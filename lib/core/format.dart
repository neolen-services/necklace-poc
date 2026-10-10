const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatWear(int seconds) {
  if (seconds < 0) seconds = 0;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours == 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}

String formatClock(int seconds) {
  if (seconds < 0) seconds = 0;
  final minutes = seconds ~/ 60;
  final remain = seconds % 60;
  return '$minutes:${remain.toString().padLeft(2, '0')}';
}

String formatHourLabel(int hour) {
  final h = hour % 12;
  return '${h == 0 ? 12 : h}';
}

String formatWeekday(DateTime day) => _weekdays[day.weekday - 1];

String formatTimeOfDay(int epochSeconds, Duration utcOffset) {
  final wall = DateTime.utc(1970).add(Duration(seconds: epochSeconds) + utcOffset);
  final hour = wall.hour.toString().padLeft(2, '0');
  final minute = wall.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatCalibration(DateTime? when, {required bool calibratedOnDevice}) {
  if (when == null) {
    return calibratedOnDevice ? 'Calibrated on device' : 'Not calibrated yet';
  }
  final now = DateTime.now();
  final hh = when.hour.toString().padLeft(2, '0');
  final mm = when.minute.toString().padLeft(2, '0');
  final sameDay =
      now.year == when.year && now.month == when.month && now.day == when.day;
  if (sameDay) return 'Calibrated today, $hh:$mm';
  return 'Calibrated ${when.day}/${when.month}, $hh:$mm';
}

String formatDegrees(double angle) => '${angle.round()}°';
