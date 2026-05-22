import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/app_mode.dart';
import '../providers/app_providers.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/neon_card.dart';
import '../widgets/primary_action_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    if (_nameController.text.isEmpty) {
      _nameController.text = state.deviceName;
    }

    return AppScaffold(
      title: 'Settings',
      leading: IconButton(
        tooltip: 'Back',
        onPressed: state.mode == AppMode.idle
            ? controller.goHome
            : controller.backToDashboard,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Device name',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryActionButton(
                  icon: Icons.save_rounded,
                  label: 'Save Name',
                  onPressed: () =>
                      controller.saveDeviceName(_nameController.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonCard(
            accent: AppTheme.cyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version 1 scope',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Android-only, local Wi-Fi or hotspot, local files, no cloud backend, no Spotify, no iOS host.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text('Calibration: ${state.calibrationOffsetMs}ms'),
                Text(
                  'Nearby permission: ${state.permissionsReady ? 'ready' : 'needs approval'}',
                ),
                const SizedBox(height: 8),
                Text('Current sync engine: ${state.activeSyncMode.label}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonCard(
            accent: AppTheme.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Advanced: Force Mode',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ForceSyncMode>(
                  initialValue: state.forceSyncMode,
                  decoration: const InputDecoration(
                    labelText: 'Mode override',
                    prefixIcon: Icon(Icons.tune_rounded),
                  ),
                  items: ForceSyncMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode.label),
                        ),
                      )
                      .toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      controller.setForceSyncMode(mode);
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Default Auto picks Star, Mesh, or Router from expected room size.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            icon: Icons.tune_rounded,
            label: 'Open Calibration',
            filled: false,
            onPressed: controller.openCalibration,
          ),
        ],
      ),
    );
  }
}
