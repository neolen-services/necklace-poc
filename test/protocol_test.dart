import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:necklace_poc/ble/protocol.dart';

void main() {
  test('config round trip', () {
    const config = DeviceConfig(
      training: false,
      thresholdDeg: 20,
      delaySeconds: 3,
      strength: 40,
      necklaceWear: true,
      autoCalibrate: false,
    );
    final bytes = Protocol.encodeConfig(config);
    expect(bytes.length, 8);
    expect(Protocol.decodeConfig(bytes), config);
  });

  test('live packet flags and angle', () {
    final data = ByteData(4);
    data.setInt16(0, 155, Endian.little);
    data.setUint8(2, flagSlouching | flagWorn | flagBuzzing | flagCalibrated);
    data.setUint8(3, 86);
    final live = Protocol.decodeLive(data.buffer.asUint8List());
    expect(live.angleDeg, closeTo(15.5, 0.001));
    expect(live.slouching, isTrue);
    expect(live.worn, isTrue);
    expect(live.buzzing, isTrue);
    expect(live.calibrated, isTrue);
    expect(live.upright, isFalse);
    expect(live.battery, 86);
    expect(live.xMg, 0);
  });

  test('live packet raw acceleration', () {
    final data = ByteData(10);
    data.setInt16(4, 401, Endian.little);
    data.setInt16(6, -480, Endian.little);
    data.setInt16(8, 780, Endian.little);
    final live = Protocol.decodeLive(data.buffer.asUint8List());
    expect(live.xMg, 401);
    expect(live.yMg, -480);
    expect(live.zMg, 780);
  });

  test('history minute, slouch, and end packets', () {
    final minute = ByteData(14);
    minute.setUint32(0, 4, Endian.little);
    minute.setUint8(4, histMinute);
    minute.setUint32(5, 1700000000, Endian.little);
    minute.setUint16(9, 40, Endian.little);
    minute.setUint16(11, 20, Endian.little);
    minute.setUint8(13, 18);
    final decoded = Protocol.decodeHistory(minute.buffer.asUint8List());
    expect(decoded, isA<MinuteRecord>());
    final asMinute = decoded as MinuteRecord;
    expect(asMinute.seq, 4);
    expect(asMinute.epoch, 1700000000);
    expect(asMinute.uprightSeconds, 40);
    expect(asMinute.slouchSeconds, 20);
    expect(asMinute.peakAngle, 18);

    final slouch = ByteData(14);
    slouch.setUint32(0, 9, Endian.little);
    slouch.setUint8(4, histSlouch);
    slouch.setUint32(5, 1700000100, Endian.little);
    slouch.setUint16(9, 22, Endian.little);
    slouch.setUint8(13, 27);
    final event = Protocol.decodeHistory(slouch.buffer.asUint8List()) as SlouchRecord;
    expect(event.durationSeconds, 22);
    expect(event.peakAngle, 27);

    final command = Protocol.command(cmdAck, 9);
    expect(command.length, 5);
    expect(command[0], cmdAck);
    expect(ByteData.sublistView(command).getUint32(1, Endian.little), 9);
  });
}
