import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/posture_client.dart';
import '../../ble/protocol.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/stats.dart';
import '../../state/dashboard.dart';
import '../../state/posture_controller.dart';
import 'charts.dart';
import 'gauge.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardProvider);
    final offset = DateTime.now().timeZoneOffset;
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => ref.read(postureControllerProvider.notifier).requestSync(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const LiveCard(),
          const SizedBox(height: 10),
          const CalibrationRow(),
          const SizedBox(height: 14),
          ScoreCard(stats: dash),
          const SizedBox(height: 12),
          StatRow(stats: dash.today),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Upright by hour',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('Today', style: TextStyle(color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Each bar is how much of that hour you were upright.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                HourlyBars(hours: dash.today.hourlyUprightPercent, goal: kGoalPercent),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Last 7 days',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('% upright', style: TextStyle(color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 8),
                WeekChart(days: dash.last7, goal: kGoalPercent),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SlouchCard(events: dash.today.slouches, offset: offset),
          const SizedBox(height: 12),
          const DisclaimerCard(),
        ],
      ),
    );
  }
}

class LiveCard extends ConsumerWidget {
  const LiveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(postureControllerProvider.select((s) => s.live));
    final config = ref.watch(postureControllerProvider.select((s) => s.config));
    final status = ref.watch(postureControllerProvider.select((s) => s.status));
    final connected = status == ConnectionStatus.connected;
    final title = _postureTitle(live, connected);
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: connected ? AppColors.orange : AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                connected ? 'Live' : _statusLabel(status),
                style: TextStyle(
                  color: connected ? AppColors.orangeDeep : AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bluetooth, size: 14, color: AppColors.muted),
                    SizedBox(width: 4),
                    Text(
                      'POSTURE TRAINER',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          PostureGauge(
            angle: connected ? live.angleDeg : 0,
            threshold: config.thresholdDeg,
          ),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            connected
                ? '${formatDegrees(live.angleDeg)} forward · reminder at ${config.thresholdDeg}°'
                : 'Waiting for the necklace',
            style: const TextStyle(color: AppColors.muted),
          ),
          if (live.sensorFault) ...[
            const SizedBox(height: 8),
            const Text(
              'The motion sensor is not responding.',
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.connecting => 'Connecting',
      ConnectionStatus.reconnecting => 'Reconnecting',
      ConnectionStatus.connected => 'Live',
      ConnectionStatus.disconnected => 'Offline',
    };
  }

  String _postureTitle(LiveReading live, bool connected) {
    if (!connected) return 'Offline';
    if (live.sensorFault) return 'Sensor error';
    if (!live.calibrated) return 'Calibrate';
    if (live.slouching) return 'Slouching';
    if (live.pending) return 'Leaning';
    return 'Upright';
  }
}

class CalibrationRow extends ConsumerWidget {
  const CalibrationRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final when = ref.watch(postureControllerProvider.select((s) => s.calibratedAt));
    final onDevice = ref.watch(
      postureControllerProvider.select((s) => s.live.calibrated),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatCalibration(when, calibratedOnDevice: onDevice),
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton.icon(
            onPressed: () => ref.read(postureControllerProvider.notifier).calibrate(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Recalibrate'),
            style: TextButton.styleFrom(foregroundColor: AppColors.orangeDeep),
          ),
        ],
      ),
    );
  }
}

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final today = stats.today;
    final delta = stats.deltaVsWeek;
    final comparison = !stats.hasWeekComparison
        ? 'Goal $kGoalPercent% upright.'
        : delta >= 0
        ? 'Goal $kGoalPercent% upright. Up $delta points on your weekly average.'
        : 'Goal $kGoalPercent% upright. Down ${delta.abs()} points on your weekly average.';
    return AppCard(
      child: Row(
        children: [
          ScoreRing(percent: today.score),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Posture score',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(comparison, style: const TextStyle(color: AppColors.muted, height: 1.35)),
                if (stats.streak > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${stats.streak}-day streak',
                    style: const TextStyle(
                      color: AppColors.orangeDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.stats});

  final DaySummary stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          _Stat(value: formatWear(stats.wearSeconds), label: 'Wear time'),
          _Stat(value: '${stats.slouchCount}', label: 'Slouch events'),
          _Stat(value: formatClock(stats.avgSlouchSeconds), label: 'Avg. slouch'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class SlouchCard extends StatelessWidget {
  const SlouchCard({super.key, required this.events, required this.offset});

  final List<SlouchSample> events;
  final Duration offset;

  @override
  Widget build(BuildContext context) {
    final shown = events.take(6).toList();
    final longest = events.fold<int>(0, (max, event) {
      return event.durationSeconds > max ? event.durationSeconds : max;
    });
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Slouch events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                events.isEmpty ? 'None yet' : 'Longest ${formatClock(longest)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No slouches recorded today.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (final event in shown)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Text(
                      formatTimeOfDay(event.startEpoch, offset),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${formatClock(event.durationSeconds)} min',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.muted, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'The device tracks how far your upper back tilts forward from your calibrated upright position, and for how long. It does not measure your spine directly, detect shoulder drop or lower-back arching, or diagnose a condition.',
              style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
