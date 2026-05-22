enum AppRoute {
  splash,
  home,
  hostDashboard,
  clientDashboard,
  calibration,
  settings,
  qrScanner,
}

enum AppMode { idle, host, client }

enum PlaybackPhase { idle, loading, ready, playing, paused, interrupted }

enum FlashlightMode { off, steady, pulse, strobe, bassReactive }

enum SyncQuality { unknown, excellent, good, poor, disconnected }

enum SyncMode { star, mesh, router }

enum ForceSyncMode { auto, star, mesh, router }

enum RoomSizePreset { small, medium, large }

extension SyncModeLabel on SyncMode {
  String get label {
    switch (this) {
      case SyncMode.star:
        return 'Star';
      case SyncMode.mesh:
        return 'Mesh';
      case SyncMode.router:
        return 'Router';
    }
  }

  String get marketingName {
    switch (this) {
      case SyncMode.star:
        return 'House Party';
      case SyncMode.mesh:
        return 'Festival';
      case SyncMode.router:
        return 'Concert';
    }
  }

  int get maxSupportedClients {
    switch (this) {
      case SyncMode.star:
        return 45;
      case SyncMode.mesh:
        return 729;
      case SyncMode.router:
        return 5000;
    }
  }

  int worstCaseLatencyMs({int hopCount = 0}) {
    switch (this) {
      case SyncMode.star:
        return 5;
      case SyncMode.mesh:
        return hopCount <= 0 ? 20 : hopCount * 20;
      case SyncMode.router:
        return 3;
    }
  }

  bool supportsFlashAtHop(int hopCount) {
    switch (this) {
      case SyncMode.star:
      case SyncMode.router:
        return true;
      case SyncMode.mesh:
        return hopCount <= 4;
    }
  }
}

extension ForceSyncModeLabel on ForceSyncMode {
  String get label {
    switch (this) {
      case ForceSyncMode.auto:
        return 'Auto';
      case ForceSyncMode.star:
        return 'Force Star';
      case ForceSyncMode.mesh:
        return 'Force Mesh';
      case ForceSyncMode.router:
        return 'Force Router';
    }
  }

  SyncMode? get forcedMode {
    switch (this) {
      case ForceSyncMode.auto:
        return null;
      case ForceSyncMode.star:
        return SyncMode.star;
      case ForceSyncMode.mesh:
        return SyncMode.mesh;
      case ForceSyncMode.router:
        return SyncMode.router;
    }
  }
}

extension RoomSizePresetLabel on RoomSizePreset {
  String get label {
    switch (this) {
      case RoomSizePreset.small:
        return 'Small <50';
      case RoomSizePreset.medium:
        return 'Medium 50-200';
      case RoomSizePreset.large:
        return 'Large 200+';
    }
  }

  String get description {
    switch (this) {
      case RoomSizePreset.small:
        return 'STAR House Party, host phone is server, <10ms target.';
      case RoomSizePreset.medium:
        return 'MESH Festival, Nearby cluster tree, flash limited to 4 hops.';
      case RoomSizePreset.large:
        return 'ROUTER Concert, external WiFi6 router CrowdSync_5G.';
    }
  }

  int get expectedCrowdSize {
    switch (this) {
      case RoomSizePreset.small:
        return 40;
      case RoomSizePreset.medium:
        return 150;
      case RoomSizePreset.large:
        return 2000;
    }
  }
}

extension FlashlightModeLabel on FlashlightMode {
  String get label {
    switch (this) {
      case FlashlightMode.off:
        return 'Off';
      case FlashlightMode.steady:
        return 'Steady';
      case FlashlightMode.pulse:
        return 'Pulse';
      case FlashlightMode.strobe:
        return 'Strobe';
      case FlashlightMode.bassReactive:
        return 'Bass';
    }
  }
}

extension SyncQualityLabel on SyncQuality {
  String get label {
    switch (this) {
      case SyncQuality.unknown:
        return 'Waiting';
      case SyncQuality.excellent:
        return 'Excellent';
      case SyncQuality.good:
        return 'Good';
      case SyncQuality.poor:
        return 'Poor';
      case SyncQuality.disconnected:
        return 'Offline';
    }
  }
}
