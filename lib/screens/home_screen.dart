import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/app_mode.dart';
import '../providers/app_providers.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/equalizer_visualizer.dart';
import '../widgets/neon_card.dart';
import '../widgets/primary_action_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _roomController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return AppScaffold(
      title: 'CrowdSync',
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: controller.openSettings,
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonCard(
            accent: AppTheme.magenta,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local phone speaker rooms',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Android MVP using Nearby Connections, local MP3 transfer, and buffered timestamp playback.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                EqualizerVisualizer(active: !state.busy, height: 68),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonCard(
            accent: AppTheme.cyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Room Size',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SegmentedButton<RoomSizePreset>(
                  segments: RoomSizePreset.values
                      .map(
                        (preset) => ButtonSegment(
                          value: preset,
                          label: Text(preset.label),
                          icon: Icon(switch (preset) {
                            RoomSizePreset.small => Icons.home_rounded,
                            RoomSizePreset.medium => Icons.festival_rounded,
                            RoomSizePreset.large => Icons.router_rounded,
                          }),
                        ),
                      )
                      .toList(),
                  selected: {state.selectedRoomSize},
                  onSelectionChanged: state.busy
                      ? null
                      : (selection) =>
                            controller.setRoomSizePreset(selection.first),
                ),
                const SizedBox(height: 10),
                Text(
                  state.selectedRoomSize.description,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: ${state.activeSyncMode.label} ${state.activeSyncMode.marketingName}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (state.activeSyncMode == SyncMode.router) ...[
                  const SizedBox(height: 8),
                  const Text(
                    "Connect this phone + all guests to WiFi: CrowdSync_5G",
                    style: TextStyle(color: AppTheme.amber),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            icon: Icons.add_circle_rounded,
            label: state.busy ? 'Working...' : 'Create Room',
            onPressed: state.busy ? null : controller.createRoom,
          ),
          const SizedBox(height: 18),
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join Room',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _roomController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Room ID',
                    counterText: '',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryActionButton(
                        icon: Icons.login_rounded,
                        label: 'Join',
                        onPressed: state.busy
                            ? null
                            : () => controller.joinRoom(
                                _roomController.text,
                                _passwordController.text,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Scan QR',
                      onPressed: state.busy ? null : controller.openScanner,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (state.errorText != null) ...[
            const SizedBox(height: 14),
            Text(
              state.errorText!,
              style: const TextStyle(color: AppTheme.danger),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Only play audio you own. Does not modify other apps. For private events.',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
