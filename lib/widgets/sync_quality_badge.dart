import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/app_mode.dart';

class SyncQualityBadge extends StatelessWidget {
  const SyncQualityBadge({
    super.key,
    required this.quality,
    required this.driftMs,
    required this.rttMs,
  });

  final SyncQuality quality;
  final int driftMs;
  final int rttMs;

  @override
  Widget build(BuildContext context) {
    final color = switch (quality) {
      SyncQuality.excellent => AppTheme.lime,
      SyncQuality.good => AppTheme.amber,
      SyncQuality.poor => AppTheme.danger,
      SyncQuality.disconnected => Colors.grey,
      SyncQuality.unknown => AppTheme.cyan,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Text('${quality.label}  ${driftMs}ms drift  ${rttMs}ms RTT'),
        ],
      ),
    );
  }
}
