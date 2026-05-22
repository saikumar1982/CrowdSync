import 'package:pigeon/pigeon.dart';

class ClockSyncSample {
  ClockSyncSample({
    required this.hostSendMicros,
    required this.clientReceiveMicros,
    required this.clientSendMicros,
    required this.hostReceiveMicros,
  });

  final int hostSendMicros;
  final int clientReceiveMicros;
  final int clientSendMicros;
  final int hostReceiveMicros;
}

class ClockSyncEstimate {
  ClockSyncEstimate({
    required this.clientMinusHostMicros,
    required this.roundTripMicros,
    required this.driftPpm,
    required this.samples,
  });

  final int clientMinusHostMicros;
  final int roundTripMicros;
  final double driftPpm;
  final int samples;
}

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeons/clock_sync.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/crowdsync/app/ClockSyncApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.crowdsync.app'),
  ),
)
@HostApi()
abstract class ClockSyncApi {
  int nowMicros();

  int ntpSync(String hostIp);

  int syncedElapsedRealtimeMs();

  ClockSyncEstimate updateClock(ClockSyncSample sample);

  void postAtSyncedTime(int syncedTimeMs);

  void resetClock();
}
