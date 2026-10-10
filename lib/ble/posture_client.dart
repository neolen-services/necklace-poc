import 'dart:async';

import 'protocol.dart';

enum ConnectionStatus { disconnected, connecting, connected, reconnecting }

abstract class PostureClient {
  Stream<ConnectionStatus> get connection;
  Stream<LiveReading> get live;
  Stream<HistoryRecord> get history;
  Stream<DeviceConfig> get configs;

  DeviceConfig get config;
  String? get firmware;
  String get deviceName;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> writeConfig(DeviceConfig config);
  Future<void> calibrate();
  Future<void> testVibration();
  Future<void> setTime(DateTime utc);
  Future<void> clearHistory();
  Future<void> requestSync();
  Future<void> ack(int seq);
  Future<void> dispose();
}
