import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/app_theme.dart';
import '../providers/app_providers.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Room QR'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: controller.goHome,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              final codes = capture.barcodes;
              for (final code in codes) {
                final value = code.rawValue;
                if (value == null) continue;
                _handled = true;
                controller.joinFromQr(value);
                break;
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              color: AppTheme.bg.withValues(alpha: 0.86),
              child: const Text(
                'Point the camera at the host QR code.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
