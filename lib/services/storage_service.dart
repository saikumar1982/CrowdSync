import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_mode.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _store {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('StorageService.init must be called before use.');
    }
    return prefs;
  }

  String get deviceName {
    final existing = _store.getString('deviceName');
    if (existing != null && existing.trim().isNotEmpty) return existing;
    final suffix = Random().nextInt(9000) + 1000;
    final generated = 'Crowd $suffix';
    _store.setString('deviceName', generated);
    return generated;
  }

  Future<void> setDeviceName(String value) =>
      _store.setString('deviceName', value.trim());

  int get calibrationOffsetMs => _store.getInt('calibrationOffsetMs') ?? 0;

  Future<void> setCalibrationOffsetMs(int value) =>
      _store.setInt('calibrationOffsetMs', value);

  bool get flashlightOptIn => _store.getBool('flashlightOptIn') ?? true;

  Future<void> setFlashlightOptIn(bool value) =>
      _store.setBool('flashlightOptIn', value);

  ForceSyncMode get forceSyncMode {
    final name = _store.getString('forceSyncMode') ?? ForceSyncMode.auto.name;
    return ForceSyncMode.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ForceSyncMode.auto,
    );
  }

  Future<void> setForceSyncMode(ForceSyncMode value) =>
      _store.setString('forceSyncMode', value.name);

  RoomSizePreset get roomSizePreset {
    final name =
        _store.getString('roomSizePreset') ?? RoomSizePreset.small.name;
    return RoomSizePreset.values.firstWhere(
      (value) => value.name == name,
      orElse: () => RoomSizePreset.small,
    );
  }

  Future<void> setRoomSizePreset(RoomSizePreset value) =>
      _store.setString('roomSizePreset', value.name);
}
