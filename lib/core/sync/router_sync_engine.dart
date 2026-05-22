import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../models/app_mode.dart';
import '../../models/room_config.dart';
import 'sync_engine.dart';

class RouterSyncEngine extends BaseSyncEngine {
  RouterSyncEngine() : super(SyncMode.router);

  HttpServer? _server;
  RawDatagramSocket? _multicastSocket;
  Timer? _heartbeatTimer;
  RoomConfig? _config;
  int? _startAtEpochMs;
  int _bpm = 120;
  String? _audioPath;

  @override
  int get maxSupportedClients => 5000;

  @override
  bool get supportsFlash => true;

  @override
  Future<void> initAsHost(RoomConfig config) async {
    _config = config;
    _server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      config.routerPort,
      shared: true,
    );
    unawaited(_serve());
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
    _startAtEpochMs = startAtEpochMs;
    _bpm = bpm;
    _audioPath = audioPath;
    _multicastSocket ??= await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
      reusePort: true,
    );
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startAtEpochMs;
      final heartbeat = utf8.encode('HEARTBEAT:${elapsed.clamp(0, 1 << 31)}');
      _multicastSocket?.send(
        heartbeat,
        InternetAddress('239.255.255.250'),
        8888,
      );
    });
  }

  Future<void> _serve() async {
    final server = _server;
    if (server == null) return;
    await for (final request in server) {
      if (request.uri.path == '/sync.json') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'startAtEpochMs': _startAtEpochMs,
            'serverTimeMs': DateTime.now().millisecondsSinceEpoch,
            'bpm': _bpm,
          }),
        );
        await request.response.close();
        continue;
      }
      if (request.uri.path == '/audio.mp3' && _audioPath != null) {
        request.response.headers.contentType = ContentType('audio', 'mpeg');
        await File(_audioPath!).openRead().pipe(request.response);
        continue;
      }
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }

  @override
  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _multicastSocket?.close();
    await _server?.close(force: true);
    await super.dispose();
  }

  String setupInstructions() {
    final config = _config;
    final ssid = config?.routerSsid ?? 'CrowdSync_5G';
    final ip = config?.routerHostIp ?? '192.168.1.100';
    final port = config?.routerPort ?? 8080;
    return "Connect this phone + all guests to WiFi: $ssid. Host sync endpoint: http://$ip:$port/sync.json";
  }
}
