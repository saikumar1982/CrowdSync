import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class NearbyPermissionResult {
  const NearbyPermissionResult({required this.granted, this.message});

  final bool granted;
  final String? message;
}

class PermissionService {
  Future<NearbyPermissionResult> requestNearbyPermissions() async {
    final required = _nearbyPermissionsForDevice();
    final statuses = await required.request();
    final missing = <String>{};

    for (final permission in required) {
      final status = statuses[permission] ?? await permission.status;
      if (!_isUsable(status)) {
        missing.add(_labelFor(permission));
      }
    }

    if (missing.isEmpty) {
      return const NearbyPermissionResult(granted: true);
    }

    return NearbyPermissionResult(
      granted: false,
      message:
          'Allow ${missing.join(', ')} for CrowdSync, then turn on Wi-Fi, Bluetooth, and Location and try again.',
    );
  }

  Future<bool> hasNearbyBasics() async {
    for (final permission in _nearbyPermissionsForDevice()) {
      if (!_isUsable(await permission.status)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> requestCameraForTorch() async {
    final status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }

  List<Permission> _nearbyPermissionsForDevice() {
    final androidApi = _androidApiLevel;
    if (!Platform.isAndroid) {
      return const [];
    }

    if (androidApi == null || androidApi >= 33) {
      return const [
        Permission.locationWhenInUse,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
        Permission.notification,
      ];
    }

    if (androidApi >= 31) {
      return const [
        Permission.locationWhenInUse,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ];
    }

    return const [Permission.locationWhenInUse, Permission.bluetooth];
  }

  int? get _androidApiLevel {
    final match = RegExp(
      r'API\s+(\d+)',
    ).firstMatch(Platform.operatingSystemVersion);
    return int.tryParse(match?.group(1) ?? '');
  }

  bool _isUsable(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  String _labelFor(Permission permission) {
    if (permission == Permission.locationWhenInUse) {
      return 'Location';
    }
    if (permission == Permission.nearbyWifiDevices) {
      return 'Nearby Wi-Fi devices';
    }
    if (permission == Permission.notification) {
      return 'Notifications';
    }
    if (permission == Permission.bluetooth ||
        permission == Permission.bluetoothScan ||
        permission == Permission.bluetoothAdvertise ||
        permission == Permission.bluetoothConnect) {
      return 'Nearby devices/Bluetooth';
    }
    return permission.toString();
  }

  Future<bool> hasWifi() async {
    if (!Platform.isAndroid) return false;
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    return interfaces.any((iface) {
      final name = iface.name.toLowerCase();
      return name.contains('wlan') ||
          name.contains('wifi') ||
          name.contains('wi-fi');
    });
  }
}
