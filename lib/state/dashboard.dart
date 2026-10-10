import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/posture_database.dart';
import '../data/stats.dart';
import 'posture_controller.dart';

final minutesProvider = StreamProvider<List<MinuteStat>>((ref) {
  final db = ref.watch(databaseProvider);
  final since = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 60))
          .millisecondsSinceEpoch ~/
      1000;
  return db.watchMinutesSince(since);
});

final slouchesProvider = StreamProvider<List<SlouchEvent>>((ref) {
  final db = ref.watch(databaseProvider);
  final since = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 60))
          .millisecondsSinceEpoch ~/
      1000;
  return db.watchSlouchesSince(since);
});

final dashboardProvider = Provider<DashboardStats>((ref) {
  final minutes = ref.watch(minutesProvider).asData?.value ?? const <MinuteStat>[];
  final slouches = ref.watch(slouchesProvider).asData?.value ?? const <SlouchEvent>[];
  final open = ref.watch(
    postureControllerProvider.select((state) => state.recentMinutes),
  );
  final now = DateTime.now();
  final samples = minutes
      .map(
        (row) => MinuteSample(
          minuteEpoch: row.minuteEpoch,
          uprightSeconds: row.uprightSeconds,
          slouchSeconds: row.slouchSeconds,
          peakAngle: row.peakAngle,
        ),
      )
      .toList();
  return buildDashboard(
    minutes: mergeOpenMinutes(samples, open),
    slouches: slouches
        .map(
          (row) => SlouchSample(
            startEpoch: row.startEpoch,
            durationSeconds: row.durationSeconds,
            peakAngle: row.peakAngle,
          ),
        )
        .toList(),
    utcOffset: now.timeZoneOffset,
    nowLocal: DateTime.utc(now.year, now.month, now.day, now.hour, now.minute, now.second),
  );
});
