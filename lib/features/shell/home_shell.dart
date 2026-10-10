import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/posture_client.dart';
import '../../core/theme.dart';
import '../../state/posture_controller.dart';
import '../device/device_page.dart';
import '../today/today_page.dart';
import '../training/training_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(postureControllerProvider.select((s) => s.status));
    final battery = ref.watch(postureControllerProvider.select((s) => s.live.battery));
    final connected = status == ConnectionStatus.connected;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'POSTURE TRAINER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      onPressed: () => setState(() => _index = 2),
                      icon: Icon(
                        connected ? Icons.bluetooth_connected : Icons.bluetooth,
                        color: connected ? AppColors.orange : AppColors.muted,
                      ),
                      tooltip: battery > 0 ? 'Battery $battery%' : 'Device',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _Tab(label: 'Today', selected: _index == 0, onTap: () => setState(() => _index = 0)),
                  _Tab(label: 'Training', selected: _index == 1, onTap: () => setState(() => _index = 1)),
                  _Tab(label: 'Device', selected: _index == 2, onTap: () => setState(() => _index = 2)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [TodayPage(), TrainingPage(), DevicePage()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(top: 12, bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.orange : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.orangeDeep : AppColors.muted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
