import 'dart:async';

import '../../models/app_mode.dart';
import '../../models/room_config.dart';

abstract class SyncEngine {
  Future<void> initAsHost(RoomConfig config);

  Future<void> initAsClient(String joinCode);

  Future<void> broadcastStart(int startAtEpochMs, int bpm, String audioPath);

  Stream<SyncQuality> get qualityStream;

  int get maxSupportedClients;

  bool get supportsFlash;

  SyncMode get mode;

  Future<void> dispose() async {}
}

class SyncStartCommand {
  const SyncStartCommand({
    required this.startAtEpochMs,
    required this.bpm,
    required this.audioPath,
    this.hopCount = 0,
  });

  final int startAtEpochMs;
  final int bpm;
  final String audioPath;
  final int hopCount;

  Map<String, dynamic> toJson() => {
    'cmd': 'START',
    'startAtEpochMs': startAtEpochMs,
    'bpm': bpm,
    'audioPath': audioPath,
    'hopCount': hopCount,
  };
}

abstract class BaseSyncEngine implements SyncEngine {
  BaseSyncEngine(this.mode);

  final StreamController<SyncQuality> _qualityController =
      StreamController<SyncQuality>.broadcast();

  @override
  final SyncMode mode;

  @override
  Stream<SyncQuality> get qualityStream => _qualityController.stream;

  void emitQuality(SyncQuality quality) {
    if (!_qualityController.isClosed) {
      _qualityController.add(quality);
    }
  }

  @override
  Future<void> dispose() async {
    await _qualityController.close();
  }
}
