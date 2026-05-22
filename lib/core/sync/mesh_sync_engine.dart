import '../../models/app_mode.dart';
import '../../models/protocol.dart';
import '../../models/room_config.dart';
import '../../services/nearby_room_service.dart';
import '../../services/native_sync_service.dart';
import 'sync_engine.dart';

class MeshSyncEngine extends BaseSyncEngine {
  MeshSyncEngine({
    required NearbyRoomService nearby,
    required NativeSyncService clock,
    required String deviceName,
  }) : _nearby = nearby,
       _clock = clock,
       _deviceName = deviceName,
       super(SyncMode.mesh);

  final NearbyRoomService _nearby;
  final NativeSyncService _clock;
  final String _deviceName;
  RoomConfig? _config;
  int hopCount = 0;

  @override
  int get maxSupportedClients => 729;

  @override
  bool get supportsFlash => hopCount <= 4;

  @override
  Future<void> initAsHost(RoomConfig config) async {
    _config = config;
    hopCount = 0;
    await _nearby.startHost(
      roomId: '',
      password: '',
      displayName: _deviceName,
      mode: SyncMode.mesh,
      hopCount: hopCount,
      maxClients: config.meshMaxChildren,
    );
    emitQuality(SyncQuality.good);
  }

  @override
  Future<void> initAsClient(String joinCode) async {
    emitQuality(hopCount <= 4 ? SyncQuality.good : SyncQuality.poor);
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
        'mode': (_config?.mode ?? SyncMode.mesh).name,
        'hopCount': hopCount + 1,
      }),
    );
  }
}
