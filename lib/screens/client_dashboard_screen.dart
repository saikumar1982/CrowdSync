import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/app_mode.dart';
import '../providers/app_providers.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/equalizer_visualizer.dart';
import '../widgets/neon_card.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/sync_quality_badge.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    return AppScaffold(
      title: 'Client Dashboard',
      leading: IconButton(
        tooltip: 'Leave room',
        onPressed: controller.leaveRoom,
        icon: const Icon(Icons.close_rounded),
      ),
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
            accent: AppTheme.cyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.room == null
                      ? 'Joining room'
                      : 'Room ${state.room!.roomId}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.hostEndpointId == null
                      ? 'Discovering host over Nearby Connections'
                      : 'Connected to host',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Synced via: ${state.activeSyncMode.label}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (state.activeSyncMode == SyncMode.mesh)
                  Text(
                    'Hop ${state.hopCount} • ${state.activeSyncMode.supportsFlashAtHop(state.hopCount) ? 'flash enabled' : 'audio only'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (state.modeWarning != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    state.modeWarning!,
                    style: const TextStyle(color: AppTheme.amber),
                  ),
                ],
                const SizedBox(height: 16),
                SyncQualityBadge(
                  quality: state.sync.quality,
                  driftMs: state.sync.driftMs,
                  rttMs: state.sync.rttMs,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonCard(
            accent: AppTheme.magenta,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  state.trackName ?? 'Waiting for host track',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                EqualizerVisualizer(active: state.isPlaying),
                const SizedBox(height: 12),
                Text(
                  state.statusText,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryActionButton(
                        icon: Icons.sync_rounded,
                        label: 'Recalibrate',
                        onPressed: controller.openCalibration,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Manual resync',
                      onPressed: controller.requestResync,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonCard(
            accent: AppTheme.amber,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.flash_on_rounded),
              title: const Text('Flashlight opt-in'),
              subtitle: Text('Host mode: ${state.flashlightMode.label}'),
              value: state.localFlashlightEnabled,
              onChanged: controller.setLocalFlashlightEnabled,
            ),
          ),
          if (state.errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorText!,
              style: const TextStyle(color: AppTheme.danger),
            ),
          ],
        ],
      ),
    );
  }
}
