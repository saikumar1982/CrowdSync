import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_constants.dart';
import '../models/app_mode.dart';
import '../models/connected_user.dart';
import '../models/network_event.dart';
import '../models/protocol.dart';
import '../models/room_config.dart';
import '../models/room_info.dart';
import '../models/sync_snapshot.dart';
import '../services/audio_service.dart';
import '../services/nearby_room_service.dart';
import '../services/native_sync_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

class CrowdSyncState {
  const CrowdSyncState({
    required this.route,
    required this.mode,
    required this.deviceName,
    required this.permissionsReady,
    required this.busy,
    required this.room,
    required this.users,
    required this.hostEndpointId,
    required this.playbackPhase,
    required this.trackPath,
    required this.trackName,
    required this.position,
    required this.duration,
    required this.sync,
    required this.flashlightMode,
    required this.localFlashlightEnabled,
    required this.globalLatencyOffsetMs,
    required this.calibrationOffsetMs,
    required this.selectedRoomSize,
    required this.forceSyncMode,
    required this.activeSyncMode,
    required this.hopCount,
    required this.modeWarning,
    required this.statusText,
    required this.errorText,
  });

  final AppRoute route;
  final AppMode mode;
  final String deviceName;
  final bool permissionsReady;
  final bool busy;
  final RoomInfo? room;
  final Map<String, ConnectedUser> users;
  final String? hostEndpointId;
  final PlaybackPhase playbackPhase;
  final String? trackPath;
  final String? trackName;
  final Duration position;
  final Duration duration;
  final SyncSnapshot sync;
  final FlashlightMode flashlightMode;
  final bool localFlashlightEnabled;
  final int globalLatencyOffsetMs;
  final int calibrationOffsetMs;
  final RoomSizePreset selectedRoomSize;
  final ForceSyncMode forceSyncMode;
  final SyncMode activeSyncMode;
  final int hopCount;
  final String? modeWarning;
  final String statusText;
  final String? errorText;

  bool get isHost => mode == AppMode.host;

  bool get isClient => mode == AppMode.client;

  bool get hasTrack => trackPath != null;

  bool get isPlaying => playbackPhase == PlaybackPhase.playing;

  factory CrowdSyncState.initial() {
    return const CrowdSyncState(
      route: AppRoute.splash,
      mode: AppMode.idle,
      deviceName: 'CrowdSync',
      permissionsReady: false,
      busy: false,
      room: null,
      users: {},
      hostEndpointId: null,
      playbackPhase: PlaybackPhase.idle,
      trackPath: null,
      trackName: null,
      position: Duration.zero,
      duration: Duration.zero,
      sync: SyncSnapshot(),
      flashlightMode: FlashlightMode.off,
      localFlashlightEnabled: true,
      globalLatencyOffsetMs: 0,
      calibrationOffsetMs: 0,
      selectedRoomSize: RoomSizePreset.small,
      forceSyncMode: ForceSyncMode.auto,
      activeSyncMode: SyncMode.star,
      hopCount: 0,
      modeWarning: null,
      statusText: 'Starting CrowdSync',
      errorText: null,
    );
  }

  CrowdSyncState copyWith({
    AppRoute? route,
    AppMode? mode,
    String? deviceName,
    bool? permissionsReady,
    bool? busy,
    RoomInfo? room,
    bool clearRoom = false,
    Map<String, ConnectedUser>? users,
    String? hostEndpointId,
    bool clearHostEndpointId = false,
    PlaybackPhase? playbackPhase,
    String? trackPath,
    String? trackName,
    bool clearTrack = false,
    Duration? position,
    Duration? duration,
    SyncSnapshot? sync,
    FlashlightMode? flashlightMode,
    bool? localFlashlightEnabled,
    int? globalLatencyOffsetMs,
    int? calibrationOffsetMs,
    RoomSizePreset? selectedRoomSize,
    ForceSyncMode? forceSyncMode,
    SyncMode? activeSyncMode,
    int? hopCount,
    String? modeWarning,
    bool clearModeWarning = false,
    String? statusText,
    String? errorText,
    bool clearError = false,
  }) {
    return CrowdSyncState(
      route: route ?? this.route,
      mode: mode ?? this.mode,
      deviceName: deviceName ?? this.deviceName,
      permissionsReady: permissionsReady ?? this.permissionsReady,
      busy: busy ?? this.busy,
      room: clearRoom ? null : room ?? this.room,
      users: users ?? this.users,
      hostEndpointId: clearHostEndpointId
          ? null
          : hostEndpointId ?? this.hostEndpointId,
      playbackPhase: playbackPhase ?? this.playbackPhase,
      trackPath: clearTrack ? null : trackPath ?? this.trackPath,
      trackName: clearTrack ? null : trackName ?? this.trackName,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      sync: sync ?? this.sync,
      flashlightMode: flashlightMode ?? this.flashlightMode,
      localFlashlightEnabled:
          localFlashlightEnabled ?? this.localFlashlightEnabled,
      globalLatencyOffsetMs:
          globalLatencyOffsetMs ?? this.globalLatencyOffsetMs,
      calibrationOffsetMs: calibrationOffsetMs ?? this.calibrationOffsetMs,
      selectedRoomSize: selectedRoomSize ?? this.selectedRoomSize,
      forceSyncMode: forceSyncMode ?? this.forceSyncMode,
      activeSyncMode: activeSyncMode ?? this.activeSyncMode,
      hopCount: hopCount ?? this.hopCount,
      modeWarning: clearModeWarning ? null : modeWarning ?? this.modeWarning,
      statusText: statusText ?? this.statusText,
      errorText: clearError ? null : errorText ?? this.errorText,
    );
  }
}

class AppController extends Notifier<CrowdSyncState> {
  late final StorageService _storage;
  late final PermissionService _permissions;
  late final CrowdAudioService _audio;
  late final NearbyRoomService _network;
  late final NativeSyncService _nativeSync;

  final Map<int, _IncomingTrack> _incomingTracks = {};
  Map<String, dynamic>? _latestPlaybackMessage;
  StreamSubscription<NetworkEvent>? _networkSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<AudioInterruptionNotice>? _interruptionSub;
  Timer? _clockTimer;
  Timer? _playbackTimer;
  Timer? _joinTimeoutTimer;
  bool _bootstrapped = false;

  @override
  CrowdSyncState build() {
    _storage = ref.read(storageServiceProvider);
    _permissions = ref.read(permissionServiceProvider);
    _audio = ref.read(audioServiceProvider);
    _network = ref.read(nearbyRoomServiceProvider);
    _nativeSync = ref.read(nativeSyncServiceProvider);
    ref.onDispose(() => unawaited(_disposeController()));

    if (!_bootstrapped) {
      _bootstrapped = true;
      Future.microtask(_bootstrap);
    }

    return CrowdSyncState.initial();
  }

  Future<void> _bootstrap() async {
    try {
      await _storage.init();
      await _audio.init();
      _networkSub = _network.events.listen(_handleNetworkEvent);
      _positionSub = _audio.positionStream.listen((position) {
        state = state.copyWith(position: position);
      });
      _durationSub = _audio.durationStream.listen((duration) {
        state = state.copyWith(duration: duration ?? Duration.zero);
      });
      _interruptionSub = _audio.interruptions.listen(_handleAudioInterruption);
      final ready = await _permissions.hasNearbyBasics();
      state = state.copyWith(
        deviceName: _storage.deviceName,
        permissionsReady: ready,
        calibrationOffsetMs: _storage.calibrationOffsetMs,
        localFlashlightEnabled: _storage.flashlightOptIn,
        selectedRoomSize: _storage.roomSizePreset,
        forceSyncMode: _storage.forceSyncMode,
        activeSyncMode:
            _storage.forceSyncMode.forcedMode ??
            RoomConfig.autoFor(
              _storage.roomSizePreset,
              _storage.forceSyncMode,
            ).mode,
        statusText: 'Ready for local audio rooms',
      );
    } on Object catch (error) {
      _setError(error);
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (state.route == AppRoute.splash) {
      state = state.copyWith(route: AppRoute.home, clearError: true);
    }
  }

  Future<void> createRoom() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final permissions = await _permissions.requestNearbyPermissions();
      if (!permissions.granted) {
        state = state.copyWith(busy: false, permissionsReady: false);
        _setError(permissions.message ?? 'Nearby permissions are required.');
        return;
      }
      var config = RoomConfig.autoFor(
        state.selectedRoomSize,
        state.forceSyncMode,
      );
      String? modeWarning;
      if (config.mode == SyncMode.router && !await _permissions.hasWifi()) {
        config = config.copyWith(mode: SyncMode.mesh, expectedCrowdSize: 150);
        modeWarning = 'Router mode needs Wi-Fi. Downgraded to Festival Mesh.';
      }
      await _audio.setMode(config.mode);
      await _nativeSync.acquirePerformanceLocks();
      final room = RoomInfo(
        roomId: AppConstants.generateRoomId(),
        password: AppConstants.generatePassword(),
        hostName: state.deviceName,
        config: config,
      );
      await _network.startHost(
        roomId: room.roomId,
        password: room.password,
        displayName: state.deviceName,
        mode: config.mode,
        hopCount: 0,
        maxClients: config.mode == SyncMode.star
            ? config.maxSupportedClients
            : config.mode == SyncMode.mesh
            ? config.meshMaxChildren
            : null,
      );
      _startHostTimers();
      state = state.copyWith(
        route: AppRoute.hostDashboard,
        mode: AppMode.host,
        room: room,
        permissionsReady: true,
        busy: false,
        activeSyncMode: config.mode,
        hopCount: 0,
        modeWarning: modeWarning,
        statusText: '${config.mode.label} room ${room.roomId} is live',
      );
    } on Object catch (error) {
      state = state.copyWith(busy: false);
      _setError(error);
    }
  }

  Future<void> joinRoom(
    String roomId,
    String password, {
    RoomConfig? config,
  }) async {
    final cleanRoom = roomId.trim();
    final cleanPassword = password.trim();
    if (cleanRoom.length != 6 || cleanPassword.isEmpty) {
      _setError('Enter the 6 digit room ID and password.');
      return;
    }

    state = state.copyWith(busy: true, clearError: true);
    try {
      final permissions = await _permissions.requestNearbyPermissions();
      if (!permissions.granted) {
        state = state.copyWith(busy: false, permissionsReady: false);
        _setError(permissions.message ?? 'Nearby permissions are required.');
        return;
      }
      final room = RoomInfo(
        roomId: cleanRoom,
        password: cleanPassword,
        hostName: 'Host',
        config:
            config ??
            RoomConfig(
              mode: state.forceSyncMode.forcedMode ?? state.activeSyncMode,
              expectedCrowdSize: state.selectedRoomSize.expectedCrowdSize,
            ),
      );
      await _audio.setMode(room.mode);
      await _nativeSync.acquirePerformanceLocks();
      await _network.joinRoom(
        roomId: cleanRoom,
        password: cleanPassword,
        displayName: state.deviceName,
        mode: room.mode,
      );
      state = state.copyWith(
        route: AppRoute.clientDashboard,
        mode: AppMode.client,
        room: room,
        permissionsReady: true,
        busy: false,
        activeSyncMode: room.mode,
        hopCount: room.hopCount,
        statusText: 'Searching for ${room.mode.label} room $cleanRoom',
      );
      _startJoinTimeout(cleanRoom);
    } on Object catch (error) {
      state = state.copyWith(busy: false);
      _setError(error);
    }
  }

  Future<void> joinFromQr(String payload) async {
    final room = RoomInfo.fromQrPayload(payload);
    if (room == null) {
      _setError('That QR code is not a CrowdSync room.');
      goHome();
      return;
    }
    await joinRoom(room.roomId, room.password, config: room.config);
  }

  Future<void> selectTrack() async {
    if (!state.isHost) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg'],
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null) {
        state = state.copyWith(busy: false);
        return;
      }
      final name = result!.files.single.name;
      await _audio.setFilePath(path);
      state = state.copyWith(
        trackPath: path,
        trackName: name,
        playbackPhase: PlaybackPhase.ready,
        busy: false,
        statusText: 'Track loaded: $name',
      );
      await _sendTrackToAllClients();
      await _broadcastPlaybackState();
    } on Object catch (error) {
      state = state.copyWith(busy: false);
      _setError(error);
    }
  }

  Future<void> togglePlay() async {
    if (!state.isHost || !state.hasTrack) return;
    if (state.isPlaying) {
      await pausePlayback();
    } else {
      await startPlayback();
    }
  }

  Future<void> startPlayback() async {
    if (!state.isHost || !state.hasTrack) return;
    final hostNow = await _nativeSync.nowMicros();
    final startBuffer = switch (state.activeSyncMode) {
      SyncMode.star => const Duration(milliseconds: 2000),
      SyncMode.mesh => const Duration(milliseconds: 3000),
      SyncMode.router => AppConstants.startBuffer,
    };
    final startAtHostMicros = hostNow + startBuffer.inMicroseconds;
    final position = _audio.position;
    await _audio.schedulePlayAfter(
      delay: AppConstants.startBuffer,
      position: position,
    );
    state = state.copyWith(
      playbackPhase: PlaybackPhase.playing,
      statusText: 'Playback starts on the next sync beat',
    );
    await _network.broadcastJson(
      state.users.keys,
      wireMessage(ProtocolType.play, {
        'startAtHostMicros': startAtHostMicros,
        'positionMicros': position.inMicroseconds,
        'durationMicros': state.duration.inMicroseconds,
        'fileName': state.trackName,
        'globalLatencyOffsetMs': state.globalLatencyOffsetMs,
        'mode': state.activeSyncMode.name,
        'hopCount': state.hopCount,
      }),
    );
  }

  Future<void> pausePlayback() async {
    if (!state.isHost) return;
    await _audio.pause();
    final hostSentMicros = await _nativeSync.nowMicros();
    final position = _audio.position;
    state = state.copyWith(
      playbackPhase: PlaybackPhase.paused,
      position: position,
      statusText: 'Playback paused',
    );
    await _network.broadcastJson(
      state.users.keys,
      wireMessage(ProtocolType.pause, {
        'positionMicros': position.inMicroseconds,
        'hostSentMicros': hostSentMicros,
      }),
    );
  }

  Future<void> seekBy(Duration delta) async {
    if (!state.isHost || !state.hasTrack) return;
    final duration = state.duration;
    final nextMicros = (_audio.position + delta).inMicroseconds.clamp(
      0,
      duration == Duration.zero ? 1 << 62 : duration.inMicroseconds,
    );
    await _audio.seek(Duration(microseconds: nextMicros));
    final hostSentMicros = await _nativeSync.nowMicros();
    state = state.copyWith(position: Duration(microseconds: nextMicros));
    await _network.broadcastJson(
      state.users.keys,
      wireMessage(ProtocolType.seek, {
        'positionMicros': nextMicros,
        'hostSentMicros': hostSentMicros,
        'playing': state.isPlaying,
        'globalLatencyOffsetMs': state.globalLatencyOffsetMs,
      }),
    );
  }

  Future<void> setGlobalLatencyOffset(double value) async {
    if (!state.isHost) return;
    state = state.copyWith(globalLatencyOffsetMs: value.round());
    await _broadcastPlaybackState();
  }

  Future<void> setFlashlightMode(FlashlightMode mode) async {
    if (!state.activeSyncMode.supportsFlashAtHop(state.hopCount) &&
        mode != FlashlightMode.off) {
      state = state.copyWith(
        flashlightMode: FlashlightMode.off,
        modeWarning: 'Audio only - too far from stage.',
      );
      await _nativeSync.stopFlashlight();
      return;
    }
    final hostStart = await _nativeSync.nowMicros() + 450000;
    state = state.copyWith(flashlightMode: mode);
    await _permissions.requestCameraForTorch();
    await _nativeSync.scheduleFlashlight(
      mode: mode,
      optIn: true,
      localStartMicros: hostStart,
    );
    if (state.isHost) {
      await _network.broadcastJson(
        state.users.keys,
        wireMessage(ProtocolType.flashlight, {
          'mode': mode.name,
          'hostStartMicros': hostStart,
          'beatMicros': 500000,
        }),
      );
    }
  }

  Future<void> setLocalFlashlightEnabled(bool enabled) async {
    await _storage.setFlashlightOptIn(enabled);
    state = state.copyWith(localFlashlightEnabled: enabled);
    if (!enabled) {
      await _nativeSync.stopFlashlight();
    }
  }

  Future<void> recalibrate(String choice) async {
    final offset = switch (choice) {
      'early' => state.calibrationOffsetMs - 15,
      'late' => state.calibrationOffsetMs + 15,
      _ => 0,
    };
    await _storage.setCalibrationOffsetMs(offset);
    state = state.copyWith(
      calibrationOffsetMs: offset,
      route: state.isHost ? AppRoute.hostDashboard : AppRoute.clientDashboard,
      statusText: 'Calibration offset set to ${offset}ms',
    );
    await requestResync();
  }

  Future<void> playCalibrationClick() async {
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> requestResync() async {
    if (state.isClient && state.hostEndpointId != null) {
      await _network.sendJson(
        state.hostEndpointId!,
        wireMessage(ProtocolType.syncRequest, {}),
      );
    } else if (state.isHost) {
      await _broadcastPlaybackState();
    }
  }

  Future<void> removeUser(String endpointId) async {
    if (!state.isHost) return;
    await _network.sendJson(
      endpointId,
      wireMessage(ProtocolType.remove, {'reason': 'Removed by host'}),
    );
    await _network.disconnect(endpointId);
    final users = Map<String, ConnectedUser>.from(state.users)
      ..remove(endpointId);
    state = state.copyWith(users: users);
  }

  Future<void> saveDeviceName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    await _storage.setDeviceName(clean);
    state = state.copyWith(deviceName: clean);
  }

  Future<void> setRoomSizePreset(RoomSizePreset preset) async {
    await _storage.setRoomSizePreset(preset);
    final config = RoomConfig.autoFor(preset, state.forceSyncMode);
    state = state.copyWith(
      selectedRoomSize: preset,
      activeSyncMode: config.mode,
      clearModeWarning: true,
      statusText: 'Mode set to ${config.mode.label}',
    );
  }

  Future<void> setForceSyncMode(ForceSyncMode mode) async {
    await _storage.setForceSyncMode(mode);
    final config = RoomConfig.autoFor(state.selectedRoomSize, mode);
    state = state.copyWith(
      forceSyncMode: mode,
      activeSyncMode: config.mode,
      clearModeWarning: true,
      statusText: 'Advanced mode: ${mode.label}',
    );
  }

  Future<void> leaveRoom() async {
    _stopHostTimers();
    _stopJoinTimeout();
    await _audio.pause();
    await _nativeSync.stopFlashlight();
    await _network.stop();
    await _nativeSync.resetClock();
    await _nativeSync.releasePerformanceLocks();
    _latestPlaybackMessage = null;
    _incomingTracks.clear();
    state = state.copyWith(
      route: AppRoute.home,
      mode: AppMode.idle,
      clearRoom: true,
      users: {},
      clearHostEndpointId: true,
      playbackPhase: PlaybackPhase.idle,
      flashlightMode: FlashlightMode.off,
      sync: const SyncSnapshot(),
      activeSyncMode: SyncMode.star,
      hopCount: 0,
      clearModeWarning: true,
      statusText: 'Ready for local audio rooms',
    );
  }

  void openScanner() => state = state.copyWith(route: AppRoute.qrScanner);

  void openCalibration() =>
      state = state.copyWith(route: AppRoute.calibration, clearError: true);

  void openSettings() =>
      state = state.copyWith(route: AppRoute.settings, clearError: true);

  void backToDashboard() {
    state = state.copyWith(
      route: state.isHost ? AppRoute.hostDashboard : AppRoute.clientDashboard,
      clearError: true,
    );
  }

  void goHome() {
    _stopJoinTimeout();
    state = state.copyWith(route: AppRoute.home, clearError: true);
  }

  void clearError() => state = state.copyWith(clearError: true);

  void handleLifecycle(AppLifecycleState lifecycle) {
    if (!state.isClient) return;
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.inactive) {
      unawaited(_audio.pause());
      state = state.copyWith(
        playbackPhase: PlaybackPhase.interrupted,
        statusText: 'Playback paused during interruption',
      );
      return;
    }
    if (lifecycle == AppLifecycleState.resumed) {
      state = state.copyWith(statusText: 'Rejoining host timeline');
      unawaited(requestResync());
    }
  }

  void _handleAudioInterruption(AudioInterruptionNotice notice) {
    if (!state.isClient) return;
    if (notice.kind == AudioInterruptionKind.began) {
      state = state.copyWith(
        playbackPhase: PlaybackPhase.interrupted,
        statusText: 'Audio focus interrupted',
      );
    } else {
      unawaited(requestResync());
    }
  }

  Future<void> _handleNetworkEvent(NetworkEvent event) async {
    switch (event.type) {
      case NetworkEventType.connected:
        _handleConnected(event);
      case NetworkEventType.disconnected:
        _handleDisconnected(event);
      case NetworkEventType.connectionRejected:
        _stopJoinTimeout();
        _setError('Connection rejected. Check the room password.');
      case NetworkEventType.message:
        await _handleMessage(event);
      case NetworkEventType.filePayload:
        _handleFilePayload(event);
      case NetworkEventType.fileTransferUpdate:
        await _handleFileTransferUpdate(event);
      case NetworkEventType.error:
        _stopJoinTimeout();
        _setError(event.error ?? 'Nearby connection failed.');
    }
  }

  void _handleConnected(NetworkEvent event) {
    _stopJoinTimeout();
    final endpointId = event.endpointId;
    if (endpointId == null) return;
    if (state.isHost) {
      final users = Map<String, ConnectedUser>.from(state.users);
      users[endpointId] = ConnectedUser(
        endpointId: endpointId,
        name: event.endpointName ?? 'Guest',
      );
      state = state.copyWith(users: users, statusText: 'Client connected');
      unawaited(_sendRoomSnapshot(endpointId));
      unawaited(_sendTrackToEndpoint(endpointId));
      unawaited(_sendClockSync(endpointId));
      return;
    }

    state = state.copyWith(
      hostEndpointId: endpointId,
      statusText: 'Connected to ${event.endpointName ?? 'host'}',
    );
    unawaited(requestResync());
  }

  void _handleDisconnected(NetworkEvent event) {
    final endpointId = event.endpointId;
    if (endpointId == null) return;
    if (state.isHost) {
      final users = Map<String, ConnectedUser>.from(state.users)
        ..remove(endpointId);
      state = state.copyWith(users: users, statusText: 'Client disconnected');
    } else if (endpointId == state.hostEndpointId) {
      state = state.copyWith(
        clearHostEndpointId: true,
        playbackPhase: PlaybackPhase.paused,
        sync: state.sync.copyWith(quality: SyncQuality.disconnected),
        statusText: 'Disconnected from host',
      );
      unawaited(_audio.pause());
    }
  }

  Future<void> _handleMessage(NetworkEvent event) async {
    final message = event.message;
    if (message == null) return;
    final type = message['type'] as String?;
    switch (type) {
      case ProtocolType.clockSync:
        await _handleClockSync(event.endpointId, message);
      case ProtocolType.clockAck:
        await _handleClockAck(event.endpointId, message);
      case ProtocolType.clockResult:
        await _handleClockResult(message);
      case ProtocolType.playbackState:
        await _applyPlaybackState(message);
      case ProtocolType.play:
        await _handlePlayCommand(message);
      case ProtocolType.pause:
        await _handlePauseCommand(message);
      case ProtocolType.seek:
        await _handleSeekCommand(message);
      case ProtocolType.syncRequest:
        if (event.endpointId != null) {
          await _sendPlaybackState(event.endpointId!);
        }
      case ProtocolType.fileMeta:
        await _handleFileMeta(message);
      case ProtocolType.flashlight:
        await _handleFlashlightCommand(message);
      case ProtocolType.remove:
        await leaveRoom();
      case ProtocolType.roomSnapshot:
        _handleRoomSnapshot(message);
    }
  }

  void _handleRoomSnapshot(Map<String, dynamic> message) {
    final mode = _syncModeFrom(message['mode']) ?? state.activeSyncMode;
    final hopCount = _asInt(message['hopCount']);
    final currentRoom = state.room;
    state = state.copyWith(
      room: currentRoom?.copyWith(
        config: currentRoom.config.copyWith(mode: mode),
        hopCount: hopCount,
      ),
      activeSyncMode: mode,
      hopCount: hopCount,
      statusText: 'Room snapshot received',
    );
    unawaited(_audio.setMode(mode));
  }

  Future<void> _handleClockSync(
    String? endpointId,
    Map<String, dynamic> message,
  ) async {
    if (!state.isClient || endpointId == null) return;
    final receiveMicros = await _nativeSync.nowMicros();
    final clientSendMicros = await _nativeSync.nowMicros();
    await _network.sendJson(
      endpointId,
      wireMessage(ProtocolType.clockAck, {
        'seq': message['seq'],
        'hostSendMicros': _asInt(message['hostSendMicros']),
        'clientReceiveMicros': receiveMicros,
        'clientSendMicros': clientSendMicros,
      }),
    );
  }

  Future<void> _handleClockAck(
    String? endpointId,
    Map<String, dynamic> message,
  ) async {
    if (!state.isHost || endpointId == null) return;
    final hostReceiveMicros = await _nativeSync.nowMicros();
    await _network.sendJson(
      endpointId,
      wireMessage(ProtocolType.clockResult, {
        'seq': message['seq'],
        'hostSendMicros': _asInt(message['hostSendMicros']),
        'clientReceiveMicros': _asInt(message['clientReceiveMicros']),
        'clientSendMicros': _asInt(message['clientSendMicros']),
        'hostReceiveMicros': hostReceiveMicros,
      }),
    );
  }

  Future<void> _handleClockResult(Map<String, dynamic> message) async {
    final estimate = await _nativeSync.updateClock(
      hostSendMicros: _asInt(message['hostSendMicros']),
      clientReceiveMicros: _asInt(message['clientReceiveMicros']),
      clientSendMicros: _asInt(message['clientSendMicros']),
      hostReceiveMicros: _asInt(message['hostReceiveMicros']),
    );
    state = state.copyWith(
      sync: state.sync.copyWith(
        rttMicros: estimate.roundTripMicros,
        clockOffsetMicros: estimate.clientMinusHostMicros,
        updatedAt: DateTime.now(),
      ),
      statusText:
          'Clock sync ${(estimate.roundTripMicros / 1000).round()}ms RTT',
    );
  }

  Future<void> _handlePlayCommand(Map<String, dynamic> message) async {
    _latestPlaybackMessage = message;
    if (!state.hasTrack) {
      state = state.copyWith(
        playbackPhase: PlaybackPhase.loading,
        statusText: 'Waiting for host audio file',
      );
      return;
    }

    final basePosition = Duration(
      microseconds: _asInt(message['positionMicros']),
    );
    final mode = _syncModeFrom(message['mode']) ?? state.activeSyncMode;
    final hopCount = _asInt(message['hopCount'], fallback: state.hopCount);
    final hostStart = _asInt(message['startAtHostMicros']);
    final globalOffsetMs = _asInt(message['globalLatencyOffsetMs']);
    final localStart =
        await _nativeSync.hostToLocalMicros(hostStart) +
        ((globalOffsetMs - state.calibrationOffsetMs) * 1000);
    final now = await _nativeSync.nowMicros();
    final elapsedPastStart = max(0, now - localStart);
    await _audio.schedulePlayAfter(
      delay: Duration(microseconds: max(0, localStart - now)),
      position: basePosition + Duration(microseconds: elapsedPastStart),
    );
    state = state.copyWith(
      playbackPhase: PlaybackPhase.playing,
      globalLatencyOffsetMs: globalOffsetMs,
      activeSyncMode: mode,
      hopCount: hopCount,
      statusText: 'Playback synchronized',
    );
    if (mode == SyncMode.mesh && hopCount > 4) {
      await _nativeSync.stopFlashlight();
      state = state.copyWith(modeWarning: 'Audio only - too far from stage.');
    }
  }

  Future<void> _handlePauseCommand(Map<String, dynamic> message) async {
    final position = Duration(microseconds: _asInt(message['positionMicros']));
    await _audio.pause();
    if (state.hasTrack) {
      await _audio.seek(_clampToDuration(position));
    }
    state = state.copyWith(
      playbackPhase: PlaybackPhase.paused,
      position: position,
      statusText: 'Paused by host',
    );
  }

  Future<void> _handleSeekCommand(Map<String, dynamic> message) async {
    await _applyPlaybackState({
      ...message,
      'type': ProtocolType.playbackState,
      'durationMicros': state.duration.inMicroseconds,
    }, force: true);
  }

  Future<void> _applyPlaybackState(
    Map<String, dynamic> message, {
    bool force = false,
  }) async {
    _latestPlaybackMessage = message;
    final playing = message['playing'] == true;
    final globalOffsetMs = _asInt(message['globalLatencyOffsetMs']);
    final mode = _syncModeFrom(message['mode']) ?? state.activeSyncMode;
    final hopCount = _asInt(message['hopCount'], fallback: state.hopCount);
    state = state.copyWith(
      globalLatencyOffsetMs: globalOffsetMs,
      activeSyncMode: mode,
      hopCount: hopCount,
    );
    await _audio.setMode(mode);

    if (!state.hasTrack) {
      state = state.copyWith(
        playbackPhase: PlaybackPhase.loading,
        statusText: 'Waiting for host audio file',
      );
      return;
    }

    final hostSentMicros = _asInt(message['hostSentMicros']);
    final basePositionMicros = _asInt(message['positionMicros']);
    final localHostSentMicros = await _nativeSync.hostToLocalMicros(
      hostSentMicros,
    );
    final localNowMicros = await _nativeSync.nowMicros();
    final elapsedMicros = playing
        ? max(0, localNowMicros - localHostSentMicros)
        : 0;
    final calibrationAdvanceMicros =
        (state.calibrationOffsetMs - globalOffsetMs) * 1000;
    final target = _clampToDuration(
      Duration(
        microseconds: max(
          0,
          basePositionMicros + elapsedMicros + calibrationAdvanceMicros,
        ),
      ),
    );
    final threshold = force
        ? Duration.zero
        : target.inMicroseconds - _audio.position.inMicroseconds >
              AppConstants.hardCorrectionThreshold.inMicroseconds
        ? AppConstants.hardCorrectionThreshold
        : AppConstants.correctionThreshold;
    final driftMicros = await _audio.correctTo(target, threshold);
    if (playing && !_audio.isPlaying) {
      await _audio.playNow();
    }
    if (!playing && _audio.isPlaying) {
      await _audio.pause();
    }

    state = state.copyWith(
      playbackPhase: playing ? PlaybackPhase.playing : PlaybackPhase.paused,
      sync: state.sync.copyWith(
        driftMicros: driftMicros,
        quality: SyncSnapshot.qualityForDrift(driftMicros),
        updatedAt: DateTime.now(),
      ),
      statusText:
          'Drift ${Duration(microseconds: driftMicros).inMilliseconds}ms',
    );
  }

  void _handleFilePayload(NetworkEvent event) {
    final id = event.payloadId;
    if (id == null) return;
    final current = _incomingTracks[id] ?? _IncomingTrack(payloadId: id);
    _incomingTracks[id] = current.copyWith(
      sourceUri: event.fileUri,
      sourcePath: event.filePath,
    );
  }

  Future<void> _handleFileTransferUpdate(NetworkEvent event) async {
    final id = event.payloadId;
    if (id == null) return;
    final current = _incomingTracks[id] ?? _IncomingTrack(payloadId: id);
    _incomingTracks[id] = current.copyWith(
      transferStatus: event.transferStatus,
    );
    await _tryMaterializeIncoming(id);
  }

  Future<void> _handleFileMeta(Map<String, dynamic> message) async {
    final id = _asInt(message['payloadId']);
    if (id == 0 && message['payloadId'] == null) return;
    final current = _incomingTracks[id] ?? _IncomingTrack(payloadId: id);
    _incomingTracks[id] = current.copyWith(
      fileName: message['fileName'] as String? ?? 'crowdsync-track.mp3',
    );
    await _tryMaterializeIncoming(id);
  }

  Future<void> _tryMaterializeIncoming(int payloadId) async {
    final track = _incomingTracks[payloadId];
    if (track == null ||
        track.materialized ||
        track.fileName == null ||
        track.transferStatus != 'SUCCESS' ||
        (track.sourceUri == null && track.sourcePath == null)) {
      return;
    }

    try {
      final path = track.sourceUri != null
          ? await _network.copyIncomingFile(
              sourceUri: track.sourceUri!,
              fileName: track.fileName!,
            )
          : await _network.copyIncomingPath(
              filePath: track.sourcePath!,
              fileName: track.fileName!,
            );
      _incomingTracks[payloadId] = track.copyWith(materialized: true);
      await _audio.setFilePath(path);
      state = state.copyWith(
        trackPath: path,
        trackName: track.fileName,
        playbackPhase: PlaybackPhase.ready,
        statusText: 'Received ${track.fileName}',
      );
      final latest = _latestPlaybackMessage;
      if (latest != null) {
        await _applyPlaybackState(latest, force: true);
      }
    } on Object catch (error) {
      _setError(error);
    }
  }

  Future<void> _handleFlashlightCommand(Map<String, dynamic> message) async {
    final modeName = message['mode'] as String? ?? FlashlightMode.off.name;
    final mode = FlashlightMode.values.firstWhere(
      (value) => value.name == modeName,
      orElse: () => FlashlightMode.off,
    );
    final hostStart = _asInt(message['hostStartMicros']);
    await _permissions.requestCameraForTorch();
    final localStartMicros = await _nativeSync.hostToLocalMicros(hostStart);
    await _nativeSync.scheduleFlashlight(
      mode: mode,
      optIn: state.localFlashlightEnabled,
      localStartMicros: localStartMicros,
      beatMicros: _asInt(message['beatMicros'], fallback: 500000),
    );
    state = state.copyWith(flashlightMode: mode);
  }

  Future<void> _sendTrackToAllClients() async {
    for (final endpointId in state.users.keys) {
      await _sendTrackToEndpoint(endpointId);
    }
  }

  Future<void> _sendTrackToEndpoint(String endpointId) async {
    final path = state.trackPath;
    if (path == null) return;
    final fileName = state.trackName ?? _basename(path);
    final payloadId = await _network.sendFile(endpointId, path);
    await _network.sendJson(
      endpointId,
      wireMessage(ProtocolType.fileMeta, {
        'payloadId': payloadId,
        'fileName': fileName,
        'sizeBytes': await File(path).length(),
      }),
    );
  }

  Future<void> _sendRoomSnapshot(String endpointId) {
    return _network.sendJson(
      endpointId,
      wireMessage(ProtocolType.roomSnapshot, {
        'roomId': state.room?.roomId,
        'trackName': state.trackName,
        'playing': state.isPlaying,
        'globalLatencyOffsetMs': state.globalLatencyOffsetMs,
        'mode': state.activeSyncMode.name,
        'hopCount': state.hopCount,
      }),
    );
  }

  Future<void> _sendClockSync(String endpointId) async {
    final hostSendMicros = await _nativeSync.nowMicros();
    return _network.sendJson(
      endpointId,
      wireMessage(ProtocolType.clockSync, {
        'seq': hostSendMicros,
        'hostSendMicros': hostSendMicros,
      }),
    );
  }

  Future<void> _broadcastClockSync() async {
    if (!state.isHost || state.users.isEmpty) return;
    final hostSend = await _nativeSync.nowMicros();
    await _network.broadcastJson(
      state.users.keys,
      wireMessage(ProtocolType.clockSync, {
        'seq': hostSend,
        'hostSendMicros': hostSend,
      }),
    );
  }

  Future<void> _broadcastPlaybackState() async {
    if (!state.isHost || state.users.isEmpty) return;
    await _network.broadcastJson(
      state.users.keys,
      await _playbackStateMessage(),
    );
  }

  Future<void> _sendPlaybackState(String endpointId) async {
    return _network.sendJson(endpointId, await _playbackStateMessage());
  }

  Future<Map<String, dynamic>> _playbackStateMessage() async {
    final hostSentMicros = await _nativeSync.nowMicros();
    return wireMessage(ProtocolType.playbackState, {
      'playing':
          _audio.isPlaying || state.playbackPhase == PlaybackPhase.playing,
      'positionMicros': _audio.position.inMicroseconds,
      'durationMicros': state.duration.inMicroseconds,
      'hostSentMicros': hostSentMicros,
      'fileName': state.trackName,
      'globalLatencyOffsetMs': state.globalLatencyOffsetMs,
      'mode': state.activeSyncMode.name,
      'hopCount': state.hopCount,
    });
  }

  void _startHostTimers() {
    _stopHostTimers();
    _clockTimer = Timer.periodic(
      AppConstants.clockSyncInterval,
      (_) => unawaited(_broadcastClockSync()),
    );
    _playbackTimer = Timer.periodic(
      AppConstants.playbackBroadcastInterval,
      (_) => unawaited(_broadcastPlaybackState()),
    );
  }

  void _stopHostTimers() {
    _clockTimer?.cancel();
    _playbackTimer?.cancel();
    _clockTimer = null;
    _playbackTimer = null;
  }

  void _startJoinTimeout(String roomId) {
    _stopJoinTimeout();
    _joinTimeoutTimer = Timer(const Duration(seconds: 25), () {
      unawaited(_handleJoinTimeout(roomId));
    });
  }

  void _stopJoinTimeout() {
    _joinTimeoutTimer?.cancel();
    _joinTimeoutTimer = null;
  }

  Future<void> _handleJoinTimeout(String roomId) async {
    _joinTimeoutTimer = null;
    if (!state.isClient ||
        state.hostEndpointId != null ||
        state.room?.roomId != roomId) {
      return;
    }

    await _network.stop();
    state = state.copyWith(
      route: AppRoute.home,
      mode: AppMode.idle,
      clearRoom: true,
      clearHostEndpointId: true,
      statusText: 'Ready for local audio rooms',
      errorText:
          'Could not find room $roomId. Keep the host room open on the other phone, keep both screens awake, and turn on Wi-Fi, Bluetooth, and Location on both phones.',
    );
  }

  Duration _clampToDuration(Duration value) {
    if (state.duration == Duration.zero) return value;
    return Duration(
      microseconds: value.inMicroseconds.clamp(
        0,
        state.duration.inMicroseconds,
      ),
    );
  }

  String _basename(String path) => path.split(RegExp(r'[\\/]')).last;

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  SyncMode? _syncModeFrom(Object? value) {
    if (value is! String) return null;
    return SyncMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => state.activeSyncMode,
    );
  }

  void _setError(Object error) {
    state = state.copyWith(errorText: _friendlyError(error), busy: false);
  }

  String _friendlyError(Object error) {
    if (error is PlatformException) {
      final message = error.message ?? error.details?.toString() ?? error.code;
      if (message.contains('MISSING_PERMISSION_ACCESS_WIFI_STATE')) {
        return 'Android is missing Wi-Fi state access for Nearby. Install the latest build on this phone, allow Nearby devices, then try again.';
      }
      if (message.contains('MISSING_PERMISSION') ||
          message.toLowerCase().contains('permission')) {
        return 'Nearby permission is missing: $message. Allow Nearby devices/Bluetooth and Location for CrowdSync, then try again.';
      }
      return message;
    }
    return error.toString();
  }

  Future<void> _disposeController() async {
    _stopHostTimers();
    _stopJoinTimeout();
    await _networkSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _interruptionSub?.cancel();
  }
}

class _IncomingTrack {
  const _IncomingTrack({
    required this.payloadId,
    this.fileName,
    this.sourceUri,
    this.sourcePath,
    this.transferStatus,
    this.materialized = false,
  });

  final int payloadId;
  final String? fileName;
  final String? sourceUri;
  final String? sourcePath;
  final String? transferStatus;
  final bool materialized;

  _IncomingTrack copyWith({
    String? fileName,
    String? sourceUri,
    String? sourcePath,
    String? transferStatus,
    bool? materialized,
  }) {
    return _IncomingTrack(
      payloadId: payloadId,
      fileName: fileName ?? this.fileName,
      sourceUri: sourceUri ?? this.sourceUri,
      sourcePath: sourcePath ?? this.sourcePath,
      transferStatus: transferStatus ?? this.transferStatus,
      materialized: materialized ?? this.materialized,
    );
  }
}
