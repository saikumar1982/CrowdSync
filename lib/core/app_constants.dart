import 'dart:math';

class AppConstants {
  static const appName = 'CrowdSync';
  static const serviceId = 'app.crowdsync.local';
  static const protocolVersion = 1;
  static const startBuffer = Duration(milliseconds: 1600);
  static const clockSyncInterval = Duration(seconds: 5);
  static const playbackBroadcastInterval = Duration(seconds: 1);
  static const correctionThreshold = Duration(milliseconds: 8);
  static const hardCorrectionThreshold = Duration(milliseconds: 40);

  static final _random = Random.secure();

  static String generateRoomId() =>
      (100000 + _random.nextInt(900000)).toString();

  static String generatePassword() =>
      (100000 + _random.nextInt(900000)).toString();
}
