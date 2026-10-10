import 'package:flutter_test/flutter_test.dart';
import 'package:necklace_poc/data/stats.dart';

void main() {
  const offset = Duration(hours: 5, minutes: 30);

  int epochAt(int year, int month, int day, int hour, [int minute = 0]) {
    final wall = DateTime.utc(year, month, day, hour, minute);
    return wall.subtract(offset).millisecondsSinceEpoch ~/ 1000;
  }

  MinuteSample wear(int year, int month, int day, int hour, int upright, int slouch) {
    return MinuteSample(
      minuteEpoch: epochAt(year, month, day, hour),
      uprightSeconds: upright,
      slouchSeconds: slouch,
      peakAngle: 20,
    );
  }

  test('score is upright time over wear time', () {
    expect(postureScore(78, 22), 78);
    expect(postureScore(0, 0), 0);
  });

  test('hourly buckets and weekly delta use the local offset', () {
    final stats = buildDashboard(
      minutes: [
        wear(2026, 10, 10, 9, 40 * 60, 8 * 60),
        wear(2026, 10, 10, 12, 20 * 60, 20 * 60),
        wear(2026, 10, 9, 10, 50 * 60, 10 * 60),
      ],
      slouches: [
        SlouchSample(startEpoch: epochAt(2026, 10, 10, 12, 15), durationSeconds: 65, peakAngle: 24),
        SlouchSample(startEpoch: epochAt(2026, 10, 10, 9, 30), durationSeconds: 15, peakAngle: 18),
      ],
      utcOffset: offset,
      nowLocal: DateTime.utc(2026, 10, 10, 15),
    );

    expect(stats.today.hourlyUprightPercent[9], postureScore(40 * 60, 8 * 60));
    expect(stats.today.hourlyUprightPercent[12], 50);
    expect(stats.today.hourlyUprightPercent[8], isNull);
    expect(stats.today.slouchCount, 2);
    expect(stats.today.avgSlouchSeconds, 40);
    expect(stats.last7.last.day, DateTime.utc(2026, 10, 10));
    expect(stats.last7.first.day, DateTime.utc(2026, 10, 4));
    expect(stats.hasWeekComparison, isTrue);
  });

  test('streak counts today only when the goal is already met', () {
    final days = <MinuteSample>[];
    for (final day in [8, 9, 10]) {
      days.add(wear(2026, 10, day, 11, 50 * 60, 5 * 60));
    }
    final met = buildDashboard(
      minutes: days,
      slouches: const [],
      utcOffset: offset,
      nowLocal: DateTime.utc(2026, 10, 10, 18),
    );
    expect(met.streak, 3);

    final openToday = buildDashboard(
      minutes: [wear(2026, 10, 9, 11, 50 * 60, 5 * 60)],
      slouches: const [],
      utcOffset: offset,
      nowLocal: DateTime.utc(2026, 10, 10, 10),
    );
    expect(openToday.streak, 1);

    final broken = buildDashboard(
      minutes: [
        wear(2026, 10, 8, 11, 50 * 60, 5 * 60),
        wear(2026, 10, 9, 11, 10 * 60, 40 * 60),
        wear(2026, 10, 10, 11, 50 * 60, 5 * 60),
      ],
      slouches: const [],
      utcOffset: offset,
      nowLocal: DateTime.utc(2026, 10, 10, 18),
    );
    expect(broken.streak, 1);
  });

  test('open minute replaces a thinner stored minute', () {
    const stored = [
      MinuteSample(minuteEpoch: 100, uprightSeconds: 10, slouchSeconds: 0, peakAngle: 4),
    ];
    const open = [
      OpenMinute(minuteEpoch: 100, uprightSeconds: 20, slouchSeconds: 5, peakAngle: 12),
      OpenMinute(minuteEpoch: 160, uprightSeconds: 3, slouchSeconds: 1, peakAngle: 8),
    ];
    final merged = mergeOpenMinutes(stored, open);
    expect(merged, hasLength(2));
    expect(merged.first.uprightSeconds, 20);
    expect(merged.last.minuteEpoch, 160);
  });
}
