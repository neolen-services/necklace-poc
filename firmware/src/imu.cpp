#include "imu.h"

#include <Arduino.h>
#include <Wire.h>
#include <math.h>
#include <nrf.h>

// The LSM6DS3TR-C is fed from GPIO P1.08 (D15). With the default "standard"
// drive the pin sags under the sensor's load and the chip never powers up,
// which leaves SDA/SCL held low and makes the TWIM driver spin forever.
// The pin must be set to high drive (H0H1), as Seeed's own library does.

namespace {

constexpr uint8_t kWhoAmI = 0x0F;
constexpr uint8_t kCtrl1Xl = 0x10;
constexpr uint8_t kCtrl2G = 0x11;
constexpr uint8_t kCtrl3C = 0x12;
constexpr uint8_t kOutXl = 0x28;
constexpr float kGPerLsb = 0.000061f;
constexpr uint8_t kAddress = 0x6A;

bool ready = false;
bool wireStarted = false;
uint8_t errorCode = 1;

volatile bool busBusy = false;
volatile uint32_t busStartedMs = 0;

void powerOn() {
  const uint32_t pin = g_ADigitalPinMap[PIN_LSM6DS3TR_C_POWER];
  NRF_GPIO_Type* port = (pin >= 32) ? NRF_P1 : NRF_P0;
  const uint32_t bit = pin & 31;
  port->PIN_CNF[bit] = (GPIO_PIN_CNF_DIR_Output << GPIO_PIN_CNF_DIR_Pos) |
                       (GPIO_PIN_CNF_INPUT_Connect << GPIO_PIN_CNF_INPUT_Pos) |
                       (GPIO_PIN_CNF_PULL_Disabled << GPIO_PIN_CNF_PULL_Pos) |
                       (GPIO_PIN_CNF_DRIVE_H0H1 << GPIO_PIN_CNF_DRIVE_Pos);
  port->OUTSET = (1UL << bit);
}

bool busIdleHigh() {
  if (wireStarted) {
    Wire1.end();
    wireStarted = false;
  }
  pinMode(PIN_WIRE1_SDA, INPUT_PULLUP);
  pinMode(PIN_WIRE1_SCL, INPUT_PULLUP);
  delayMicroseconds(50);
  return digitalRead(PIN_WIRE1_SDA) == HIGH && digitalRead(PIN_WIRE1_SCL) == HIGH;
}

uint8_t endTx(bool stop) {
  busBusy = true;
  busStartedMs = millis();
  uint8_t err = Wire1.endTransmission(stop);
  busBusy = false;
  return err;
}

uint8_t request(uint8_t len) {
  busBusy = true;
  busStartedMs = millis();
  uint8_t got = Wire1.requestFrom(kAddress, len);
  busBusy = false;
  return got;
}

bool writeReg(uint8_t reg, uint8_t value) {
  Wire1.beginTransmission(kAddress);
  Wire1.write(reg);
  Wire1.write(value);
  return endTx(true) == 0;
}

bool readRegs(uint8_t reg, uint8_t* dest, uint8_t len) {
  Wire1.beginTransmission(kAddress);
  Wire1.write(reg);
  if (endTx(false) != 0) return false;
  if (request(len) != len) return false;
  for (uint8_t i = 0; i < len; i++) dest[i] = Wire1.read();
  return true;
}

}  // namespace

void imuServiceWatchdog() {
  if (busBusy && (millis() - busStartedMs) > 20) {
    NRF_TWIM1->EVENTS_ERROR = 1;
    NRF_TWIM1->TASKS_STOP = 1;
  }
}

void imuBegin() {
  ready = false;
  powerOn();
  delay(30);
  if (!busIdleHigh()) {
    errorCode = 2;
    return;
  }
  Wire1.setPins(PIN_WIRE1_SDA, PIN_WIRE1_SCL);
  Wire1.begin();
  Wire1.setClock(400000);
  wireStarted = true;

  uint8_t who = 0;
  if (!readRegs(kWhoAmI, &who, 1) || (who != 0x6A && who != 0x69)) {
    errorCode = 1;
    return;
  }
  writeReg(kCtrl3C, 0x01);
  delay(20);
  writeReg(kCtrl3C, 0x44);
  writeReg(kCtrl1Xl, 0x40);
  writeReg(kCtrl2G, 0x00);
  delay(20);
  ready = true;
  errorCode = 0;
}

bool imuOk() { return ready; }

uint8_t imuError() { return errorCode; }

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
    errorCode = 3;
    ready = false;
    return sample;
  }
  auto axis = [&](uint8_t index) -> float {
    int16_t raw16 = (int16_t)(raw[index] | (raw[index + 1] << 8));
    return raw16 * kGPerLsb;
  };
  sample.x = axis(0);
  sample.y = axis(2);
  sample.z = axis(4);
  float mag = sqrtf(sample.x * sample.x + sample.y * sample.y + sample.z * sample.z);
  if (mag < 0.3f || mag > 2.0f) {
    errorCode = 4;
    return sample;
  }
  errorCode = 0;
  sample.ok = true;
  return sample;
}
