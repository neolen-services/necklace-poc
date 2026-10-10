#include "imu.h"

#include <Arduino.h>
#include <Wire.h>

// The Sense IMU is not on the header I2C pins. It sits on Wire1
// (SDA D17, SCL D16) and stays off until PIN_LSM6DS3TR_C_POWER is driven.
// Address 0x6A. WHO_AM_I is 0x6A on the TR-C and 0x69 on the original LSM6DS3.

namespace {

constexpr uint8_t kWhoAmI = 0x0F;
constexpr uint8_t kCtrl1Xl = 0x10;
constexpr uint8_t kCtrl2G = 0x11;
constexpr uint8_t kCtrl3C = 0x12;
constexpr uint8_t kOutXl = 0x28;
constexpr float kGPerLsb = 0.000061f;  // ±2 g

uint8_t address = 0x6A;
bool ready = false;

bool writeReg(uint8_t reg, uint8_t value) {
  Wire1.beginTransmission(address);
  Wire1.write(reg);
  Wire1.write(value);
  return Wire1.endTransmission() == 0;
}

bool readRegs(uint8_t reg, uint8_t* dest, uint8_t len) {
  Wire1.beginTransmission(address);
  Wire1.write(reg);
  if (Wire1.endTransmission(false) != 0) {
    return false;
  }
  if (Wire1.requestFrom(address, len) != len) {
    return false;
  }
  for (uint8_t i = 0; i < len; i++) {
    dest[i] = Wire1.read();
  }
  return true;
}

bool probe(uint8_t addr) {
  Wire1.beginTransmission(addr);
  if (Wire1.endTransmission() != 0) {
    return false;
  }
  address = addr;
  uint8_t who = 0;
  if (!readRegs(kWhoAmI, &who, 1)) {
    return false;
  }
  return who == 0x6A || who == 0x69 || who == 0x6C;
}

bool powerAndProbe(uint8_t level) {
  pinMode(PIN_LSM6DS3TR_C_POWER, OUTPUT);
  digitalWrite(PIN_LSM6DS3TR_C_POWER, level);
  delay(20);
  Wire1.begin();
  Wire1.setClock(100000);
  return probe(0x6A) || probe(0x6B);
}

}  // namespace

void imuBegin() {
  ready = false;
  if (!powerAndProbe(HIGH) && !powerAndProbe(LOW)) {
    Serial.println("IMU: no ACK on Wire1");
    return;
  }

  writeReg(kCtrl3C, 0x01);  // software reset
  delay(20);
  writeReg(kCtrl3C, 0x44);  // BDU + auto-increment
  writeReg(kCtrl1Xl, 0x40);  // 104 Hz, ±2 g
  writeReg(kCtrl2G, 0x00);   // gyro powered down
  ready = true;
  Serial.println("IMU: ready");
}

bool imuOk() { return ready; }

AccelSample imuRead() {
  AccelSample sample{0, 0, 0, false};
  if (!ready) {
    static uint32_t lastTry = 0;
    if (millis() - lastTry > 2000) {
      lastTry = millis();
      imuBegin();
    }
    if (!ready) return sample;
  }
  uint8_t raw[6];
  if (!readRegs(kOutXl, raw, 6)) {
    return sample;
  }
  auto axis = [&](uint8_t index) -> float {
    int16_t v = (int16_t)(raw[index] | (raw[index + 1] << 8));
    return v * kGPerLsb;
  };
  sample.x = axis(0);
  sample.y = axis(2);
  sample.z = axis(4);
  sample.ok = true;
  return sample;
}
