import 'app_mode.dart';

class SyncSnapshot {
  const SyncSnapshot({
    this.rttMicros = 0,
    this.clockOffsetMicros = 0,
    this.driftMicros = 0,
    this.quality = SyncQuality.unknown,
    this.updatedAt,
  });

  final int rttMicros;
  final int clockOffsetMicros;
  final int driftMicros;
  final SyncQuality quality;
  final DateTime? updatedAt;

  int get rttMs => (rttMicros / 1000).round();

  int get driftMs => (driftMicros / 1000).round();

  SyncSnapshot copyWith({
    int? rttMicros,
    int? clockOffsetMicros,
    int? driftMicros,
    SyncQuality? quality,
    DateTime? updatedAt,
  }) {
    return SyncSnapshot(
      rttMicros: rttMicros ?? this.rttMicros,
      clockOffsetMicros: clockOffsetMicros ?? this.clockOffsetMicros,
      driftMicros: driftMicros ?? this.driftMicros,
      quality: quality ?? this.quality,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static SyncQuality qualityForDrift(int driftMicros) {
    final absDrift = driftMicros.abs();
    if (absDrift < 10000) return SyncQuality.excellent;
    if (absDrift < 25000) return SyncQuality.good;
    return SyncQuality.poor;
  }
}
