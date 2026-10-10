#include "posture.h"

#include <Arduino.h>
#include <math.h>
#include <string.h>

#include "ble_service.h"
#include "imu.h"
#include "storage.h"

namespace {

constexpr float kPi = 3.14159265f;
constexpr float kHysteresisDeg = 2.0f;
constexpr float kFilterAlpha = 0.12f;
constexpr uint32_t kLiveIntervalMs = 200;
constexpr uint32_t kOffBodyMs = 45000;
constexpr uint32_t kAutoStillMs = 2500;
constexpr int kCalSamples = 25;

ConfigPacket cfg{
    MODE_TRAINING, 15, 5, 70, WEAR_UPPER_BACK, 1, 0,
};

float gx = 0, gy = 0, gz = 1;
float rawAx = 0, rawAy = 0, rawAz = 0;
bool filterInit = false;
float refX = 0, refY = 0, refZ = 1;
bool hasRef = false;

enum SlouchState : uint8_t { ST_OK = 0, ST_PENDING = 1, ST_SLOUCH = 2 };
SlouchState slouch = ST_OK;
uint32_t pendingSince = 0;
uint32_t slouchStartMs = 0;
uint32_t slouchStartEpoch = 0;
float slouchPeak = 0;

bool connected = false;
bool flushRequested = false;
bool sensorFault = false;

uint32_t timeBaseEpoch = 0;
uint32_t timeBaseMs = 0;
bool timeValid = false;

uint32_t lastMotionMs = 0;
uint32_t stillForMs = 0;
bool sawMotion = false;
bool autoArmed = true;
bool worn = false;

uint32_t bucketMinute = 0;
uint32_t uprightMs = 0;
uint32_t slouchMsAccum = 0;
uint8_t bucketPeak = 0;

uint32_t lastLiveMs = 0;
uint32_t lastBatteryMs = 0;
uint8_t battery = 0;

bool samplingCal = false;
int calCount = 0;
float calX = 0, calY = 0, calZ = 0;
uint32_t calibratingUntil = 0;

volatile uint32_t vibeUntilMs = 0;

bool syncing = false;
uint16_t syncIndex = 0;

volatile bool pendingCmd = false;
uint8_t pendingBuf[8];
uint16_t pendingLen = 0;
volatile bool pendingConfig = false;
ConfigPacket pendingCfg{};

int16_t toMilliG(float v) {
  int32_t mg = (int32_t)(v * 1000.0f);
  if (mg > 32000) mg = 32000;
  if (mg < -32000) mg = -32000;
  return (int16_t)mg;
}

float fromMilliG(int16_t mg) { return mg / 1000.0f; }

uint32_t nowEpoch() {
  if (!timeValid) {
    return 0;
  }
  return timeBaseEpoch + (millis() - timeBaseMs) / 1000UL;
}

void persistConfig() {
  PersistConfig stored{};
  stored.magic = 0x31474D4D;
  stored.cfg = cfg;
  stored.refXmg = toMilliG(refX);
  stored.refYmg = toMilliG(refY);
  stored.refZmg = toMilliG(refZ);
  stored.hasRef = hasRef ? 1 : 0;
  storageSaveConfig(stored);
}

void clampConfig() {
  if (cfg.mode > MODE_TRACKING) cfg.mode = MODE_TRAINING;
  if (cfg.thresholdDeg < 5) cfg.thresholdDeg = 5;
  if (cfg.thresholdDeg > 45) cfg.thresholdDeg = 45;
  if (cfg.delayS > 30) cfg.delayS = 30;
  if (cfg.strength > 100) cfg.strength = 100;
  if (cfg.wear > WEAR_NECKLACE) cfg.wear = WEAR_UPPER_BACK;
  cfg.autoCal = cfg.autoCal ? 1 : 0;
}

void emitMinute() {
  uint16_t upright = (uint16_t)(uprightMs / 1000UL);
  uint16_t slouching = (uint16_t)(slouchMsAccum / 1000UL);
  if (upright > 60) upright = 60;
  if (slouching > 60) slouching = 60;
  if (upright + slouching == 0 || bucketMinute == 0) {
    return;
  }
  storageAppend(HIST_MINUTE, bucketMinute * 60UL, upright, slouching, bucketPeak);
}

void closeSlouch() {
  if (slouch != ST_SLOUCH) {
    return;
  }
  uint32_t dur = (millis() - slouchStartMs) / 1000UL;
  if (dur < 1) dur = 1;
  if (dur > 65535UL) dur = 65535UL;
  uint8_t peak = (uint8_t)(slouchPeak > 180 ? 180 : slouchPeak);
  storageAppend(HIST_SLOUCH, slouchStartEpoch, (uint16_t)dur, 0, peak);
  storageFlush(false);
}

float tiltDeg() {
  float na = sqrtf(gx * gx + gy * gy + gz * gz);
  float nr = sqrtf(refX * refX + refY * refY + refZ * refZ);
  if (na < 0.2f || nr < 0.2f) {
    return 0;
  }
  float c = (gx * refX + gy * refY + gz * refZ) / (na * nr);
  if (c > 1) c = 1;
  if (c < -1) c = -1;
  return acosf(c) * (180.0f / kPi);
}

void startCalibration() {
  samplingCal = true;
  calCount = 0;
  calX = calY = calZ = 0;
  calibratingUntil = millis() + 1500;
}

void finishCalibration() {
  float n = (float)calCount;
  refX = calX / n;
  refY = calY / n;
  refZ = calZ / n;
  hasRef = true;
  samplingCal = false;
  calibratingUntil = millis() + 800;
  persistConfig();
  Serial.println("Calibrated");
}

void armVibration(uint32_t durationMs) { vibeUntilMs = millis() + durationMs; }

bool buzzingNow(uint32_t nowMs) {
  bool testBuzz = (int32_t)(vibeUntilMs - nowMs) > 0;
  return testBuzz || (cfg.mode == MODE_TRAINING && slouch == ST_SLOUCH && cfg.strength > 0);
}

int readBattery() {
#if defined(PIN_VBAT)
  static bool inited = false;
  if (!inited) {
#if defined(VBAT_ENABLE)
    pinMode(VBAT_ENABLE, OUTPUT);
    digitalWrite(VBAT_ENABLE, LOW);
#endif
    analogReadResolution(12);
    inited = true;
  }
  uint32_t acc = 0;
  for (int i = 0; i < 4; i++) {
    acc += analogRead(PIN_VBAT);
  }
  float volts = (acc / 4.0f) * 2.0f * 3.6f / 4096.0f;
  if (volts < 2.5f) {
    return 0;
  }
  int pct = (int)((volts - 3.30f) * 100.0f / 0.90f);
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  return pct;
#else
  return 0;
#endif
}

void trackMinute(uint32_t dtMs, float angle) {
  if (!worn || !hasRef || !timeValid) {
    return;
  }
  uint32_t epoch = nowEpoch();
  uint32_t minute = epoch / 60UL;
  if (bucketMinute == 0) {
    bucketMinute = minute;
  }
  if (minute != bucketMinute) {
    emitMinute();
    bucketMinute = minute;
    uprightMs = 0;
    slouchMsAccum = 0;
    bucketPeak = 0;
  }
  if (angle > cfg.thresholdDeg) {
    slouchMsAccum += dtMs;
  } else {
    uprightMs += dtMs;
  }
  if (angle > bucketPeak) {
    bucketPeak = (uint8_t)(angle > 180 ? 180 : angle);
  }
}

void updateSlouch(float angle, uint32_t nowMs) {
  float clearBelow = cfg.thresholdDeg - kHysteresisDeg;
  if (clearBelow < 0) clearBelow = 0;

  if (!hasRef || !worn) {
    if (slouch == ST_SLOUCH) closeSlouch();
    slouch = ST_OK;
    return;
  }

  if (angle > cfg.thresholdDeg) {
    if (slouch == ST_OK) {
      slouch = ST_PENDING;
      pendingSince = nowMs;
    }
    uint32_t delayMs = (uint32_t)cfg.delayS * 1000UL;
    if (slouch == ST_PENDING && (nowMs - pendingSince) >= delayMs) {
      slouch = ST_SLOUCH;
      slouchStartMs = nowMs;
      slouchStartEpoch = timeValid ? nowEpoch() : 0;
      slouchPeak = angle;
    }
    if (slouch == ST_SLOUCH && angle > slouchPeak) {
      slouchPeak = angle;
    }
  } else if (angle < clearBelow) {
    if (slouch == ST_SLOUCH) closeSlouch();
    slouch = ST_OK;
  }
}

void updateWear(float motion, uint32_t dtMs, uint32_t nowMs) {
  if (motion > 0.12f) {
    lastMotionMs = nowMs;
    stillForMs = 0;
    sawMotion = true;
  } else if (motion < 0.05f) {
    stillForMs += dtMs;
  } else {
    stillForMs = 0;
  }

  bool recentMotion = lastMotionMs != 0 && (nowMs - lastMotionMs) < 20000UL;
  worn = recentMotion || (hasRef && stillForMs < kOffBodyMs);
  if (stillForMs > kOffBodyMs) {
    worn = false;
    sawMotion = false;
    autoArmed = true;
  }

  if (cfg.autoCal && autoArmed && sawMotion && stillForMs > kAutoStillMs && !samplingCal) {
    startCalibration();
    autoArmed = false;
    sawMotion = false;
  }
}

void pumpSync() {
  if (!syncing || !connected) {
    return;
  }
  for (int n = 0; n < 3; n++) {
    HistoryPacket pkt{};
    bool found = false;
    while (syncIndex < storageCount()) {
      if (!storageRead(syncIndex, &pkt)) {
        break;
      }
      syncIndex++;
      if (pkt.seq > storageAckSeq()) {
        found = true;
        break;
      }
    }
    if (!found) {
      HistoryPacket end{};
      end.type = HIST_END;
      end.seq = storageAckSeq();
      end.a = 1;
      bleNotifyHistory(end);
      syncing = false;
      storageFlush(true);
      return;
    }
    if (!bleNotifyHistory(pkt)) {
      if (syncIndex > 0) syncIndex--;
      return;
    }
  }
}

void publishLive(uint32_t nowMs, float angle) {
  if (!connected || (nowMs - lastLiveMs) < kLiveIntervalMs) {
    return;
  }
  lastLiveMs = nowMs;
  bool buzzing = buzzingNow(nowMs);
  LivePacket live{};
  int tenth = (int)(angle * 10.0f + 0.5f);
  if (tenth < 0) tenth = 0;
  if (tenth > 1800) tenth = 1800;
  live.angleTenthDeg = (int16_t)tenth;
  if (hasRef && worn && slouch == ST_OK && angle <= cfg.thresholdDeg) {
    live.flags |= FLAG_UPRIGHT;
  }
  if (slouch == ST_SLOUCH) live.flags |= FLAG_SLOUCHING;
  bool showCal = samplingCal || (calibratingUntil != 0 && (int32_t)(calibratingUntil - nowMs) > 0);
  if (showCal) live.flags |= FLAG_CALIBRATING;
  if (worn) live.flags |= FLAG_WORN;
  if (buzzing) live.flags |= FLAG_BUZZING;
  if (hasRef) live.flags |= FLAG_CALIBRATED;
  if (slouch == ST_PENDING) live.flags |= FLAG_PENDING;
  if (sensorFault) live.flags |= FLAG_SENSOR_FAULT;
  live.battery = battery;
  live.xMg = (int16_t)(rawAx * 1000.0f);
  live.yMg = (int16_t)(rawAy * 1000.0f);
  live.zMg = (int16_t)(rawAz * 1000.0f);
  bleNotifyLive(live);
}

}  // namespace

void postureBegin() {
  storageBegin();
  PersistConfig stored{};
  if (storageLoadConfig(&stored)) {
    cfg = stored.cfg;
    clampConfig();
    if (stored.hasRef) {
      refX = fromMilliG(stored.refXmg);
      refY = fromMilliG(stored.refYmg);
      refZ = fromMilliG(stored.refZmg);
      hasRef = true;
    }
  }
  imuBegin();
  sensorFault = !imuOk();
}

void postureAfterBle() {
  bleWriteConfig(cfg);
  bleWriteBattery(battery);
}

void postureSetConnected(bool isConnected) {
  connected = isConnected;
  if (!connected) {
    syncing = false;
    flushRequested = true;
  }
}

// Runs every 50 ms from a timer and is the only owner of the LEDs and motor.
void postureLedTick() {
  imuServiceWatchdog();
  uint32_t now = millis();
  if (buzzingNow(now)) {
    bool pulse = ((now / 140UL) % 2UL) == 0UL;
    digitalWrite(LED_RED, pulse ? LOW : HIGH);
    digitalWrite(LED_GREEN, HIGH);
    digitalWrite(LED_BLUE, HIGH);
    analogWrite(VIBE_PIN, pulse ? (int)cfg.strength * 255 / 100 : 0);
    return;
  }
  analogWrite(VIBE_PIN, 0);
  digitalWrite(LED_RED, HIGH);
  // Green stays on while the phone is connected. Blue blinks only while waiting.
  bool waitingBlink = !connected && (now % 1000UL) < 160UL;
  digitalWrite(LED_BLUE, waitingBlink ? LOW : HIGH);
  digitalWrite(LED_GREEN, connected ? LOW : HIGH);
}

void postureOnConfig(const ConfigPacket& incoming) {
  noInterrupts();
  pendingCfg = incoming;
  pendingConfig = true;
  interrupts();
}

void applyConfig(const ConfigPacket& incoming) {
  cfg = incoming;
  clampConfig();
  persistConfig();
  bleWriteConfig(cfg);
}

void applyCommand(const uint8_t* data, uint16_t len) {
  switch (data[0]) {
    case CMD_CALIBRATE:
      startCalibration();
      break;
    case CMD_SET_TIME:
      if (len >= 5) {
        uint32_t epoch = (uint32_t)data[1] | ((uint32_t)data[2] << 8) |
                         ((uint32_t)data[3] << 16) | ((uint32_t)data[4] << 24);
        timeBaseEpoch = epoch;
        timeBaseMs = millis();
        timeValid = epoch > 1600000000UL;
        Serial.print("Time set ");
        Serial.println(epoch);
      }
      break;
    case CMD_CLEAR_HISTORY:
      if (slouch == ST_SLOUCH) closeSlouch();
      storageClearHistory();
      uprightMs = slouchMsAccum = 0;
      bucketMinute = 0;
      break;
    case CMD_REQUEST_SYNC:
      syncing = true;
      syncIndex = 0;
      break;
    case CMD_ACK:
      if (len >= 5) {
        uint32_t seq = (uint32_t)data[1] | ((uint32_t)data[2] << 8) |
                       ((uint32_t)data[3] << 16) | ((uint32_t)data[4] << 24);
        storageAckThrough(seq);
        syncIndex = 0;
      }
      break;
    default:
      break;
  }
}

void postureOnCommand(const uint8_t* data, uint16_t len) {
  if (len < 1) {
    return;
  }
  // Arm right away so the test buzz does not wait for the next sample tick.
  if (data[0] == CMD_TEST_VIBE) {
    armVibration(2000);
  }
  if (len > sizeof(pendingBuf)) {
    len = sizeof(pendingBuf);
  }
  noInterrupts();
  memcpy(pendingBuf, data, len);
  pendingLen = len;
  pendingCmd = true;
  interrupts();
}

void postureUpdate(uint32_t nowMs) {
  if (pendingConfig) {
    ConfigPacket next{};
    noInterrupts();
    next = pendingCfg;
    pendingConfig = false;
    interrupts();
    applyConfig(next);
  }
  if (pendingCmd) {
    uint8_t buf[8];
    uint16_t len = 0;
    noInterrupts();
    len = pendingLen;
    memcpy(buf, pendingBuf, len);
    pendingCmd = false;
    interrupts();
    applyCommand(buf, len);
  }

  static uint32_t lastMs = 0;
  uint32_t dt = lastMs == 0 ? 20 : (nowMs - lastMs);
  lastMs = nowMs;
  if (dt > 200) dt = 200;

  AccelSample sample = imuRead();
  rawAx = sample.x;
  rawAy = sample.y;
  rawAz = sample.z;
  sensorFault = !sample.ok;
  float angle = 0;
  float motion = 0;
  if (sample.ok) {
    if (!filterInit) {
      gx = sample.x;
      gy = sample.y;
      gz = sample.z;
      filterInit = true;
    } else {
      gx += kFilterAlpha * (sample.x - gx);
      gy += kFilterAlpha * (sample.y - gy);
      gz += kFilterAlpha * (sample.z - gz);
    }
    motion = fabsf(sample.x - gx) + fabsf(sample.y - gy) + fabsf(sample.z - gz);
    float mag = sqrtf(gx * gx + gy * gy + gz * gz);
    if (mag > 0.5f && mag < 1.5f && !hasRef && !samplingCal) {
      refX = gx;
      refY = gy;
      refZ = gz;
      hasRef = true;
    }
    if (samplingCal) {
      calX += gx;
      calY += gy;
      calZ += gz;
      calCount++;
      if (calCount >= kCalSamples) {
        finishCalibration();
      }
    }
    angle = tiltDeg();
  }

  updateWear(motion, dt, nowMs);
  updateSlouch(angle, nowMs);
  trackMinute(dt, angle);

  if ((nowMs - lastBatteryMs) > 10000UL || lastBatteryMs == 0) {
    lastBatteryMs = nowMs;
    int pct = readBattery();
    battery = (uint8_t)pct;
    bleWriteBattery(battery);
  }

  publishLive(nowMs, angle);
  pumpSync();

  if (flushRequested) {
    flushRequested = false;
    storageFlush(true);
  } else {
    storageFlush(false);
  }
}
