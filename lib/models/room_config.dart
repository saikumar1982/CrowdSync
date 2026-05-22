import 'app_mode.dart';

class RoomConfig {
  const RoomConfig({
    required this.mode,
    required this.expectedCrowdSize,
    this.routerSsid = 'CrowdSync_5G',
    this.routerHostIp = '192.168.1.100',
    this.routerPort = 8080,
    this.meshMaxChildren = 3,
    this.meshMaxHops = 6,
  });

  final SyncMode mode;
  final int expectedCrowdSize;
  final String routerSsid;
  final String routerHostIp;
  final int routerPort;
  final int meshMaxChildren;
  final int meshMaxHops;

  bool get requiresRouter => mode == SyncMode.router;

  int get maxSupportedClients => mode.maxSupportedClients;

  RoomConfig copyWith({
    SyncMode? mode,
    int? expectedCrowdSize,
    String? routerSsid,
    String? routerHostIp,
    int? routerPort,
    int? meshMaxChildren,
    int? meshMaxHops,
  }) {
    return RoomConfig(
      mode: mode ?? this.mode,
      expectedCrowdSize: expectedCrowdSize ?? this.expectedCrowdSize,
      routerSsid: routerSsid ?? this.routerSsid,
      routerHostIp: routerHostIp ?? this.routerHostIp,
      routerPort: routerPort ?? this.routerPort,
      meshMaxChildren: meshMaxChildren ?? this.meshMaxChildren,
      meshMaxHops: meshMaxHops ?? this.meshMaxHops,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'expectedCrowdSize': expectedCrowdSize,
    'routerSsid': routerSsid,
    'routerHostIp': routerHostIp,
    'routerPort': routerPort,
    'meshMaxChildren': meshMaxChildren,
    'meshMaxHops': meshMaxHops,
  };

  factory RoomConfig.fromJson(Map<String, dynamic> json) {
    return RoomConfig(
      mode: SyncMode.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => SyncMode.star,
      ),
      expectedCrowdSize: _asInt(json['expectedCrowdSize'], fallback: 40),
      routerSsid: json['routerSsid'] as String? ?? 'CrowdSync_5G',
      routerHostIp: json['routerHostIp'] as String? ?? '192.168.1.100',
      routerPort: _asInt(json['routerPort'], fallback: 8080),
      meshMaxChildren: _asInt(json['meshMaxChildren'], fallback: 3),
      meshMaxHops: _asInt(json['meshMaxHops'], fallback: 6),
    );
  }

  static RoomConfig autoFor(RoomSizePreset size, ForceSyncMode forceMode) {
    final forced = forceMode.forcedMode;
    if (forced != null) {
      return RoomConfig(
        mode: forced,
        expectedCrowdSize: size.expectedCrowdSize,
      );
    }
    return RoomConfig(
      mode: switch (size) {
        RoomSizePreset.small => SyncMode.star,
        RoomSizePreset.medium => SyncMode.mesh,
        RoomSizePreset.large => SyncMode.router,
      },
      expectedCrowdSize: size.expectedCrowdSize,
    );
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
