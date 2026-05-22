import 'package:flutter/services.dart';

import '../models/app_mode.dart';

class NativeClockEstimate {
  const NativeClockEstimate({
    this.clientMinusHostMicros = 0,
    this.roundTripMicros = 0,
    this.driftPpm = 0,
    this.samples = 0,
    this.lastUpdatedMicros = 0,
  });

  final int clientMinusHostMicros;
  final int roundTripMicros;
  final double driftPpm;
  final int samples;
  final int lastUpdatedMicros;

  factory NativeClockEstimate.fromMap(Map<dynamic, dynamic> map) {
    return NativeClockEstimate(
      clientMinusHostMicros: _asInt(map['clientMinusHostMicros']),
      roundTripMicros: _asInt(map['roundTripMicros']),
      driftPpm: _asDouble(map['driftPpm']),
      samples: _asInt(map['samples']),
      lastUpdatedMicros: _asInt(map['lastUpdatedMicros']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class NativeSyncService {
  static const _channel = MethodChannel('crowdsync/native_sync');

  Future<int> nowMicros() async {
    final value = await _channel.invokeMethod<int>('nowMicros');
    return value ?? 0;
  }

  Future<void> resetClock() => _channel.invokeMethod<void>('resetClock');

  Future<NativeClockEstimate> updateClock({
    required int hostSendMicros,
    required int clientReceiveMicros,
    required int clientSendMicros,
    required int hostReceiveMicros,
  }) async {
    final map = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('updateClock', {
          'hostSendMicros': hostSendMicros,
          'clientReceiveMicros': clientReceiveMicros,
          'clientSendMicros': clientSendMicros,
          'hostReceiveMicros': hostReceiveMicros,
        });
    return NativeClockEstimate.fromMap(map ?? const {});
  }

  Future<int> hostToLocalMicros(int hostMicros) async {
    final value = await _channel.invokeMethod<int>('hostToLocalMicros', {
      'hostMicros': hostMicros,
    });
    return value ?? hostMicros;
  }

  Future<int> localToHostMicros(int localMicros) async {
    final value = await _channel.invokeMethod<int>('localToHostMicros', {
      'localMicros': localMicros,
    });
    return value ?? localMicros;
  }

  Future<NativeClockEstimate> currentEstimate() async {
    final map = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'currentEstimate',
    );
    return NativeClockEstimate.fromMap(map ?? const {});
  }

  Future<void> scheduleFlashlight({
    required FlashlightMode mode,
    required bool optIn,
    required int localStartMicros,
    int beatMicros = 500000,
    int durationMicros = 0,
  }) {
    return _channel.invokeMethod<void>('scheduleFlashlight', {
      'mode': mode.name,
      'optIn': optIn,
      'localStartMicros': localStartMicros,
      'beatMicros': beatMicros,
      'durationMicros': durationMicros,
    });
  }

  Future<void> stopFlashlight() =>
      _channel.invokeMethod<void>('stopFlashlight');

  Future<int> ntpSync(String hostIp) async {
    final value = await _channel.invokeMethod<int>('ntpSync', {
      'hostIp': hostIp,
    });
    return value ?? 0;
  }

  Future<int> syncedElapsedRealtimeMs() async {
    final value = await _channel.invokeMethod<int>('syncedElapsedRealtimeMs');
    return value ?? 0;
  }

  Future<void> acquirePerformanceLocks() =>
      _channel.invokeMethod<void>('acquirePerformanceLocks');

  Future<void> releasePerformanceLocks() =>
      _channel.invokeMethod<void>('releasePerformanceLocks');

  Future<int> audioTrackDriftMicros() async {
    final value = await _channel.invokeMethod<int>('audioTrackDriftMicros');
    return value ?? 0;
  }
}
