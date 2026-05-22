import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'models/app_mode.dart';
import 'providers/app_providers.dart';
import 'screens/calibration_screen.dart';
import 'screens/client_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/host_dashboard_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CrowdSyncApp()));
}

class CrowdSyncApp extends ConsumerStatefulWidget {
  const CrowdSyncApp({super.key});

  @override
  ConsumerState<CrowdSyncApp> createState() => _CrowdSyncAppState();
}

class _CrowdSyncAppState extends ConsumerState<CrowdSyncApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appControllerProvider.notifier).handleLifecycle(state);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return MaterialApp(
      title: 'CrowdSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: switch (app.route) {
        AppRoute.splash => const SplashScreen(),
        AppRoute.home => const HomeScreen(),
        AppRoute.hostDashboard => const HostDashboardScreen(),
        AppRoute.clientDashboard => const ClientDashboardScreen(),
        AppRoute.calibration => const CalibrationScreen(),
        AppRoute.settings => const SettingsScreen(),
        AppRoute.qrScanner => const QrScannerScreen(),
      },
    );
  }
}
