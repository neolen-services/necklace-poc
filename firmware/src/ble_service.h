#pragma once

#include <stdint.h>

#include "protocol.h"

void bleBegin();
void blePump();
bool bleConnected();
bool bleNotifyLive(const LivePacket& packet);
bool bleNotifyHistory(const HistoryPacket& packet);
void bleWriteBattery(uint8_t percent);
void bleWriteConfig(const ConfigPacket& cfg);
