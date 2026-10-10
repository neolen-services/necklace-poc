import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../background/tracking_service.dart';
import '../ble/ble_posture_client.dart';
import '../ble/posture_client.dart';
import '../ble/protocol.dart';
import '../ble/simulated_posture_client.dart';
import '../data/posture_database.dart';
import '../data/stats.dart';

const _keep = Object();

class PostureState {
  const PostureState({
    required this.paired,
    required this.simulator,
    required this.status,
    required this.deviceName,
    required this.firmware,
    required this.error,
    required this.live,
    required this.config,
    required this.calibratedAt,
    required this.recentMinutes,
  });

  final bool paired;
  final bool simulator;
  final ConnectionStatus status;
  final String deviceName;
  final String? firmware;
  final String? error;
  final LiveReading live;
  final DeviceConfig config;
  final DateTime? calibratedAt;
  final List<OpenMinute> recentMinutes;

  static const initial = PostureState(
    paired: false,
    simulator: false,
    status: ConnectionStatus.disconnected,
    deviceName: '',
    firmware: null,
    error: null,
    live: LiveReading.empty,
    config: DeviceConfig.defaults,
    calibratedAt: null,
    recentMinutes: [],
  );

  PostureState copyWith({
    bool? paired,
    bool? simulator,
    ConnectionStatus? status,
    String? deviceName,
    Object? firmware = _keep,
    Object? error = _keep,
    LiveReading? live,
    DeviceConfig? config,
    Object? calibratedAt = _keep,
    List<OpenMinute>? recentMinutes,
  }) {
    return PostureState(
      paired: paired ?? this.paired,
      simulator: simulator ?? this.simulator,
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
      firmware: firmware == _keep ? this.firmware : firmware as String?,
      error: error == _keep ? this.error : error as String?,
      live: live ?? this.live,
      config: config ?? this.config,
      calibratedAt: calibratedAt == _keep
          ? this.calibratedAt
          : calibratedAt as DateTime?,
      recentMinutes: recentMinutes ?? this.recentMinutes,
    );
  }
}

final databaseProvider = Provider<PostureDatabase>((ref) {
  final db = PostureDatabase();
  ref.onDispose(db.close);
  return db;
});

final postureControllerProvider =
    NotifierProvider<PostureController, PostureState>(PostureController.new);

class PostureController extends Notifier<PostureState> {
  PostureClient? _client;
  StreamSubscription<LiveReading>? _liveSub;
  StreamSubscription<HistoryRecord>? _histSub;
  StreamSubscription<ConnectionStatus>? _connSub;
  StreamSubscription<DeviceConfig>? _cfgSub;
  Timer? _configTimer;
  DeviceConfig? _pendingConfig;
  Future<void> _ingestChain = Future<void>.value();
  final _alerts = DisconnectAlerts();
  var _alive = true;
  var _wasConnected = false;
  var _sawCalibrating = false;
  DateTime? _lastSampleAt;

  @override
  PostureState build() {
    _alive = true;
    ref.onDispose(_shutdown);
    TrackingService.init();
    unawaited(_boot());
    return PostureState.initial;
  }

  PostureDatabase get _db => ref.read(databaseProvider);

  void _set(PostureState next) {
    if (!_alive) return;
    state = next;
  }

  Future<void> _boot() async {
    try {
      await _alerts.init();
      final prefs = await SharedPreferences.getInstance();
      if (!_alive) return;
      final simulator = prefs.getBool('simulator') ?? false;
      final id = prefs.getString('device_id');
      final name = prefs.getString('device_name') ?? '';
      final calibratedMs = prefs.getInt('calibrated_at');
      final calibrated = calibratedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(calibratedMs);
      if (!simulator && (id == null || id.isEmpty)) {
        if (calibrated != null) _set(state.copyWith(calibratedAt: calibrated));
        return;
      }
      _set(
        state.copyWith(
          paired: true,
          simulator: simulator,
          deviceName: simulator ? 'MMH Posture' : name,
          calibratedAt: calibrated,
          status: ConnectionStatus.connecting,
        ),
      );
      await _attach(
        simulator
            ? SimulatedPostureClient()
            : BlePostureClient(id!, knownName: name),
      );
    } catch (error) {
      _set(state.copyWith(error: 'Could not start: $error'));
    }
  }

  Future<void> pairDevice(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', id);
    await prefs.setString('device_name', name);
    await prefs.setBool('simulator', false);
    _set(
      state.copyWith(
        paired: true,
        simulator: false,
        deviceName: name,
        status: ConnectionStatus.connecting,
        error: null,
        live: LiveReading.empty,
        recentMinutes: const [],
      ),
    );
    await _attach(BlePostureClient(id, knownName: name));
  }

  Future<void> useSimulator() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('simulator', true);
    await prefs.remove('device_id');
    _set(
      state.copyWith(
        paired: true,
        simulator: true,
        deviceName: 'MMH Posture',
        status: ConnectionStatus.connecting,
        error: null,
        live: LiveReading.empty,
        recentMinutes: const [],
      ),
    );
    await _attach(SimulatedPostureClient());
  }

  Future<void> forget() async {
    await _detachClient();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('device_id');
    await prefs.remove('device_name');
    await prefs.setBool('simulator', false);
    await prefs.remove('calibrated_at');
    await TrackingService.stop();
    _wasConnected = false;
    _set(PostureState.initial);
  }

  Future<void> updateConfig(DeviceConfig config) async {
    _set(state.copyWith(config: config));
    _pendingConfig = config;
    _configTimer?.cancel();
    _configTimer = Timer(const Duration(milliseconds: 250), () async {
      final next = _pendingConfig;
      _pendingConfig = null;
      if (next != null) await _client?.writeConfig(next);
    });
  }

  Future<void> calibrate() async {
    final now = DateTime.now();
    _set(state.copyWith(calibratedAt: now));
    await _saveCalibrated(now);
    await _client?.calibrate();
  }

  Future<void> testVibration() => _client?.testVibration() ?? Future<void>.value();

  Future<void> requestSync() => _client?.requestSync() ?? Future<void>.value();

  Future<void> _attach(PostureClient client) async {
    await _detachClient();
    if (!_alive) {
      await client.dispose();
      return;
    }
    _client = client;
    _connSub = client.connection.listen(_onStatus);
    _liveSub = client.live.listen(_onLive);
    _histSub = client.history.listen((record) {
      _ingestChain = _ingestChain.then((_) => _ingest(record));
    });
    _cfgSub = client.configs.listen((config) {
      _set(state.copyWith(config: config));
    });
    await client.connect();
  }

  Future<void> _detachClient() async {
    _configTimer?.cancel();
    await _liveSub?.cancel();
    await _histSub?.cancel();
    await _connSub?.cancel();
    await _cfgSub?.cancel();
    _liveSub = null;
    _histSub = null;
    _connSub = null;
    _cfgSub = null;
    final client = _client;
    _client = null;
    if (client != null) await client.dispose();
  }

  Future<void> _onStatus(ConnectionStatus status) async {
    final dropped = _wasConnected && status != ConnectionStatus.connected;
    _wasConnected = status == ConnectionStatus.connected;
    final client = _client;
    _set(
      state.copyWith(
        status: status,
        deviceName: client?.deviceName ?? state.deviceName,
        firmware: client?.firmware ?? state.firmware,
        error: status == ConnectionStatus.connected ? null : state.error,
      ),
    );
    if (status == ConnectionStatus.connected && client != null) {
      await client.setTime(DateTime.now().toUtc());
      await client.requestSync();
      if (!state.simulator) {
        await TrackingService.start('Connected to ${client.deviceName}');
      }
    } else if (dropped && !state.simulator) {
      await _alerts.showDisconnected(state.deviceName);
      await TrackingService.update('Reconnecting to ${state.deviceName}');
    }
  }

  void _onLive(LiveReading reading) {
    var calibratedAt = state.calibratedAt;
    if (reading.calibrating) _sawCalibrating = true;
    if (_sawCalibrating && !reading.calibrating && reading.calibrated) {
      _sawCalibrating = false;
      calibratedAt = DateTime.now();
      unawaited(_saveCalibrated(calibratedAt));
    }
    _set(state.copyWith(live: reading, calibratedAt: calibratedAt));
    _rememberSample(reading);
  }

  void _rememberSample(LiveReading reading) {
    if (state.status != ConnectionStatus.connected) return;
    if (!reading.worn || !reading.calibrated) return;
    final now = DateTime.now();
    if (_lastSampleAt != null &&
        now.difference(_lastSampleAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastSampleAt = now;
    final epoch = now.toUtc().millisecondsSinceEpoch ~/ 1000;
    final minute = (epoch ~/ 60) * 60;
    final slouching = reading.angleDeg > state.config.thresholdDeg;
    final angle = reading.angleDeg.round();
    final recent = [...state.recentMinutes];
    final index = recent.indexWhere((sample) => sample.minuteEpoch == minute);
    if (index < 0) {
      recent.add(
        OpenMinute(
          minuteEpoch: minute,
          uprightSeconds: slouching ? 0 : 1,
          slouchSeconds: slouching ? 1 : 0,
          peakAngle: angle,
        ),
      );
    } else {
      recent[index] = recent[index].addSecond(slouching: slouching, angleDeg: angle);
    }
    if (recent.length > 5) {
      recent.removeRange(0, recent.length - 5);
    }
    _set(state.copyWith(recentMinutes: recent));
  }

  Future<void> _ingest(HistoryRecord record) async {
    final client = _client;
    if (client == null || !_alive) return;
    try {
      await _store(record, client);
    } catch (error) {
      debugPrint('History ingest failed: $error');
    }
  }

  Future<void> _store(HistoryRecord record, PostureClient client) async {
    switch (record) {
      case MinuteRecord():
        final existing = await _db.minuteAt(record.epoch);
        final incoming = record.uprightSeconds + record.slouchSeconds;
        final stored = existing == null
            ? 0
            : existing.uprightSeconds + existing.slouchSeconds;
        if (incoming >= stored) {
          await _db.upsertMinute(
            minuteEpoch: record.epoch,
            uprightSeconds: record.uprightSeconds,
            slouchSeconds: record.slouchSeconds,
            peakAngle: record.peakAngle,
          );
        }
        await client.ack(record.seq);
      case SlouchRecord():
        await _db.upsertSlouch(
          deviceSeq: record.seq,
          startEpoch: record.startEpoch,
          durationSeconds: record.durationSeconds,
          peakAngle: record.peakAngle,
        );
        await client.ack(record.seq);
      case SyncEnd():
        break;
    }
  }

  Future<void> _saveCalibrated(DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calibrated_at', when.millisecondsSinceEpoch);
  }

  Future<void> _shutdown() async {
    _alive = false;
    _configTimer?.cancel();
    await _detachClient();
  }
}
