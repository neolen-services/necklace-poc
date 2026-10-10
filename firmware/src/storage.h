#pragma once

#include <stdint.h>

#include "protocol.h"

struct PersistConfig {
  uint32_t magic;
  ConfigPacket cfg;
  int16_t refXmg;
  int16_t refYmg;
  int16_t refZmg;
  uint8_t hasRef;
  uint8_t pad;
};

void storageBegin();
bool storageLoadConfig(PersistConfig* out);
void storageSaveConfig(const PersistConfig& cfg);

uint32_t storageAppend(uint8_t type, uint32_t epoch, uint16_t a, uint16_t b, uint8_t peak);
bool storageRead(uint16_t index, HistoryPacket* out);
uint16_t storageCount();
uint32_t storageAckSeq();
void storageAckThrough(uint32_t seq);
void storageClearHistory();
void storageFlush(bool force);
