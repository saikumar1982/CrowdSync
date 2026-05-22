import 'dart:convert';

import '../core/app_constants.dart';
import 'app_mode.dart';
import 'room_config.dart';

class RoomInfo {
  const RoomInfo({
    required this.roomId,
    required this.password,
    required this.hostName,
    this.config = const RoomConfig(mode: SyncMode.star, expectedCrowdSize: 40),
    this.hopCount = 0,
  });

  final String roomId;
  final String password;
  final String hostName;
  final RoomConfig config;
  final int hopCount;

  SyncMode get mode => config.mode;

  String get qrPayload => jsonEncode({
    'app': AppConstants.appName,
    'v': AppConstants.protocolVersion,
    'roomId': roomId,
    'password': password,
    'serviceId': AppConstants.serviceId,
    'hostName': hostName,
    'config': config.toJson(),
    'hopCount': hopCount,
  });

  RoomInfo copyWith({
    String? roomId,
    String? password,
    String? hostName,
    RoomConfig? config,
    int? hopCount,
  }) {
    return RoomInfo(
      roomId: roomId ?? this.roomId,
      password: password ?? this.password,
      hostName: hostName ?? this.hostName,
      config: config ?? this.config,
      hopCount: hopCount ?? this.hopCount,
    );
  }

  static RoomInfo? fromQrPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['app'] != AppConstants.appName) return null;
      final rawConfig = decoded['config'];
      return RoomInfo(
        roomId: decoded['roomId'] as String,
        password: decoded['password'] as String,
        hostName: decoded['hostName'] as String? ?? 'Host',
        config: rawConfig is Map<String, dynamic>
            ? RoomConfig.fromJson(rawConfig)
            : const RoomConfig(mode: SyncMode.star, expectedCrowdSize: 40),
        hopCount: (decoded['hopCount'] as num?)?.round() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
