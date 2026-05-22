import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';

import '../core/app_constants.dart';
import '../models/app_mode.dart';
import '../models/network_event.dart';

class NearbyRoomService {
  final Nearby _nearby = Nearby();
  final StreamController<NetworkEvent> _events =
      StreamController<NetworkEvent>.broadcast();
  final Map<String, String> _endpointNames = {};

  String? _roomId;
  String? _password;
  String? _hostEndpointId;
  SyncMode _mode = SyncMode.star;
  int _hopCount = 0;
  int? _maxClients;

  Stream<NetworkEvent> get events => _events.stream;

  String? get hostEndpointId => _hostEndpointId;

  Iterable<String> get connectedEndpointIds => _endpointNames.keys;

  Future<void> startHost({
    required String roomId,
    required String password,
    required String displayName,
    SyncMode mode = SyncMode.star,
    int hopCount = 0,
    int? maxClients,
  }) async {
    await stop();
    _roomId = roomId;
    _password = password;
    _mode = mode;
    _hopCount = hopCount;
    _maxClients = maxClients;
    final endpointName = _encodeHostName(roomId, displayName, mode, hopCount);

    final ok = await _nearby.startAdvertising(
      endpointName,
      _strategyFor(mode),
      serviceId: AppConstants.serviceId,
      onConnectionInitiated: _onHostConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
    if (!ok) {
      _events.add(
        const NetworkEvent(
          type: NetworkEventType.error,
          error: 'Unable to start Nearby advertising.',
        ),
      );
    }
  }

  Future<void> joinRoom({
    required String roomId,
    required String password,
    required String displayName,
    SyncMode mode = SyncMode.star,
  }) async {
    await stop();
    _roomId = roomId;
    _password = password;
    _mode = mode;

    final ok = await _nearby.startDiscovery(
      _encodeClientDiscoveryName(displayName),
      _strategyFor(mode),
      serviceId: AppConstants.serviceId,
      onEndpointFound: (endpointId, endpointName, serviceId) {
        final host = _decodeHostName(endpointName);
        if (host == null || host.roomId != roomId) return;
        _mode = host.mode;
        _hopCount = host.hopCount + 1;
        _endpointNames[endpointId] = host.hostName;
        _hostEndpointId = endpointId;
        unawaited(_nearby.stopDiscovery());
        unawaited(
          _nearby
              .requestConnection(
                _encodeJoinName(roomId, password, displayName),
                endpointId,
                onConnectionInitiated: _onClientConnectionInitiated,
                onConnectionResult: _onConnectionResult,
                onDisconnected: _onDisconnected,
              )
              .then((ok) {
                if (!ok) {
                  _events.add(
                    const NetworkEvent(
                      type: NetworkEventType.error,
                      error: 'Unable to request connection to the host.',
                    ),
                  );
                }
              })
              .catchError((Object error) {
                _events.add(
                  NetworkEvent(
                    type: NetworkEventType.error,
                    endpointId: endpointId,
                    endpointName: _endpointNames[endpointId],
                    error: error,
                  ),
                );
              }),
        );
      },
      onEndpointLost: (_) {},
    );
    if (!ok) {
      _events.add(
        const NetworkEvent(
          type: NetworkEventType.error,
          error: 'Unable to start Nearby discovery.',
        ),
      );
    }
  }

  Future<void> sendJson(String endpointId, Map<String, dynamic> message) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(message)));
    return _nearby.sendBytesPayload(endpointId, bytes);
  }

  Future<void> broadcastJson(
    Iterable<String> endpointIds,
    Map<String, dynamic> message,
  ) async {
    for (final id in endpointIds) {
      await sendJson(id, message);
    }
  }

  Future<int> sendFile(String endpointId, String filePath) {
    return _nearby.sendFilePayload(endpointId, filePath);
  }

  Future<String> copyIncomingFile({
    required String sourceUri,
    required String fileName,
  }) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final tracksDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}tracks',
    );
    if (!tracksDir.existsSync()) {
      tracksDir.createSync(recursive: true);
    }
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._ -]'), '_');
    final destination = '${tracksDir.path}${Platform.pathSeparator}$safeName';
    final ok = await _nearby.copyFileAndDeleteOriginal(sourceUri, destination);
    if (!ok) {
      throw StateError('Nearby could not copy the received file.');
    }
    return destination;
  }

  Future<String> copyIncomingPath({
    required String filePath,
    required String fileName,
  }) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final tracksDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}tracks',
    );
    if (!tracksDir.existsSync()) {
      tracksDir.createSync(recursive: true);
    }
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._ -]'), '_');
    final destination = '${tracksDir.path}${Platform.pathSeparator}$safeName';
    return File(filePath).copy(destination).then((file) => file.path);
  }

  Future<void> disconnect(String endpointId) =>
      _nearby.disconnectFromEndpoint(endpointId);

  Future<void> stop() async {
    try {
      await _nearby.stopAdvertising();
      await _nearby.stopDiscovery();
      await _nearby.stopAllEndpoints();
    } on Object {
      // Nearby throws on some OEM builds if stop is called before start.
    }
    _endpointNames.clear();
    _hostEndpointId = null;
    _maxClients = null;
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
  }

  void _onHostConnectionInitiated(String endpointId, ConnectionInfo info) {
    final join = _decodeJoinName(info.endpointName);
    if (join == null || join.roomId != _roomId || join.password != _password) {
      unawaited(_nearby.rejectConnection(endpointId));
      _events.add(
        NetworkEvent(
          type: NetworkEventType.connectionRejected,
          endpointId: endpointId,
          endpointName: info.endpointName,
        ),
      );
      return;
    }
    if (_mode == SyncMode.star &&
        _maxClients != null &&
        _endpointNames.length >= _maxClients!) {
      unawaited(_nearby.rejectConnection(endpointId));
      _events.add(
        NetworkEvent(
          type: NetworkEventType.connectionRejected,
          endpointId: endpointId,
          endpointName: join.displayName,
          error: 'Room full. Use Festival Mode.',
        ),
      );
      return;
    }
    if (_mode == SyncMode.mesh && _hopCount > 6) {
      unawaited(_nearby.rejectConnection(endpointId));
      _events.add(
        NetworkEvent(
          type: NetworkEventType.connectionRejected,
          endpointId: endpointId,
          endpointName: join.displayName,
          error: 'Move closer to stage.',
        ),
      );
      return;
    }

    _endpointNames[endpointId] = join.displayName;
    unawaited(
      _nearby
          .acceptConnection(
            endpointId,
            onPayLoadRecieved: _onPayloadReceived,
            onPayloadTransferUpdate: _onPayloadTransferUpdate,
          )
          .then((ok) {
            if (!ok) {
              _events.add(
                NetworkEvent(
                  type: NetworkEventType.error,
                  endpointId: endpointId,
                  endpointName: _endpointNames[endpointId],
                  error: 'Unable to accept client connection.',
                ),
              );
            }
          })
          .catchError((Object error) {
            _events.add(
              NetworkEvent(
                type: NetworkEventType.error,
                endpointId: endpointId,
                endpointName: _endpointNames[endpointId],
                error: error,
              ),
            );
          }),
    );
  }

  void _onClientConnectionInitiated(String endpointId, ConnectionInfo info) {
    _endpointNames[endpointId] =
        _decodeHostName(info.endpointName)?.hostName ??
        _endpointNames[endpointId] ??
        'Host';
    unawaited(
      _nearby
          .acceptConnection(
            endpointId,
            onPayLoadRecieved: _onPayloadReceived,
            onPayloadTransferUpdate: _onPayloadTransferUpdate,
          )
          .then((ok) {
            if (!ok) {
              _events.add(
                NetworkEvent(
                  type: NetworkEventType.error,
                  endpointId: endpointId,
                  endpointName: _endpointNames[endpointId],
                  error: 'Unable to accept host connection.',
                ),
              );
            }
          })
          .catchError((Object error) {
            _events.add(
              NetworkEvent(
                type: NetworkEventType.error,
                endpointId: endpointId,
                endpointName: _endpointNames[endpointId],
                error: error,
              ),
            );
          }),
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _events.add(
        NetworkEvent(
          type: NetworkEventType.connected,
          endpointId: endpointId,
          endpointName: _endpointNames[endpointId],
        ),
      );
      return;
    }

    _events.add(
      NetworkEvent(
        type: NetworkEventType.connectionRejected,
        endpointId: endpointId,
        endpointName: _endpointNames[endpointId],
        error: status.name,
      ),
    );
  }

  void _onDisconnected(String endpointId) {
    _events.add(
      NetworkEvent(
        type: NetworkEventType.disconnected,
        endpointId: endpointId,
        endpointName: _endpointNames[endpointId],
      ),
    );
    _endpointNames.remove(endpointId);
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      try {
        final text = utf8.decode(payload.bytes!);
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          _events.add(
            NetworkEvent(
              type: NetworkEventType.message,
              endpointId: endpointId,
              endpointName: _endpointNames[endpointId],
              message: decoded,
            ),
          );
        }
      } on Object catch (error) {
        _events.add(
          NetworkEvent(
            type: NetworkEventType.error,
            endpointId: endpointId,
            error: error,
          ),
        );
      }
      return;
    }

    if (payload.type == PayloadType.FILE) {
      _events.add(
        NetworkEvent(
          type: NetworkEventType.filePayload,
          endpointId: endpointId,
          endpointName: _endpointNames[endpointId],
          payloadId: payload.id,
          fileUri: payload.uri,
          // ignore: deprecated_member_use
          filePath: payload.filePath,
        ),
      );
    }
  }

  void _onPayloadTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) {
    _events.add(
      NetworkEvent(
        type: NetworkEventType.fileTransferUpdate,
        endpointId: endpointId,
        endpointName: _endpointNames[endpointId],
        payloadId: update.id,
        transferStatus: update.status.name,
        bytesTransferred: update.bytesTransferred,
        totalBytes: update.totalBytes,
      ),
    );
  }

  static String _encodeHostName(
    String roomId,
    String displayName,
    SyncMode mode,
    int hopCount,
  ) => 'CSH|$roomId|${mode.name}|$hopCount|${_safe(displayName)}';

  static String _encodeClientDiscoveryName(String displayName) =>
      'CSD|${_safe(displayName)}';

  static String _encodeJoinName(
    String roomId,
    String password,
    String displayName,
  ) => 'CSJ|$roomId|$password|${_safe(displayName)}';

  static String _safe(String value) =>
      value.replaceAll('|', ' ').trim().replaceAll(RegExp(r'\s+'), ' ');

  static _HostAdvert? _decodeHostName(String value) {
    final parts = value.split('|');
    if (parts.length < 3 || parts.first != 'CSH') return null;
    if (parts.length >= 5) {
      return _HostAdvert(
        parts[1],
        parts.sublist(4).join('|'),
        SyncMode.values.firstWhere(
          (mode) => mode.name == parts[2],
          orElse: () => SyncMode.star,
        ),
        int.tryParse(parts[3]) ?? 0,
      );
    }
    return _HostAdvert(parts[1], parts.sublist(2).join('|'), SyncMode.star, 0);
  }

  static _JoinRequest? _decodeJoinName(String value) {
    final parts = value.split('|');
    if (parts.length < 4 || parts.first != 'CSJ') return null;
    return _JoinRequest(parts[1], parts[2], parts.sublist(3).join('|'));
  }

  Strategy _strategyFor(SyncMode mode) {
    return switch (mode) {
      SyncMode.mesh => Strategy.P2P_CLUSTER,
      SyncMode.star || SyncMode.router => Strategy.P2P_STAR,
    };
  }
}

class _HostAdvert {
  const _HostAdvert(this.roomId, this.hostName, this.mode, this.hopCount);

  final String roomId;
  final String hostName;
  final SyncMode mode;
  final int hopCount;
}

class _JoinRequest {
  const _JoinRequest(this.roomId, this.password, this.displayName);

  final String roomId;
  final String password;
  final String displayName;
}
