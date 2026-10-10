import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:necklace_poc/features/today/gauge.dart';

void main() {
  testWidgets('gauge and score ring render', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PostureGauge(angle: 9, threshold: 15),
              ScoreRing(percent: 78),
            ],
          ),
        ),
      ),
    );
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('upright'), findsOneWidget);
  });
}
