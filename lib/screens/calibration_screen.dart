import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/app_mode.dart';
import '../providers/app_providers.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/neon_card.dart';
import '../widgets/primary_action_button.dart';

class CalibrationScreen extends ConsumerWidget {
  const CalibrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final routerMode = state.activeSyncMode == SyncMode.router;

    return AppScaffold(
      title: 'Calibration',
      leading: IconButton(
        tooltip: 'Back',
        onPressed: controller.backToDashboard,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonCard(
            accent: AppTheme.lime,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device offset ${state.calibrationOffsetMs}ms',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Star/Mesh use this 5-click test for phone-speaker latency. Router mode uses LAN NTP only.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                PrimaryActionButton(
                  icon: Icons.ads_click_rounded,
                  label: routerMode ? 'Router NTP active' : 'Play 5-Click Test',
                  onPressed: routerMode
                      ? null
                      : () async {
                          for (var i = 0; i < 5; i += 1) {
                            await controller.playCalibrationClick();
                            await Future<void>.delayed(
                              const Duration(milliseconds: 300),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            icon: Icons.check_circle_rounded,
            label: 'Perfect',
            onPressed: () => controller.recalibrate('perfect'),
          ),
          const SizedBox(height: 10),
          PrimaryActionButton(
            icon: Icons.fast_rewind_rounded,
            label: 'Slightly Early',
            filled: false,
            onPressed: () => controller.recalibrate('early'),
          ),
          const SizedBox(height: 10),
          PrimaryActionButton(
            icon: Icons.fast_forward_rounded,
            label: 'Slightly Late',
            filled: false,
            onPressed: () => controller.recalibrate('late'),
          ),
        ],
      ),
    );
  }
}
