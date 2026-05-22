import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/mesh_sync_engine.dart';
import '../core/sync/router_sync_engine.dart';
import '../core/sync/star_sync_engine.dart';
import '../services/audio_service.dart';
import '../services/nearby_room_service.dart';
import '../services/native_sync_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import 'app_controller.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final audioServiceProvider = Provider<CrowdAudioService>((ref) {
  final service = CrowdAudioService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final nearbyRoomServiceProvider = Provider<NearbyRoomService>((ref) {
  final service = NearbyRoomService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final nativeSyncServiceProvider = Provider<NativeSyncService>((ref) {
  return NativeSyncService();
});

final starSyncEngineProvider = Provider<StarSyncEngine>((ref) {
  return StarSyncEngine(
    nearby: ref.read(nearbyRoomServiceProvider),
    clock: ref.read(nativeSyncServiceProvider),
    deviceName: ref.read(storageServiceProvider).deviceName,
  );
});

final meshSyncEngineProvider = Provider<MeshSyncEngine>((ref) {
  return MeshSyncEngine(
    nearby: ref.read(nearbyRoomServiceProvider),
    clock: ref.read(nativeSyncServiceProvider),
    deviceName: ref.read(storageServiceProvider).deviceName,
  );
});

final routerSyncEngineProvider = Provider<RouterSyncEngine>((ref) {
  final engine = RouterSyncEngine();
  ref.onDispose(() => unawaited(engine.dispose()));
  return engine;
});

final appControllerProvider = NotifierProvider<AppController, CrowdSyncState>(
  AppController.new,
);
