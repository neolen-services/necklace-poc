#pragma once

#include <stdint.h>

#include "protocol.h"

void postureBegin();
void postureAfterBle();
void postureUpdate(uint32_t nowMs);
void postureOnConfig(const ConfigPacket& cfg);
void postureOnCommand(const uint8_t* data, uint16_t len);
void postureSetConnected(bool connected);
