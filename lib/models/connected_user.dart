import 'app_mode.dart';

class ConnectedUser {
  ConnectedUser({
    required this.endpointId,
    required this.name,
    this.quality = SyncQuality.unknown,
    this.rttMicros = 0,
    this.clockOffsetMicros = 0,
    this.driftMicros = 0,
    DateTime? connectedAt,
    DateTime? lastSeenAt,
  }) : connectedAt = connectedAt ?? DateTime.now(),
       lastSeenAt = lastSeenAt ?? DateTime.now();

  final String endpointId;
  final String name;
  final SyncQuality quality;
  final int rttMicros;
  final int clockOffsetMicros;
  final int driftMicros;
  final DateTime connectedAt;
  final DateTime lastSeenAt;

  ConnectedUser copyWith({
    String? endpointId,
    String? name,
    SyncQuality? quality,
    int? rttMicros,
    int? clockOffsetMicros,
    int? driftMicros,
    DateTime? connectedAt,
    DateTime? lastSeenAt,
  }) {
    return ConnectedUser(
      endpointId: endpointId ?? this.endpointId,
      name: name ?? this.name,
      quality: quality ?? this.quality,
      rttMicros: rttMicros ?? this.rttMicros,
      clockOffsetMicros: clockOffsetMicros ?? this.clockOffsetMicros,
      driftMicros: driftMicros ?? this.driftMicros,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
