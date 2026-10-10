import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/ble_posture_client.dart';
import '../../ble/permissions.dart';
import '../../core/theme.dart';
import '../../state/posture_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  var _scanning = false;
  String? _error;
  List<NearbyPostureDevice> _devices = const [];

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
      _devices = const [];
    });
    try {
      final allowed = await ensureBlePermissions();
      if (!allowed) {
        setState(() => _error = 'Bluetooth permission is required to find the necklace.');
        return;
      }
      final adapter = await FlutterBluePlus.adapterState.first;
      if (adapter != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }
      final found = await scanForPostureDevices();
      if (!mounted) return;
      setState(() {
        _devices = found;
        _error = found.isEmpty
            ? 'No necklace found. Charge it, then hold it close and scan again.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Scan failed ($error). Turn Bluetooth on and try again.');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          children: [
            const Text(
              'POSTURE TRAINER',
              style: TextStyle(
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Buzzes when you slouch.',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.15),
            ),
            const SizedBox(height: 12),
            const Text(
              'Put the sensor on your upper back, calibrate upright, and the necklace reminds you the moment you drift forward.',
              style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 16),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _scanning ? null : _scan,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_scanning ? 'Scanning…' : 'Scan for necklace'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.muted, height: 1.35)),
            ],
            if (_devices.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Nearby', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final device in _devices)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth, color: AppColors.orange),
                    title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(device.id),
                    trailing: Text('${device.rssi}', style: const TextStyle(color: AppColors.muted)),
                    onTap: () => ref.read(postureControllerProvider.notifier).pairDevice(device.id, device.name),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(postureControllerProvider.notifier).useSimulator(),
              child: const Text('Preview with a simulated device'),
            ),
          ],
        ),
      ),
    );
  }
}
