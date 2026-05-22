import '../../models/app_mode.dart';
import '../../models/protocol.dart';
import '../../models/room_config.dart';
import '../../services/nearby_room_service.dart';
import '../../services/native_sync_service.dart';
import 'sync_engine.dart';

class StarSyncEngine extends BaseSyncEngine {
  StarSyncEngine({
    required NearbyRoomService nearby,
    required NativeSyncService clock,
    required String deviceName,
  }) : _nearby = nearby,
       _clock = clock,
       _deviceName = deviceName,
       super(SyncMode.star);

  final NearbyRoomService _nearby;
  final NativeSyncService _clock;
  final String _deviceName;
  RoomConfig? _config;

  @override
  int get maxSupportedClients => 45;

  @override
  bool get supportsFlash => true;

  @override
  Future<void> initAsHost(RoomConfig config) async {
    _config = config;
    await _nearby.startHost(
      roomId: '',
      password: '',
      displayName: _deviceName,
      mode: SyncMode.star,
      hopCount: 0,
      maxClients: maxSupportedClients,
    );
    emitQuality(SyncQuality.excellent);
  }

  @override
  Future<void> initAsClient(String joinCode) async {
    emitQuality(SyncQuality.unknown);
  }

  @override
  Future<void> broadcastStart(
    int startAtEpochMs,
    int bpm,
    String audioPath,
  ) async {
    final hostNowMicros = await _clock.nowMicros();
    final startAtHostMicros =
        hostNowMicros + Duration(milliseconds: startAtEpochMs).inMicroseconds;
    await _nearby.broadcastJson(
      _nearby.connectedEndpointIds,
      wireMessage(ProtocolType.play, {
        'startAtHostMicros': startAtHostMicros,
        'positionMicros': 0,
        'fileName': audioPath.split(RegExp(r'[\\/]')).last,
        'bpm': bpm,
        'mode': (_config?.mode ?? SyncMode.star).name,
      }),
    );
  }
}
