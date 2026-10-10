import 'dart:async';
import 'dart:math';

import 'posture_client.dart';
import 'protocol.dart';

class SimulatedPostureClient implements PostureClient {
  final _connection = StreamController<ConnectionStatus>.broadcast();
  final _live = StreamController<LiveReading>.broadcast();
  final _history = StreamController<HistoryRecord>.broadcast();
  final _configs = StreamController<DeviceConfig>.broadcast();

  DeviceConfig _config = DeviceConfig.defaults;
  Timer? _timer;
  double _t = 0;
  bool _calibrated = true;
  bool _calibrating = false;
  DateTime? _buzzUntil;
  bool _seeded = false;
  int _seq = 1;
  final _random = Random(7);

  @override
  Stream<ConnectionStatus> get connection => _connection.stream;

  @override
  Stream<LiveReading> get live => _live.stream;

  @override
  Stream<HistoryRecord> get history => _history.stream;

  @override
  Stream<DeviceConfig> get configs => _configs.stream;

  @override
  DeviceConfig get config => _config;

  @override
  String? get firmware => '2.4.1';

  @override
  String get deviceName => 'MMH Posture';

  @override
  Future<void> connect() async {
    _connection.add(ConnectionStatus.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _connection.add(ConnectionStatus.connected);
    _configs.add(_config);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    _t += 0.2;
    final burst = (sin(_t / 9) > 0.72);
    final base = 8 + 4 * sin(_t / 2.4);
    final angle = (burst ? base + 14 : base).clamp(0, 40).toDouble();
    final slouching = _calibrated && angle > _config.thresholdDeg + 2;
    final pending = _calibrated && !slouching && angle > _config.thresholdDeg;
    final buzzing =
        _config.training &&
        slouching &&
        (_buzzUntil != null || (DateTime.now().millisecond ~/ 200).isEven);
    final testBuzz = _buzzUntil != null && DateTime.now().isBefore(_buzzUntil!);
    _live.add(
      LiveReading(
        angleDeg: angle,
        upright: _calibrated && !slouching && !pending,
        slouching: slouching,
        calibrating: _calibrating,
        worn: true,
        buzzing: buzzing || testBuzz,
        calibrated: _calibrated,
        pending: pending,
        sensorFault: false,
        battery: 86,
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _connection.add(ConnectionStatus.disconnected);
  }

  @override
  Future<void> writeConfig(DeviceConfig config) async {
    _config = config;
    _configs.add(config);
  }

  @override
  Future<void> calibrate() async {
    _calibrating = true;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _calibrating = false;
    _calibrated = true;
  }

  @override
  Future<void> testVibration() async {
    _buzzUntil = DateTime.now().add(const Duration(milliseconds: 800));
  }

  @override
  Future<void> setTime(DateTime utc) async {}

  @override
  Future<void> clearHistory() async {}

  @override
  Future<void> requestSync() async {
    if (_seeded) {
      _history.add(SyncEnd(seq: _seq, complete: true));
      return;
    }
    _seeded = true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var daysAgo = 6; daysAgo >= 1; daysAgo--) {
      final day = today.subtract(Duration(days: daysAgo));
      for (var hour = 9; hour <= 16; hour++) {
        _emitHour(DateTime(day.year, day.month, day.day, hour), daysAgo);
      }
    }
    final lastHour = now.hour.clamp(9, 17);
    if (now.hour >= 9) {
      for (var hour = 9; hour < lastHour; hour++) {
        _emitHour(DateTime(today.year, today.month, today.day, hour), 0);
      }
    }
    _emitSlouches(now);
    _history.add(SyncEnd(seq: _seq, complete: true));
  }

  void _emitHour(DateTime localHour, int daysAgo) {
    const worn = 48 * 60;
    final ratio = _ratio(localHour.hour, daysAgo);
    final upright = (worn * ratio).round();
    _history.add(
      MinuteRecord(
        seq: _seq++,
        epoch: localHour.toUtc().millisecondsSinceEpoch ~/ 1000,
        uprightSeconds: upright,
        slouchSeconds: worn - upright,
        peakAngle: ratio < 0.7 ? 28 : 18,
      ),
    );
  }

  double _ratio(int hour, int daysAgo) {
    var ratio = switch (hour) {
      12 || 15 => 0.64,
      11 || 14 => 0.72,
      _ => 0.84,
    };
    ratio += (daysAgo - 3) * 0.01;
    ratio += (_random.nextDouble() - 0.5) * 0.04;
    return ratio.clamp(0.55, 0.92);
  }

  void _emitSlouches(DateTime now) {
    final starts = [70, 48, 36, 22, 11];
    final durations = [22, 9, 65, 14, 31];
    for (var i = 0; i < starts.length; i++) {
      final when = now.subtract(Duration(minutes: starts[i]));
      if (when.hour < 8) continue;
      _history.add(
        SlouchRecord(
          seq: _seq++,
          startEpoch: when.toUtc().millisecondsSinceEpoch ~/ 1000,
          durationSeconds: durations[i],
          peakAngle: 18 + i,
        ),
      );
    }
  }

  @override
  Future<void> ack(int seq) async {}

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _connection.close();
    await _live.close();
    await _history.close();
    await _configs.close();
  }
}
