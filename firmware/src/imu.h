#pragma once

struct AccelSample {
  float x;
  float y;
  float z;
  bool ok;
};

void imuBegin();
bool imuOk();
AccelSample imuRead();
