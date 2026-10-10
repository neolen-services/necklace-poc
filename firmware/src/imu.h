#pragma once

#include <stdint.h>

struct AccelSample {
  float x;
  float y;
  float z;
  bool ok;
};

void imuBegin();
bool imuOk();
AccelSample imuRead();
uint8_t imuError();
void imuServiceWatchdog();
