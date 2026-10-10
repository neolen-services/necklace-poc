import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class PostureGauge extends StatelessWidget {
  const PostureGauge({super.key, required this.angle, required this.threshold});

  final double angle;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      width: double.infinity,
      child: CustomPaint(
        painter: _GaugePainter(angle: angle, threshold: threshold.toDouble()),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.angle, required this.threshold});

  final double angle;
  final double threshold;

  @override
  void paint(Canvas canvas, Size size) {
    const maxAngle = 40.0;
    const stroke = 14.0;
    final cx = size.width / 2;
    final radius = min((size.width - 64) / 2, size.height - 46);
    final cy = 10 + stroke / 2 + radius;

    // t = 0 is the left end (0°), t = 1 is the right end (40°), along the top.
    Offset at(double t, double r) {
      final a = pi * (1 - t);
      return Offset(cx + cos(a) * r, cy - sin(a) * r);
    }

    Path band(double from, double to) {
      final path = Path()..moveTo(at(from, radius).dx, at(from, radius).dy);
      final steps = max(12, ((to - from) * 64).round());
      for (var i = 1; i <= steps; i++) {
        final p = at(from + (to - from) * i / steps, radius);
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFF8E7C8);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.orange;
    final trackDot = Paint()..color = const Color(0xFFF8E7C8);
    final fillDot = Paint()..color = AppColors.orange;

    canvas.drawPath(band(0, 1), track);
    canvas.drawCircle(at(0, radius), stroke / 2, trackDot);
    canvas.drawCircle(at(1, radius), stroke / 2, trackDot);

    final shown = angle.clamp(0, maxAngle) / maxAngle;
    if (shown > 0.012) {
      canvas.drawPath(band(0, shown), fill);
      canvas.drawCircle(at(0, radius), stroke / 2, fillDot);
      canvas.drawCircle(at(shown, radius), stroke / 2, fillDot);
    }

    final mark = (threshold / maxAngle).clamp(0.0, 1.0);
    final dash = Paint()..color = const Color(0xFF6F6A64);
    for (var i = 0; i < 5; i++) {
      final r = radius * (0.52 + 0.28 * i / 4);
      canvas.drawCircle(at(mark, r), 1.7, dash);
    }

    final tip = at(shown, radius - stroke / 2 - 12);
    canvas.drawLine(
      Offset(cx, cy),
      tip,
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 5.5, Paint()..color = AppColors.ink);

    _label(canvas, '0°', at(0, radius) + const Offset(0, 12));
    _label(canvas, '40°', at(1, radius) + const Offset(0, 12));
  }

  void _label(Canvas canvas, String text, Offset anchor) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(anchor.dx - painter.width / 2, anchor.dy));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.threshold != threshold;
  }
}

class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: CustomPaint(
        painter: _RingPainter(percent / 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1),
              ),
              const Text('upright', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = const Color(0xFFF0F1F3);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = AppColors.orange;
    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress.clamp(0, 1), false, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
