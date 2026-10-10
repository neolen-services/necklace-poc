#include <Arduino.h>

#include "ble_service.h"
#include "posture.h"

static uint32_t lastSampleMs = 0;

void setup() {
  Serial.begin(115200);
  delay(200);
  Serial.println("MMH Posture firmware " FIRMWARE_VERSION);
  postureBegin();
  bleBegin();
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
}
