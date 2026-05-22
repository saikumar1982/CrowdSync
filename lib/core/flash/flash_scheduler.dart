import '../../models/app_mode.dart';
import '../../services/native_sync_service.dart';

class FlashScheduler {
  FlashScheduler(this._nativeSync);

  final NativeSyncService _nativeSync;

  Future<void> scheduleBeatPattern({
    required int startAtEpochMs,
    required int bpm,
    required int durationMs,
    required int hopCount,
    required SyncMode mode,
    required bool optIn,
  }) async {
    if (!mode.supportsFlashAtHop(hopCount) || bpm <= 0 || durationMs <= 0) {
      await _nativeSync.stopFlashlight();
      return;
    }
    final beatMicros = (60000000 / bpm).round();
    final nowMicros = await _nativeSync.nowMicros();
    final localStartMicros =
        nowMicros +
        ((startAtEpochMs - DateTime.now().millisecondsSinceEpoch) * 1000);
    await _nativeSync.scheduleFlashlight(
      mode: FlashlightMode.pulse,
      optIn: optIn,
      localStartMicros: localStartMicros,
      beatMicros: beatMicros,
      durationMicros: durationMs * 1000,
    );
  }
}
