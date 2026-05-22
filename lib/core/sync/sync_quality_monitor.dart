import 'dart:async';
import 'dart:collection';

import '../../models/app_mode.dart';
import '../../services/audio_service.dart';

class SyncQualityMonitor {
  SyncQualityMonitor({required CrowdAudioService audio}) : _audio = audio;

  final CrowdAudioService _audio;
  final StreamController<SyncQuality> _quality =
      StreamController<SyncQuality>.broadcast();
  final Queue<int> _samplesMs = Queue<int>();
  Timer? _timer;
  int _poorSeconds = 0;

  Stream<SyncQuality> get stream => _quality.stream;

  void start() {
    stop();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final drift = (await _audio.getDriftMs()).abs();
      _samplesMs.add(drift);
      while (_samplesMs.length > 20) {
        _samplesMs.removeFirst();
      }
      final next = _qualityForSamples();
      _poorSeconds = next == SyncQuality.poor ? _poorSeconds + 1 : 0;
      _quality.add(next);
    });
  }

  bool get shouldAutoResync => _poorSeconds >= 10;

  void stop() {
    _timer?.cancel();
    _timer = null;
    _poorSeconds = 0;
    _samplesMs.clear();
  }

  SyncQuality _qualityForSamples() {
    if (_samplesMs.isEmpty) return SyncQuality.unknown;
    final sorted = _samplesMs.toList()..sort();
    final p95Index = ((sorted.length - 1) * 0.95).round();
    final p95 = sorted[p95Index];
    if (p95 < 10) return SyncQuality.excellent;
    if (p95 < 25) return SyncQuality.good;
    return SyncQuality.poor;
  }

  Future<void> dispose() async {
    stop();
    await _quality.close();
  }
}
