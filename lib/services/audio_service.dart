import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../models/app_mode.dart';

enum AudioInterruptionKind { began, ended }

class AudioInterruptionNotice {
  const AudioInterruptionNotice(this.kind);

  final AudioInterruptionKind kind;
}

class CrowdAudioService {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<AudioInterruptionNotice> _interruptions =
      StreamController<AudioInterruptionNotice>.broadcast();
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  Timer? _scheduledPlay;
  SyncMode _mode = SyncMode.star;
  Duration? _lastPositionSample;
  DateTime? _lastPositionSampleAt;

  AudioPlayer get player => _player;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<AudioInterruptionNotice> get interruptions => _interruptions.stream;

  Duration get position => _player.position;

  Duration? get duration => _player.duration;

  bool get isPlaying => _player.playing;

  SyncMode get mode => _mode;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _interruptionSub ??= session.interruptionEventStream.listen((event) {
      if (event.begin) {
        unawaited(pause());
        _interruptions.add(
          const AudioInterruptionNotice(AudioInterruptionKind.began),
        );
      } else {
        _interruptions.add(
          const AudioInterruptionNotice(AudioInterruptionKind.ended),
        );
      }
    });
  }

  Future<void> setFilePath(String path) async {
    _scheduledPlay?.cancel();
    _rejectUnsupportedForSync(path);
    await _player.setFilePath(path);
  }

  Future<void> setMode(SyncMode mode) async {
    _mode = mode;
  }

  Future<void> schedulePlayAfter({
    required Duration delay,
    required Duration position,
  }) async {
    _scheduledPlay?.cancel();
    await _player.seek(position);
    final routerJitterBuffer = _mode == SyncMode.router
        ? const Duration(milliseconds: 200)
        : Duration.zero;
    final scheduledDelay = delay.isNegative
        ? routerJitterBuffer
        : delay + routerJitterBuffer;
    _scheduledPlay = Timer(scheduledDelay, () {
      unawaited(_player.play());
    });
  }

  Future<void> playNow() async {
    _scheduledPlay?.cancel();
    await _player.play();
  }

  Future<void> pause() async {
    _scheduledPlay?.cancel();
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<int> correctTo(Duration target, Duration threshold) async {
    final driftMicros = target.inMicroseconds - _player.position.inMicroseconds;
    final hardFailsafe =
        driftMicros.abs() > const Duration(milliseconds: 100).inMicroseconds;
    if (driftMicros.abs() >= threshold.inMicroseconds) {
      await _player.seek(target);
      if (hardFailsafe && !_player.playing) {
        await _player.play();
      }
    }
    return driftMicros;
  }

  Future<int> getDriftMs() async {
    final now = DateTime.now();
    final lastPosition = _lastPositionSample;
    final lastAt = _lastPositionSampleAt;
    _lastPositionSample = _player.position;
    _lastPositionSampleAt = now;
    if (!_player.playing || lastPosition == null || lastAt == null) {
      return 0;
    }
    final expected = lastPosition + now.difference(lastAt);
    return _player.position.inMilliseconds - expected.inMilliseconds;
  }

  void _rejectUnsupportedForSync(String path) {
    final lower = path.toLowerCase();
    final accepted =
        lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.ogg');
    if (!accepted) {
      throw StateError('CrowdSync accepts local audio files only.');
    }
  }

  Future<void> dispose() async {
    _scheduledPlay?.cancel();
    await _interruptionSub?.cancel();
    await _interruptions.close();
    await _player.dispose();
  }
}
