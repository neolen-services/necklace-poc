import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/posture_client.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../state/posture_controller.dart';

class DevicePage extends ConsumerWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(postureControllerProvider.select((s) => s.config));
    final status = ref.watch(postureControllerProvider.select((s) => s.status));
    final firmware = ref.watch(postureControllerProvider.select((s) => s.firmware));
    final simulator = ref.watch(postureControllerProvider.select((s) => s.simulator));
    final battery = ref.watch(postureControllerProvider.select((s) => s.live.battery));
    final notifier = ref.read(postureControllerProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SegmentedChoice(
                labels: const ['Training', 'Tracking only'],
                index: config.training ? 0 : 1,
                onChanged: (index) => notifier.updateConfig(config.copyWith(training: index == 0)),
              ),
              const SizedBox(height: 8),
              Text(
                config.training
                    ? 'Vibrates when you slouch past your upright position.'
                    : 'Silent. Records posture without buzzing.',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('How you wear it', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              SegmentedChoice(
                labels: const ['Upper back', 'Necklace'],
                index: config.necklaceWear ? 1 : 0,
                onChanged: (index) => notifier.updateConfig(config.copyWith(necklaceWear: index == 1)),
              ),
              const SizedBox(height: 8),
              Text(
                config.necklaceWear
                    ? 'Sensor hangs at the base of the neck on the cord.'
                    : 'Attached with the reusable silicone adhesive.',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              IconRow(
                icon: Icons.center_focus_strong_outlined,
                title: 'Auto calibration',
                subtitle: 'Learns your upright position when you put it on',
                trailing: Switch(
                  value: config.autoCalibrate,
                  onChanged: (value) => notifier.updateConfig(config.copyWith(autoCalibrate: value)),
                  thumbColor: const WidgetStatePropertyAll(Colors.white),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return AppColors.orange;
                    return const Color(0xFFE4E4E7);
                  }),
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              InkWell(
                onTap: () => notifier.calibrate(),
                child: const IconRow(
                  icon: Icons.schedule,
                  title: 'Recalibrate now',
                  subtitle: 'Sit upright and hold still for a moment',
                  trailing: Icon(Icons.chevron_right, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Buzz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _SliderRow(
                label: 'Reminder angle',
                valueLabel: '${config.thresholdDeg}°',
                value: config.thresholdDeg.toDouble(),
                min: 5,
                max: 40,
                divisions: 35,
                onChanged: (value) => notifier.updateConfig(config.copyWith(thresholdDeg: value.round())),
              ),
              _SliderRow(
                label: 'Delay',
                valueLabel: '${config.delaySeconds}s',
                value: config.delaySeconds.toDouble(),
                min: 0,
                max: 15,
                divisions: 15,
                onChanged: (value) => notifier.updateConfig(config.copyWith(delaySeconds: value.round())),
              ),
              _SliderRow(
                label: 'Strength',
                valueLabel: '${config.strength}',
                value: config.strength.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: (value) => notifier.updateConfig(config.copyWith(strength: value.round())),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => notifier.testVibration(),
                  icon: const Icon(Icons.vibration, size: 18),
                  label: const Text('Test vibration'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.orangeDeep),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              const IconRow(
                icon: Icons.water_drop_outlined,
                title: 'Splash-proof',
                subtitle: "Fine for sweat and light rain. Don't submerge.",
              ),
              const Divider(height: 1, color: AppColors.line),
              const IconRow(
                icon: Icons.cable,
                title: 'Charging',
                subtitle: 'USB-C. Store in the case when not in use.',
              ),
              const Divider(height: 1, color: AppColors.line),
              IconRow(
                icon: Icons.memory,
                title: 'Firmware',
                subtitle: simulator ? 'Simulated device' : _firmwareStatus(status),
                trailing: Text(
                  firmware ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (battery > 0) ...[
                const Divider(height: 1, color: AppColors.line),
                IconRow(
                  icon: Icons.battery_std,
                  title: 'Battery',
                  subtitle: 'From the device',
                  trailing: Text(
                    '$battery%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: () async {
            final forget = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Forget this device?'),
                content: const Text(
                  'The app will unpair. Posture history already saved on this phone stays.',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Forget')),
                ],
              ),
            );
            if (forget == true) await notifier.forget();
          },
          icon: const Icon(Icons.link_off),
          label: const Text('Forget this device'),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
        ),
      ],
    );
  }

  String _firmwareStatus(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.connected => 'Up to date',
      ConnectionStatus.connecting => 'Connecting…',
      ConnectionStatus.reconnecting => 'Reconnecting…',
      ConnectionStatus.disconnected => 'Not connected',
    };
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(valueLabel, style: const TextStyle(color: AppColors.orangeDeep, fontWeight: FontWeight.w700)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.orange,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
