const kGoalPercent = 80;
const kStreakMinWearSeconds = 30 * 60;

class MinuteSample {
  const MinuteSample({
    required this.minuteEpoch,
    required this.uprightSeconds,
    required this.slouchSeconds,
    required this.peakAngle,
  });

  final int minuteEpoch;
  final int uprightSeconds;
  final int slouchSeconds;
  final int peakAngle;

  int get wearSeconds => uprightSeconds + slouchSeconds;
}

class SlouchSample {
  const SlouchSample({
    required this.startEpoch,
    required this.durationSeconds,
    required this.peakAngle,
  });

  final int startEpoch;
  final int durationSeconds;
  final int peakAngle;
}

class OpenMinute {
  const OpenMinute({
    required this.minuteEpoch,
    required this.uprightSeconds,
    required this.slouchSeconds,
    required this.peakAngle,
  });

  final int minuteEpoch;
  final int uprightSeconds;
  final int slouchSeconds;
  final int peakAngle;

  OpenMinute addSecond({required bool slouching, required int angleDeg}) {
    return OpenMinute(
      minuteEpoch: minuteEpoch,
      uprightSeconds: uprightSeconds + (slouching ? 0 : 1),
      slouchSeconds: slouchSeconds + (slouching ? 1 : 0),
      peakAngle: angleDeg > peakAngle ? angleDeg : peakAngle,
    );
  }

  MinuteSample toSample() {
    return MinuteSample(
      minuteEpoch: minuteEpoch,
      uprightSeconds: uprightSeconds,
      slouchSeconds: slouchSeconds,
      peakAngle: peakAngle,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OpenMinute &&
        other.minuteEpoch == minuteEpoch &&
        other.uprightSeconds == uprightSeconds &&
        other.slouchSeconds == slouchSeconds &&
        other.peakAngle == peakAngle;
  }

  @override
  int get hashCode =>
      Object.hash(minuteEpoch, uprightSeconds, slouchSeconds, peakAngle);
}

class DaySummary {
  const DaySummary({
    required this.day,
    required this.uprightSeconds,
    required this.slouchSeconds,
    required this.slouchCount,
    required this.avgSlouchSeconds,
    required this.score,
    required this.hourlyUprightPercent,
    required this.slouches,
  });

  final DateTime day;
  final int uprightSeconds;
  final int slouchSeconds;
  final int slouchCount;
  final int avgSlouchSeconds;
  final int score;

  /// 24 entries. Null when that hour has no wear.
  final List<int?> hourlyUprightPercent;
  final List<SlouchSample> slouches;

  int get wearSeconds => uprightSeconds + slouchSeconds;

  static DaySummary empty(DateTime day) {
    return DaySummary(
      day: day,
      uprightSeconds: 0,
      slouchSeconds: 0,
      slouchCount: 0,
      avgSlouchSeconds: 0,
      score: 0,
      hourlyUprightPercent: List<int?>.filled(24, null),
      slouches: const [],
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.today,
    required this.last7,
    required this.streak,
    required this.weeklyAverage,
    required this.deltaVsWeek,
    required this.hasWeekComparison,
  });

  final DaySummary today;

  /// Oldest first, ending today. Always 7 entries.
  final List<DaySummary> last7;
  final int streak;
  final int weeklyAverage;
  final int deltaVsWeek;
  final bool hasWeekComparison;

  static DashboardStats empty(DateTime today) {
    final days = List<DaySummary>.generate(
      7,
      (i) => DaySummary.empty(today.subtract(Duration(days: 6 - i))),
    );
    return DashboardStats(
      today: days.last,
      last7: days,
      streak: 0,
      weeklyAverage: 0,
      deltaVsWeek: 0,
      hasWeekComparison: false,
    );
  }
}

int postureScore(int uprightSeconds, int slouchSeconds) {
  final total = uprightSeconds + slouchSeconds;
  if (total <= 0) return 0;
  return ((uprightSeconds * 100) / total).round().clamp(0, 100);
}

/// [utcOffset] is the device's local offset. [nowLocal] is the wall clock
/// stored in a UTC [DateTime] so tests do not depend on the host timezone.
DashboardStats buildDashboard({
  required List<MinuteSample> minutes,
  required List<SlouchSample> slouches,
  required Duration utcOffset,
  required DateTime nowLocal,
  int goal = kGoalPercent,
  int minWearForStreak = kStreakMinWearSeconds,
  int historyDays = 60,
}) {
  final today = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day);
  final first = today.subtract(Duration(days: historyDays - 1));
  final byDay = <DateTime, _Acc>{};

  for (final minute in minutes) {
    final wall = _wall(minute.minuteEpoch, utcOffset);
    final day = DateTime.utc(wall.year, wall.month, wall.day);
    if (day.isBefore(first) || day.isAfter(today)) continue;
    final acc = byDay.putIfAbsent(day, _Acc.new);
    acc.upright += minute.uprightSeconds;
    acc.slouch += minute.slouchSeconds;
    final hour = wall.hour;
    acc.hourUpright[hour] += minute.uprightSeconds;
    acc.hourSlouch[hour] += minute.slouchSeconds;
  }

  for (final event in slouches) {
    final wall = _wall(event.startEpoch, utcOffset);
    final day = DateTime.utc(wall.year, wall.month, wall.day);
    if (day.isBefore(first) || day.isAfter(today)) continue;
    final acc = byDay.putIfAbsent(day, _Acc.new);
    acc.events.add(event);
  }

  final summaries = <DaySummary>[];
  for (var i = 0; i < historyDays; i++) {
    final day = first.add(Duration(days: i));
    summaries.add(_finish(day, byDay[day]));
  }

  final last7 = summaries.sublist(summaries.length - 7);
  final streak = _streak(
    summaries.reversed.toList(),
    goal: goal,
    minWear: minWearForStreak,
  );

  final earlier = last7
      .take(6)
      .where((d) => d.wearSeconds >= 10 * 60)
      .toList();
  final hasWeek = earlier.isNotEmpty && last7.last.wearSeconds > 0;
  final weekly = hasWeek
      ? (earlier.map((d) => d.score).reduce((a, b) => a + b) / earlier.length)
            .round()
      : 0;

  return DashboardStats(
    today: last7.last,
    last7: last7,
    streak: streak,
    weeklyAverage: weekly,
    deltaVsWeek: hasWeek ? last7.last.score - weekly : 0,
    hasWeekComparison: hasWeek,
  );
}

List<MinuteSample> mergeOpenMinutes(
  List<MinuteSample> stored,
  List<OpenMinute> open,
) {
  if (open.isEmpty) return stored;
  final merged = [...stored];
  for (final extra in open) {
    final sample = extra.toSample();
    final index = merged.indexWhere((m) => m.minuteEpoch == sample.minuteEpoch);
    if (index < 0) {
      merged.add(sample);
      continue;
    }
    if (sample.wearSeconds > merged[index].wearSeconds) {
      merged[index] = sample;
    }
  }
  return merged;
}

DateTime _wall(int epochSeconds, Duration utcOffset) {
  return DateTime.utc(1970).add(Duration(seconds: epochSeconds) + utcOffset);
}

DaySummary _finish(DateTime day, _Acc? acc) {
  if (acc == null) return DaySummary.empty(day);
  final hours = List<int?>.generate(24, (hour) {
    final total = acc.hourUpright[hour] + acc.hourSlouch[hour];
    if (total <= 0) return null;
    return postureScore(acc.hourUpright[hour], acc.hourSlouch[hour]);
  });
  final events = [...acc.events]
    ..sort((a, b) => b.startEpoch.compareTo(a.startEpoch));
  final avg = events.isEmpty
      ? 0
      : (events.map((e) => e.durationSeconds).reduce((a, b) => a + b) /
                events.length)
            .round();
  return DaySummary(
    day: day,
    uprightSeconds: acc.upright,
    slouchSeconds: acc.slouch,
    slouchCount: events.length,
    avgSlouchSeconds: avg,
    score: postureScore(acc.upright, acc.slouch),
    hourlyUprightPercent: hours,
    slouches: events,
  );
}

int _streak(List<DaySummary> newestFirst, {required int goal, required int minWear}) {
  var streak = 0;
  for (var i = 0; i < newestFirst.length; i++) {
    final day = newestFirst[i];
    final met = day.wearSeconds >= minWear && day.score >= goal;
    if (i == 0 && !met) continue;
    if (!met) break;
    streak++;
  }
  return streak;
}

class _Acc {
  int upright = 0;
  int slouch = 0;
  final hourUpright = List<int>.filled(24, 0);
  final hourSlouch = List<int>.filled(24, 0);
  final events = <SlouchSample>[];
}
