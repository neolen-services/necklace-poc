import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'posture_database.g.dart';

class MinuteStats extends Table {
  IntColumn get minuteEpoch => integer()();
  IntColumn get uprightSeconds => integer()();
  IntColumn get slouchSeconds => integer()();
  IntColumn get peakAngle => integer()();

  @override
  Set<Column> get primaryKey => {minuteEpoch};
}

class SlouchEvents extends Table {
  IntColumn get deviceSeq => integer()();
  IntColumn get startEpoch => integer()();
  IntColumn get durationSeconds => integer()();
  IntColumn get peakAngle => integer()();

  @override
  Set<Column> get primaryKey => {deviceSeq};
}

@DriftDatabase(tables: [MinuteStats, SlouchEvents])
class PostureDatabase extends _$PostureDatabase {
  PostureDatabase() : super(driftDatabase(name: 'posture'));

  @override
  int get schemaVersion => 1;

  Stream<List<MinuteStat>> watchMinutesSince(int epoch) {
    return (select(minuteStats)
          ..where((t) => t.minuteEpoch.isBiggerOrEqualValue(epoch))
          ..orderBy([(t) => OrderingTerm(expression: t.minuteEpoch)]))
        .watch();
  }

  Stream<List<SlouchEvent>> watchSlouchesSince(int epoch) {
    return (select(slouchEvents)
          ..where((t) => t.startEpoch.isBiggerOrEqualValue(epoch))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.startEpoch,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<MinuteStat?> minuteAt(int epoch) {
    return (select(minuteStats)
          ..where((t) => t.minuteEpoch.equals(epoch)))
        .getSingleOrNull();
  }

  Future<void> upsertMinute({
    required int minuteEpoch,
    required int uprightSeconds,
    required int slouchSeconds,
    required int peakAngle,
  }) {
    return into(minuteStats).insert(
      MinuteStatsCompanion.insert(
        minuteEpoch: Value(minuteEpoch),
        uprightSeconds: uprightSeconds,
        slouchSeconds: slouchSeconds,
        peakAngle: peakAngle,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> upsertSlouch({
    required int deviceSeq,
    required int startEpoch,
    required int durationSeconds,
    required int peakAngle,
  }) {
    return into(slouchEvents).insert(
      SlouchEventsCompanion.insert(
        deviceSeq: Value(deviceSeq),
        startEpoch: startEpoch,
        durationSeconds: durationSeconds,
        peakAngle: peakAngle,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}
