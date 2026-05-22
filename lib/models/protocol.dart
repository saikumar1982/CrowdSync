class ProtocolType {
  static const clockSync = 'clock_sync';
  static const clockAck = 'clock_ack';
  static const clockResult = 'clock_result';
  static const playbackState = 'playback_state';
  static const play = 'play';
  static const pause = 'pause';
  static const seek = 'seek';
  static const syncRequest = 'sync_request';
  static const fileMeta = 'file_meta';
  static const flashlight = 'flashlight';
  static const remove = 'remove';
  static const roomSnapshot = 'room_snapshot';
}

Map<String, dynamic> wireMessage(String type, Map<String, dynamic> data) => {
  'type': type,
  ...data,
};
