#include "ble_service.h"

#include <Arduino.h>
#include <bluefruit.h>

#include "posture.h"

namespace {

BLEService postureService(POSTURE_SERVICE_UUID);
BLECharacteristic liveChr(POSTURE_LIVE_UUID);
BLECharacteristic configChr(POSTURE_CONFIG_UUID);
BLECharacteristic commandChr(POSTURE_COMMAND_UUID);
BLECharacteristic historyChr(POSTURE_HISTORY_UUID);
BLEDis deviceInfo;
BLEBas battery;

bool connected = false;
uint8_t batteryPercent = 0;

void onConnect(uint16_t connHandle) {
  (void)connHandle;
  connected = true;
  Serial.println("BLE connected");
  postureSetConnected(true);
}

void onDisconnect(uint16_t connHandle, uint8_t reason) {
  (void)connHandle;
  (void)reason;
  connected = false;
  Serial.println("BLE disconnected");
  postureSetConnected(false);
}

void onConfigWrite(uint16_t connHandle, BLECharacteristic* chr, uint8_t* data, uint16_t len) {
  (void)connHandle;
  (void)chr;
  if (len < sizeof(ConfigPacket)) {
    return;
  }
  ConfigPacket cfg{};
  memcpy(&cfg, data, sizeof(cfg));
  postureOnConfig(cfg);
}

void onCommandWrite(uint16_t connHandle, BLECharacteristic* chr, uint8_t* data, uint16_t len) {
  (void)connHandle;
  (void)chr;
  if (len < 1) {
    return;
  }
  postureOnCommand(data, len);
}

}  // namespace

void bleBegin() {
  Bluefruit.begin();
  Bluefruit.setTxPower(4);
  Bluefruit.setName(DEVICE_NAME);
  Bluefruit.Periph.setConnectCallback(onConnect);
  Bluefruit.Periph.setDisconnectCallback(onDisconnect);
  Bluefruit.Periph.setConnInterval(24, 48);  // 30 ms – 60 ms

  deviceInfo.setManufacturer("Make My Health");
  deviceInfo.setModel("Necklace");
  deviceInfo.setFirmwareRev(FIRMWARE_VERSION);
  deviceInfo.begin();

  battery.begin();
  battery.write(0);

  postureService.begin();

  liveChr.setProperties(CHR_PROPS_READ | CHR_PROPS_NOTIFY);
  liveChr.setPermission(SECMODE_OPEN, SECMODE_NO_ACCESS);
  liveChr.setFixedLen(sizeof(LivePacket));
  liveChr.begin();

  configChr.setProperties(CHR_PROPS_READ | CHR_PROPS_WRITE);
  configChr.setPermission(SECMODE_OPEN, SECMODE_OPEN);
  configChr.setFixedLen(sizeof(ConfigPacket));
  configChr.setWriteCallback(onConfigWrite);
  configChr.begin();

  commandChr.setProperties(CHR_PROPS_WRITE);
  commandChr.setPermission(SECMODE_NO_ACCESS, SECMODE_OPEN);
  commandChr.setMaxLen(16);
  commandChr.setWriteCallback(onCommandWrite);
  commandChr.begin();

  historyChr.setProperties(CHR_PROPS_NOTIFY);
  historyChr.setPermission(SECMODE_OPEN, SECMODE_NO_ACCESS);
  historyChr.setMaxLen(sizeof(HistoryPacket));
  historyChr.begin();

  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  Bluefruit.Advertising.addService(postureService);
  Bluefruit.ScanResponse.addName();
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);
  Bluefruit.Advertising.setFastTimeout(30);
  Bluefruit.Advertising.start(0);
  Serial.println("Advertising as " DEVICE_NAME);
}

void blePump() {}

bool bleConnected() { return connected; }

bool bleNotifyLive(const LivePacket& packet) {
  if (!connected) {
    return false;
  }
  return liveChr.notify(&packet, sizeof(packet)) > 0;
}

bool bleNotifyHistory(const HistoryPacket& packet) {
  if (!connected) {
    return false;
  }
  return historyChr.notify(&packet, sizeof(packet)) > 0;
}

void bleWriteBattery(uint8_t percent) {
  batteryPercent = percent;
  if (connected) {
    battery.write(percent);
  }
}

void bleWriteConfig(const ConfigPacket& cfg) {
  configChr.write(&cfg, sizeof(cfg));
}
