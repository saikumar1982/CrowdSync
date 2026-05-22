import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_theme.dart';
import '../models/app_mode.dart';
import '../providers/app_providers.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/equalizer_visualizer.dart';
import '../widgets/neon_card.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/sync_quality_badge.dart';

class HostDashboardScreen extends ConsumerWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final room = state.room;

    return AppScaffold(
      title: 'Host Dashboard',
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
          if (room != null)
            NeonCard(
              accent: AppTheme.cyan,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${room.roomId}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text('Password ${room.password}'),
                        const SizedBox(height: 8),
                        Text(
                          '${state.users.length} connected',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${state.activeSyncMode.label} ${state.activeSyncMode.marketingName}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Tree depth ${state.hopCount} • worst-case ${state.activeSyncMode.worstCaseLatencyMs(hopCount: state.hopCount)}ms',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (state.modeWarning != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            state.modeWarning!,
                            style: const TextStyle(color: AppTheme.amber),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 132,
                    height: 132,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(data: room.qrPayload),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.trackName ?? 'No track selected',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Select local audio',
                      onPressed: state.busy ? null : controller.selectTrack,
                      icon: const Icon(Icons.library_music_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                EqualizerVisualizer(active: state.isPlaying),
                const SizedBox(height: 8),
                _ProgressRow(
                  position: state.position,
                  duration: state.duration,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Seek back',
                      onPressed: state.hasTrack
                          ? () =>
                                controller.seekBy(const Duration(seconds: -10))
                          : null,
                      icon: const Icon(Icons.replay_10_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryActionButton(
                        icon: state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        label: state.isPlaying ? 'Pause' : 'Start',
                        onPressed: state.hasTrack
                            ? controller.togglePlay
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Seek forward',
                      onPressed: state.hasTrack
                          ? () => controller.seekBy(const Duration(seconds: 10))
                          : null,
                      icon: const Icon(Icons.forward_10_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonCard(
            accent: AppTheme.lime,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Timing',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SyncQualityBadge(
                  quality: state.sync.quality,
                  driftMs: state.sync.driftMs,
                  rttMs: state.sync.rttMs,
                ),
                const SizedBox(height: 16),
                Text('Client timing offset ${state.globalLatencyOffsetMs}ms'),
                const SizedBox(height: 6),
                Text(
                  'Mode cap ${state.activeSyncMode.maxSupportedClients} clients • flash ${state.activeSyncMode.supportsFlashAtHop(state.hopCount) ? 'enabled' : 'audio only'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Slider(
                  value: state.globalLatencyOffsetMs.toDouble(),
                  min: -120,
                  max: 120,
                  divisions: 48,
                  label: '${state.globalLatencyOffsetMs}ms',
                  onChanged: (value) =>
                      controller.setGlobalLatencyOffset(value),
                ),
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
                  'Flashlight',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SegmentedButton<FlashlightMode>(
                  segments: FlashlightMode.values
                      .map(
                        (mode) =>
                            ButtonSegment(value: mode, label: Text(mode.label)),
                      )
                      .toList(),
                  selected: {state.flashlightMode},
                  onSelectionChanged: (selection) =>
                      controller.setFlashlightMode(selection.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Users',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (state.users.isEmpty)
                  const Text(
                    'Waiting for Android phones to join this room.',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  for (final user in state.users.values)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_android_rounded),
                      title: Text(user.name),
                      subtitle: Text(user.quality.label),
                      trailing: IconButton(
                        tooltip: 'Remove user',
                        onPressed: () => controller.removeUser(user.endpointId),
                        icon: const Icon(Icons.person_remove_rounded),
                      ),
                    ),
              ],
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

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.position, required this.duration});

  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(_fmt(position)), Text(_fmt(duration))],
        ),
      ],
    );
  }

  String _fmt(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
