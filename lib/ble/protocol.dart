import 'dart:typed_data';

/// Byte layout shared with firmware/src/protocol.h. Little-endian.

const postureServiceUuid = '8f3a0001-7c2b-4d6e-9a10-b1c2d3e4f5a6';
const postureLiveUuid = '8f3a0012-7c2b-4d6e-9a10-b1c2d3e4f5a6';
const postureConfigUuid = '8f3a0003-7c2b-4d6e-9a10-b1c2d3e4f5a6';
const postureCommandUuid = '8f3a0004-7c2b-4d6e-9a10-b1c2d3e4f5a6';
const postureHistoryUuid = '8f3a0005-7c2b-4d6e-9a10-b1c2d3e4f5a6';

const batteryServiceUuid = '180f';
const batteryLevelUuid = '2a19';
const deviceInfoServiceUuid = '180a';
const firmwareRevisionUuid = '2a26';

const cmdCalibrate = 1;
const cmdTestVibe = 2;
const cmdSetTime = 3;
const cmdClearHistory = 4;
const cmdRequestSync = 5;
const cmdAck = 6;

const histMinute = 1;
const histSlouch = 2;
const histEnd = 3;

const flagUpright = 1 << 0;
const flagSlouching = 1 << 1;
const flagCalibrating = 1 << 2;
const flagWorn = 1 << 3;
const flagBuzzing = 1 << 4;
const flagCalibrated = 1 << 5;
const flagPending = 1 << 6;
const flagSensorFault = 1 << 7;

class DeviceConfig {
  const DeviceConfig({
    required this.training,
    required this.thresholdDeg,
    required this.delaySeconds,
    required this.strength,
    required this.necklaceWear,
    required this.autoCalibrate,
  });

  final bool training;
  final int thresholdDeg;
  final int delaySeconds;
  final int strength;
  final bool necklaceWear;
  final bool autoCalibrate;

  static const defaults = DeviceConfig(
    training: true,
    thresholdDeg: 15,
    delaySeconds: 5,
    strength: 70,
    necklaceWear: false,
    autoCalibrate: true,
  );

  DeviceConfig copyWith({
    bool? training,
    int? thresholdDeg,
    int? delaySeconds,
    int? strength,
    bool? necklaceWear,
    bool? autoCalibrate,
  }) {
    return DeviceConfig(
      training: training ?? this.training,
      thresholdDeg: thresholdDeg ?? this.thresholdDeg,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      strength: strength ?? this.strength,
      necklaceWear: necklaceWear ?? this.necklaceWear,
      autoCalibrate: autoCalibrate ?? this.autoCalibrate,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DeviceConfig &&
        other.training == training &&
        other.thresholdDeg == thresholdDeg &&
        other.delaySeconds == delaySeconds &&
        other.strength == strength &&
        other.necklaceWear == necklaceWear &&
        other.autoCalibrate == autoCalibrate;
  }

  @override
  int get hashCode => Object.hash(
    training,
    thresholdDeg,
    delaySeconds,
    strength,
    necklaceWear,
    autoCalibrate,
  );
}

class LiveReading {
  const LiveReading({
    required this.angleDeg,
    required this.upright,
    required this.slouching,
    required this.calibrating,
    required this.worn,
    required this.buzzing,
    required this.calibrated,
    required this.pending,
    required this.sensorFault,
    required this.battery,
    this.xMg = 0,
    this.yMg = 0,
    this.zMg = 0,
  });

  final double angleDeg;
  final bool upright;
  final bool slouching;
  final bool calibrating;
  final bool worn;
  final bool buzzing;
  final bool calibrated;
  final bool pending;
  final bool sensorFault;
  final int battery;
  final int xMg;
  final int yMg;
  final int zMg;

  static const empty = LiveReading(
    angleDeg: 0,
    upright: false,
    slouching: false,
    calibrating: false,
    worn: false,
    buzzing: false,
    calibrated: false,
    pending: false,
    sensorFault: false,
    battery: 0,
  );

  @override
  bool operator ==(Object other) {
    return other is LiveReading &&
        other.angleDeg == angleDeg &&
        other.upright == upright &&
        other.slouching == slouching &&
        other.calibrating == calibrating &&
        other.worn == worn &&
        other.buzzing == buzzing &&
        other.calibrated == calibrated &&
        other.pending == pending &&
        other.sensorFault == sensorFault &&
        other.battery == battery &&
        other.xMg == xMg &&
        other.yMg == yMg &&
        other.zMg == zMg;
  }

  @override
  int get hashCode => Object.hash(
    angleDeg,
    upright,
    slouching,
    calibrating,
    worn,
    buzzing,
    calibrated,
    pending,
    sensorFault,
    battery,
    xMg,
    yMg,
    zMg,
  );
}

sealed class HistoryRecord {
  const HistoryRecord(this.seq);
  final int seq;
}

class MinuteRecord extends HistoryRecord {
  const MinuteRecord({
    required int seq,
    required this.epoch,
    required this.uprightSeconds,
    required this.slouchSeconds,
    required this.peakAngle,
  }) : super(seq);

  final int epoch;
  final int uprightSeconds;
  final int slouchSeconds;
  final int peakAngle;
}

class SlouchRecord extends HistoryRecord {
  const SlouchRecord({
    required int seq,
    required this.startEpoch,
    required this.durationSeconds,
    required this.peakAngle,
  }) : super(seq);

  final int startEpoch;
  final int durationSeconds;
  final int peakAngle;
}

class SyncEnd extends HistoryRecord {
  const SyncEnd({required int seq, required this.complete}) : super(seq);
  final bool complete;
}

class Protocol {
  static Uint8List encodeConfig(DeviceConfig config) {
    final data = ByteData(8);
    data.setUint8(0, config.training ? 0 : 1);
    data.setUint8(1, config.thresholdDeg.clamp(5, 45));
    data.setUint8(2, config.delaySeconds.clamp(0, 30));
    data.setUint8(3, config.strength.clamp(0, 100));
    data.setUint8(4, config.necklaceWear ? 1 : 0);
    data.setUint8(5, config.autoCalibrate ? 1 : 0);
    data.setUint16(6, 0, Endian.little);
    return data.buffer.asUint8List();
  }

  static DeviceConfig decodeConfig(List<int> bytes) {
    if (bytes.length < 8) {
      throw FormatException('config packet is ${bytes.length} bytes');
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return DeviceConfig(
      training: data.getUint8(0) == 0,
      thresholdDeg: data.getUint8(1),
      delaySeconds: data.getUint8(2),
      strength: data.getUint8(3),
      necklaceWear: data.getUint8(4) == 1,
      autoCalibrate: data.getUint8(5) == 1,
    );
  }

  static LiveReading decodeLive(List<int> bytes) {
    if (bytes.length < 4) {
      throw FormatException('live packet is ${bytes.length} bytes');
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final flags = data.getUint8(2);
    return LiveReading(
      angleDeg: data.getInt16(0, Endian.little) / 10.0,
      upright: (flags & flagUpright) != 0,
      slouching: (flags & flagSlouching) != 0,
      calibrating: (flags & flagCalibrating) != 0,
      worn: (flags & flagWorn) != 0,
      buzzing: (flags & flagBuzzing) != 0,
      calibrated: (flags & flagCalibrated) != 0,
      pending: (flags & flagPending) != 0,
      sensorFault: (flags & flagSensorFault) != 0,
      battery: data.getUint8(3),
      xMg: bytes.length >= 10 ? data.getInt16(4, Endian.little) : 0,
      yMg: bytes.length >= 10 ? data.getInt16(6, Endian.little) : 0,
      zMg: bytes.length >= 10 ? data.getInt16(8, Endian.little) : 0,
    );
  }

  static HistoryRecord decodeHistory(List<int> bytes) {
    if (bytes.length < 14) {
      throw FormatException('history packet is ${bytes.length} bytes');
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final seq = data.getUint32(0, Endian.little);
    final type = data.getUint8(4);
    final epoch = data.getUint32(5, Endian.little);
    final a = data.getUint16(9, Endian.little);
    final b = data.getUint16(11, Endian.little);
    final peak = data.getUint8(13);
    switch (type) {
      case histMinute:
        return MinuteRecord(
          seq: seq,
          epoch: epoch,
          uprightSeconds: a,
          slouchSeconds: b,
          peakAngle: peak,
        );
      case histSlouch:
        return SlouchRecord(
          seq: seq,
          startEpoch: epoch,
          durationSeconds: a,
          peakAngle: peak,
        );
      case histEnd:
        return SyncEnd(seq: seq, complete: a == 1);
      default:
        throw FormatException('unknown history type $type');
    }
  }

  static Uint8List command(int id, [int? payload]) {
    if (payload == null) {
      return Uint8List.fromList([id]);
    }
    final data = ByteData(5);
    data.setUint8(0, id);
    data.setUint32(1, payload, Endian.little);
    return data.buffer.asUint8List();
  }
}
