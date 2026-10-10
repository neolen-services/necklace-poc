#include "storage.h"

#include <Arduino.h>
#include <string.h>

#include <InternalFileSystem.h>

using namespace Adafruit_LittleFS_Namespace;

namespace {

constexpr uint32_t kCfgMagic = 0x31474D4D;   // MMG1
constexpr uint32_t kHistMagic = 0x31484D4D;  // MMH1
constexpr uint16_t kCapacity = 480;
constexpr uint32_t kFlushIntervalMs = 5UL * 60UL * 1000UL;

HistoryPacket records[kCapacity];
uint16_t count = 0;
uint32_t nextSeq = 1;
uint32_t ackSeq = 0;
bool flashOk = false;
bool dirty = false;
uint32_t lastFlushMs = 0;

struct HistHeader {
  uint32_t magic;
  uint32_t ack;
  uint32_t next;
  uint16_t count;
  uint16_t reserved;
};

void loadHistory() {
  File file(InternalFS);
  if (!file.open("/mmh.hst", FILE_O_READ)) {
    return;
  }
  HistHeader header{};
  if (file.read(&header, sizeof(header)) != sizeof(header) || header.magic != kHistMagic) {
    file.close();
    return;
  }
  if (header.count > kCapacity) {
    file.close();
    return;
  }
  uint16_t got = 0;
  while (got < header.count) {
    HistoryPacket pkt{};
    if (file.read(&pkt, sizeof(pkt)) != sizeof(pkt)) {
      break;
    }
    records[got++] = pkt;
  }
  file.close();
  count = got;
  ackSeq = header.ack;
  nextSeq = header.next > 0 ? header.next : 1;
  Serial.print("History loaded: ");
  Serial.println(count);
}

void saveHistory() {
  if (!flashOk) {
    return;
  }
  InternalFS.remove("/mmh.hst");
  File file(InternalFS);
  if (!file.open("/mmh.hst", FILE_O_WRITE)) {
    Serial.println("History file open failed");
    return;
  }
  HistHeader header{kHistMagic, ackSeq, nextSeq, count, 0};
  file.write((const uint8_t*)&header, sizeof(header));
  if (count > 0) {
    file.write((const uint8_t*)records, sizeof(HistoryPacket) * count);
  }
  file.close();
  dirty = false;
  lastFlushMs = millis();
}

}  // namespace

void storageBegin() {
  flashOk = InternalFS.begin();
  if (!flashOk) {
    Serial.println("InternalFS unavailable; history stays in RAM");
    return;
  }
  loadHistory();
}

bool storageLoadConfig(PersistConfig* out) {
  if (!flashOk || out == nullptr) {
    return false;
  }
  File file(InternalFS);
  if (!file.open("/mmh.cfg", FILE_O_READ)) {
    return false;
  }
  PersistConfig cfg{};
  bool ok = file.read(&cfg, sizeof(cfg)) == sizeof(cfg) && cfg.magic == kCfgMagic;
  file.close();
  if (ok) {
    *out = cfg;
  }
  return ok;
}

void storageSaveConfig(const PersistConfig& cfg) {
  if (!flashOk) {
    return;
  }
  InternalFS.remove("/mmh.cfg");
  File file(InternalFS);
  if (!file.open("/mmh.cfg", FILE_O_WRITE)) {
    return;
  }
  file.write((const uint8_t*)&cfg, sizeof(cfg));
  file.close();
}

uint32_t storageAppend(uint8_t type, uint32_t epoch, uint16_t a, uint16_t b, uint8_t peak) {
  if (count == kCapacity) {
    memmove(&records[0], &records[1], sizeof(HistoryPacket) * (kCapacity - 1));
    count--;
  }
  HistoryPacket pkt{};
  pkt.seq = nextSeq++;
  pkt.type = type;
  pkt.epoch = epoch;
  pkt.a = a;
  pkt.b = b;
  pkt.peak = peak;
  records[count++] = pkt;
  dirty = true;
  return pkt.seq;
}

bool storageRead(uint16_t index, HistoryPacket* out) {
  if (out == nullptr || index >= count) {
    return false;
  }
  *out = records[index];
  return true;
}

uint16_t storageCount() { return count; }

uint32_t storageAckSeq() { return ackSeq; }

void storageAckThrough(uint32_t seq) {
  if (seq > ackSeq) {
    ackSeq = seq;
  }
  uint16_t write = 0;
  for (uint16_t i = 0; i < count; i++) {
    if (records[i].seq > ackSeq) {
      records[write++] = records[i];
    }
  }
  count = write;
  dirty = true;
  storageFlush(true);
}

void storageClearHistory() {
  count = 0;
  ackSeq = 0;
  dirty = true;
  storageFlush(true);
}

void storageFlush(bool force) {
  if (!dirty) {
    return;
  }
  if (!force && (millis() - lastFlushMs) < kFlushIntervalMs) {
    return;
  }
  saveHistory();
}
