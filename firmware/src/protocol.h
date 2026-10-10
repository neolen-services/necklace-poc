#pragma once

#include <stdint.h>

// Shared with lib/ble/protocol.dart. All multi-byte fields are little-endian.
//
// Service  8f3a0001-7c2b-4d6e-9a10-b1c2d3e4f5a6
// Live     8f3a0002-7c2b-4d6e-9a10-b1c2d3e4f5a6  notify, 4 bytes
// Config   8f3a0003-7c2b-4d6e-9a10-b1c2d3e4f5a6  read/write, 8 bytes
// Command  8f3a0004-7c2b-4d6e-9a10-b1c2d3e4f5a6  write, 1-8 bytes
// History  8f3a0005-7c2b-4d6e-9a10-b1c2d3e4f5a6  notify, 14 bytes

#define POSTURE_SERVICE_UUID "8f3a0001-7c2b-4d6e-9a10-b1c2d3e4f5a6"
#define POSTURE_LIVE_UUID "8f3a0002-7c2b-4d6e-9a10-b1c2d3e4f5a6"
#define POSTURE_CONFIG_UUID "8f3a0003-7c2b-4d6e-9a10-b1c2d3e4f5a6"
#define POSTURE_COMMAND_UUID "8f3a0004-7c2b-4d6e-9a10-b1c2d3e4f5a6"
#define POSTURE_HISTORY_UUID "8f3a0005-7c2b-4d6e-9a10-b1c2d3e4f5a6"

enum PostureMode : uint8_t {
  MODE_TRAINING = 0,
  MODE_TRACKING = 1,
};

enum WearStyle : uint8_t {
  WEAR_UPPER_BACK = 0,
  WEAR_NECKLACE = 1,
};

enum LiveFlag : uint8_t {
  FLAG_UPRIGHT = 1 << 0,
  FLAG_SLOUCHING = 1 << 1,
  FLAG_CALIBRATING = 1 << 2,
  FLAG_WORN = 1 << 3,
  FLAG_BUZZING = 1 << 4,
  FLAG_CALIBRATED = 1 << 5,
  FLAG_PENDING = 1 << 6,
  FLAG_SENSOR_FAULT = 1 << 7,
};

enum CommandId : uint8_t {
  CMD_CALIBRATE = 1,
  CMD_TEST_VIBE = 2,
  CMD_SET_TIME = 3,       // uint32 UTC epoch after the command byte
  CMD_CLEAR_HISTORY = 4,
  CMD_REQUEST_SYNC = 5,
  CMD_ACK = 6,            // uint32 last received seq after the command byte
};

enum HistoryType : uint8_t {
  HIST_MINUTE = 1,  // epoch = minute start, a = upright sec, b = slouch sec
  HIST_SLOUCH = 2,  // epoch = start, a = duration sec, b = 0
  HIST_END = 3,     // a = 1 when the sync batch is finished
};

struct __attribute__((packed)) LivePacket {
  int16_t angleTenthDeg;
  uint8_t flags;
  uint8_t battery;
};
static_assert(sizeof(LivePacket) == 4, "LivePacket size");

struct __attribute__((packed)) ConfigPacket {
  uint8_t mode;
  uint8_t thresholdDeg;
  uint8_t delayS;
  uint8_t strength;
  uint8_t wear;
  uint8_t autoCal;
  uint16_t reserved;
};
static_assert(sizeof(ConfigPacket) == 8, "ConfigPacket size");

struct __attribute__((packed)) HistoryPacket {
  uint32_t seq;
  uint8_t type;
  uint32_t epoch;
  uint16_t a;
  uint16_t b;
  uint8_t peak;
};
static_assert(sizeof(HistoryPacket) == 14, "HistoryPacket size");

// Vibration motor on D0 (transistor or a module input). The red LED mirrors it.
#ifndef VIBE_PIN
#define VIBE_PIN 0
#endif

#define FIRMWARE_VERSION "2.4.1"
#define DEVICE_NAME "MMH Posture"
