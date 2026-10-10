#include <Arduino.h>
#include <Adafruit_TinyUSB.h>

#include "ble_service.h"
#include "imu.h"
#include "posture.h"
#include "utility/SoftwareTimer.h"

static SoftwareTimer ledTimer;
static uint32_t lastSampleMs = 0;
static uint32_t lastLogMs = 0;

static void ledTimerCallback(TimerHandle_t timer) {
  (void)timer;
  postureLedTick();
}

// LEDs are active-low on the XIAO.
static void flashAlive() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_RED, LOW);
    digitalWrite(LED_BLUE, LOW);
    delay(100);
    digitalWrite(LED_RED, HIGH);
    digitalWrite(LED_BLUE, HIGH);
    delay(100);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(VIBE_PIN, OUTPUT);
  digitalWrite(VIBE_PIN, LOW);
  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  flashAlive();
  Serial.println("MMH Posture firmware " FIRMWARE_VERSION);

  ledTimer.begin(50, ledTimerCallback);
  ledTimer.start();
  bleBegin();
  postureBegin();
  postureAfterBle();
  lastSampleMs = millis();
}

void loop() {
  uint32_t now = millis();
  if ((now - lastSampleMs) >= 20) {
    lastSampleMs = now;
    postureUpdate(now);
  }
  blePump();
  if (now - lastLogMs > 5000) {
    lastLogMs = now;
    Serial.printf("%s imu=%s err=%u\n", bleConnected() ? "connected" : "advertising",
                  imuOk() ? "ok" : "fail", imuError());
  }
}
