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
      height: 168,
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
    final cx = size.width / 2;
    final cy = size.height - 18;
    final radius = min(size.width * 0.42, cy - 8);
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = AppColors.cream;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = AppColors.orange;

    canvas.drawArc(rect, pi, -pi, false, track);
    final shown = angle.clamp(0, maxAngle);
    if (shown > 0.4) {
      canvas.drawArc(rect, pi, -pi * (shown / maxAngle), false, fill);
    }

    final mark = pi * (1 - (threshold / maxAngle).clamp(0, 1));
    final dot = Paint()..color = const Color(0xFFB9B4AE);
    for (var i = 0; i < 7; i++) {
      final r = radius * (0.62 + 0.38 * i / 6);
      canvas.drawCircle(Offset(cx + cos(mark) * r, cy - sin(mark) * r), 1.5, dot);
    }

    final needle = pi * (1 - shown / maxAngle);
    final tip = Offset(cx + cos(needle) * (radius - 28), cy - sin(needle) * (radius - 28));
    canvas.drawLine(
      Offset(cx, cy),
      tip,
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 7, Paint()..color = AppColors.ink);
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = Colors.white);

    _label(canvas, '0°', Offset(cx - radius - 4, cy + 8), TextAlign.left);
    _label(canvas, '40°', Offset(cx + radius - 18, cy + 8), TextAlign.right);
  }

  void _label(Canvas canvas, String text, Offset offset, TextAlign align) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    painter.paint(canvas, offset);
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
