import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'posture_client.dart';
import 'protocol.dart';

class NearbyPostureDevice {
  const NearbyPostureDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  final String id;
  final String name;
  final int rssi;
}

class BlePostureClient implements PostureClient {
  BlePostureClient(this.remoteId, {this.knownName = ''});

  final String remoteId;
  final String knownName;

  final _connection = StreamController<ConnectionStatus>.broadcast();
  final _live = StreamController<LiveReading>.broadcast();
  final _history = StreamController<HistoryRecord>.broadcast();
  final _configs = StreamController<DeviceConfig>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _configChar;
  BluetoothCharacteristic? _commandChar;
  StreamSubscription<List<int>>? _liveSub;
  StreamSubscription<List<int>>? _historySub;
  StreamSubscription<BluetoothConnectionState>? _stateSub;

  DeviceConfig _config = DeviceConfig.defaults;
  String? _firmware;
  bool _want = false;
  bool _closing = false;
  bool _sessionReady = false;
  int _backoffSeconds = 2;
  Timer? _retry;

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
  String? get firmware => _firmware;

  @override
  String get deviceName {
    final advertised = _device?.advName ?? '';
    if (advertised.isNotEmpty) return advertised;
    final platform = _device?.platformName ?? '';
    if (platform.isNotEmpty) return platform;
    return knownName.isEmpty ? 'MMH Posture' : knownName;
  }

  @override
  Future<void> connect() async {
    _want = true;
    _closing = false;
    _connection.add(ConnectionStatus.connecting);
    await _open(firstAttempt: true);
  }

  Future<void> _open({required bool firstAttempt}) async {
    _retry?.cancel();
    try {
      final device = BluetoothDevice.fromId(remoteId);
      _device = device;
      _stateSub ??= device.connectionState.listen(_onConnectionState);
      if (!device.isConnected) {
        // FlutterBluePlus requires a license declaration. This product is commercial.
        await device.connect(
          license: License.commercial,
          timeout: const Duration(seconds: 20),
          mtu: null,
        );
      }
      await _prepare(device);
      _backoffSeconds = 2;
      _connection.add(ConnectionStatus.connected);
    } catch (error, stack) {
      debugPrint('BLE connect failed: $error\n$stack');
      if (!_want || _closing) return;
      _connection.add(
        firstAttempt ? ConnectionStatus.disconnected : ConnectionStatus.reconnecting,
      );
      _scheduleRetry();
    }
  }

  Future<void> _prepare(BluetoothDevice device) async {
    try {
      await device.clearGattCache();
    } catch (_) {}
    final services = await device.discoverServices();
    final posture = _service(services, postureServiceUuid);
    if (posture == null) {
      throw StateError('Device does not expose the posture service');
    }
    final live = _char(posture, postureLiveUuid);
    final config = _char(posture, postureConfigUuid);
    final command = _char(posture, postureCommandUuid);
    final history = _char(posture, postureHistoryUuid);
    if (live == null || config == null || command == null || history == null) {
      throw StateError('Posture service is missing a characteristic');
    }
    _configChar = config;
    _commandChar = command;

    await _liveSub?.cancel();
    await _historySub?.cancel();
    _liveSub = live.onValueReceived.listen((value) {
      try {
        _live.add(Protocol.decodeLive(value));
      } catch (error) {
        debugPrint('Bad live packet: $error');
      }
    });
    _historySub = history.onValueReceived.listen((value) {
      try {
        _history.add(Protocol.decodeHistory(value));
      } catch (error) {
        debugPrint('Bad history packet: $error');
      }
    });
    device.cancelWhenDisconnected(_liveSub!);
    device.cancelWhenDisconnected(_historySub!);
    await live.setNotifyValue(true);
    await history.setNotifyValue(true);

    final configBytes = await config.read();
    _config = Protocol.decodeConfig(configBytes);
    _configs.add(_config);

    final info = _service(services, deviceInfoServiceUuid);
    final firmwareChar = info == null ? null : _char(info, firmwareRevisionUuid);
    if (firmwareChar != null) {
      final bytes = await firmwareChar.read();
      _firmware = String.fromCharCodes(bytes).trim();
    }
    _sessionReady = true;
  }

  void _onConnectionState(BluetoothConnectionState state) {
    if (_closing || !_want) return;
    if (state == BluetoothConnectionState.disconnected && _sessionReady) {
      _sessionReady = false;
      _connection.add(ConnectionStatus.reconnecting);
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (!_want || _closing) return;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: _backoffSeconds), () {
      if (!_want || _closing) return;
      _backoffSeconds = (_backoffSeconds * 2).clamp(2, 15);
      _open(firstAttempt: false);
    });
  }

  @override
  Future<void> disconnect() async {
    _want = false;
    _retry?.cancel();
    _sessionReady = false;
    final device = _device;
    if (device != null && device.isConnected) {
      await device.disconnect();
    }
    _connection.add(ConnectionStatus.disconnected);
  }

  @override
  Future<void> writeConfig(DeviceConfig config) async {
    final char = _configChar;
    if (char == null) return;
    _config = config;
    _configs.add(config);
    await char.write(Protocol.encodeConfig(config), withoutResponse: false);
  }

  @override
  Future<void> calibrate() => _writeCommand(Protocol.command(cmdCalibrate));

  @override
  Future<void> testVibration() => _writeCommand(Protocol.command(cmdTestVibe));

  @override
  Future<void> setTime(DateTime utc) {
    final epoch = utc.toUtc().millisecondsSinceEpoch ~/ 1000;
    return _writeCommand(Protocol.command(cmdSetTime, epoch));
  }

  @override
  Future<void> clearHistory() => _writeCommand(Protocol.command(cmdClearHistory));

  @override
  Future<void> requestSync() => _writeCommand(Protocol.command(cmdRequestSync));

  @override
  Future<void> ack(int seq) => _writeCommand(Protocol.command(cmdAck, seq));

  Future<void> _writeCommand(List<int> bytes) async {
    final char = _commandChar;
    if (char == null) {
      throw StateError('Necklace is not ready for commands');
    }
    try {
      await char.write(bytes, withoutResponse: false);
    } catch (_) {
      await char.write(bytes, withoutResponse: true);
    }
  }

  @override
  Future<void> dispose() async {
    _closing = true;
    _want = false;
    _retry?.cancel();
    await _liveSub?.cancel();
    await _historySub?.cancel();
    await _stateSub?.cancel();
    final device = _device;
    if (device != null && device.isConnected) {
      await device.disconnect();
    }
    await _connection.close();
    await _live.close();
    await _history.close();
    await _configs.close();
  }

  BluetoothService? _service(List<BluetoothService> services, String uuid) {
    final target = Guid(uuid);
    for (final service in services) {
      if (service.uuid == target) return service;
    }
    return null;
  }

  BluetoothCharacteristic? _char(BluetoothService service, String uuid) {
    final target = Guid(uuid);
    for (final characteristic in service.characteristics) {
      if (characteristic.uuid == target) return characteristic;
    }
    return null;
  }
}

Future<List<NearbyPostureDevice>> scanForPostureDevices({
  Duration timeout = const Duration(seconds: 8),
}) async {
  if (Platform.isAndroid) {
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
  }
  final found = <String, NearbyPostureDevice>{};
  final sub = FlutterBluePlus.scanResults.listen((results) {
    for (final result in results) {
      final name = result.advertisementData.advName.isNotEmpty
          ? result.advertisementData.advName
          : result.device.platformName;
      final looksLikeNecklace = name.toLowerCase().contains('mmh') ||
          name.toLowerCase().contains('posture') ||
          result.advertisementData.serviceUuids
              .map((id) => id.toString().toLowerCase())
              .contains(postureServiceUuid);
      if (!looksLikeNecklace && name.isNotEmpty) continue;
      found[result.device.remoteId.str] = NearbyPostureDevice(
        id: result.device.remoteId.str,
        name: name.isEmpty ? 'MMH Posture' : name,
        rssi: result.rssi,
      );
    }
  });
  try {
    // Name and service filters are OR'd. Some phones only match one of them.
    await FlutterBluePlus.startScan(
      withServices: [Guid(postureServiceUuid)],
      withNames: const ['MMH Posture'],
      timeout: timeout,
      androidUsesFineLocation: false,
      androidCheckLocationServices: false,
    );
    await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;
  } catch (_) {
    await FlutterBluePlus.startScan(
      withServices: [Guid(postureServiceUuid)],
      timeout: timeout,
      androidUsesFineLocation: false,
      androidCheckLocationServices: false,
    );
    await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;
  }
  await sub.cancel();
  final devices = found.values.toList()
    ..sort((a, b) => b.rssi.compareTo(a.rssi));
  return devices;
}
