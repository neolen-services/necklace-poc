import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/stats.dart';

class HourlyBars extends StatelessWidget {
  const HourlyBars({super.key, required this.hours, required this.goal});

  final List<int?> hours;
  final int goal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: CustomPaint(
        painter: _HourPainter(hours: hours, goal: goal),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HourPainter extends CustomPainter {
  _HourPainter({required this.hours, required this.goal});

  final List<int?> hours;
  final int goal;

  @override
  void paint(Canvas canvas, Size size) {
    const startHour = 9;
    const count = 9;
    final labelHeight = 22.0;
    final chartHeight = size.height - labelHeight;
    final gap = 8.0;
    final barWidth = (size.width - gap * (count - 1)) / count;
    final goalY = chartHeight * (1 - goal / 100);

    final dash = Paint()
      ..color = const Color(0xFFD5D5DA)
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, goalY), Offset(min(x + 5, size.width), goalY), dash);
      x += 9;
    }

    for (var i = 0; i < count; i++) {
      final hour = startHour + i;
      final value = hour < hours.length ? hours[hour] : null;
      final left = i * (barWidth + gap);
      final height = value == null ? chartHeight * 0.16 : chartHeight * (value / 100).clamp(0.08, 1);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, chartHeight - height, barWidth, height),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = value == null ? const Color(0xFFE6E6EA) : AppColors.orange,
      );
      final label = TextPainter(
        text: TextSpan(
          text: formatHourLabel(hour),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth);
      label.paint(canvas, Offset(left + (barWidth - label.width) / 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _HourPainter oldDelegate) {
    return oldDelegate.goal != goal || oldDelegate.hours != hours;
  }
}

class WeekChart extends StatelessWidget {
  const WeekChart({super.key, required this.days, required this.goal});

  final List<DaySummary> days;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final any = days.any((day) => day.wearSeconds > 0);
    if (!any) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Wear it for a few days to see the week.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _WeekPainter(days: days, goal: goal),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WeekPainter extends CustomPainter {
  _WeekPainter({required this.days, required this.goal});

  final List<DaySummary> days;
  final int goal;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 22.0;
    final chartHeight = size.height - labelHeight;
    final count = days.length;
    final dx = count <= 1 ? size.width : size.width / (count - 1);
    final goalY = chartHeight * (1 - goal / 100);
    final dash = Paint()
      ..color = const Color(0xFFE0B089)
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, goalY), Offset(min(x + 6, size.width), goalY), dash);
      x += 10;
    }

    final points = <Offset>[];
    for (var i = 0; i < count; i++) {
      final day = days[i];
      if (day.wearSeconds == 0) continue;
      final y = chartHeight * (1 - day.score / 100);
      points.add(Offset(i * dx, y));
    }
    if (points.length >= 2) {
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        line.lineTo(point.dx, point.dy);
      }
      final fill = Path.from(line)
        ..lineTo(points.last.dx, chartHeight)
        ..lineTo(points.first.dx, chartHeight)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x66E07A3D), Color(0x00E07A3D)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight)),
      );
      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = AppColors.orange,
      );
    }
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = AppColors.orange);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }

    for (var i = 0; i < count; i++) {
      final label = TextPainter(
        text: TextSpan(
          text: formatWeekday(days[i].day),
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(i * dx - label.width / 2, chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeekPainter oldDelegate) {
    return oldDelegate.goal != goal || oldDelegate.days != days;
  }
}
