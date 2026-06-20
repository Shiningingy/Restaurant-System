import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n_ext.dart';
import '../data/storefront_link.dart';

/// Whether this device can scan QR codes (needs a camera + a mobile_scanner
/// platform implementation). Desktop falls back to manual entry.
bool get qrScanSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Full-screen camera that resolves to a [StorefrontLink] when a valid
/// storefront QR is scanned (pop with the link), or null if cancelled.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;
  bool _sawInvalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final link = StorefrontLink.tryParse(raw);
      if (link != null) {
        _handled = true;
        Navigator.of(context).pop(link);
        return;
      }
    }
    // Saw a code, but it wasn't one of ours — nudge the user.
    if (mounted && !_sawInvalid) setState(() => _sawInvalid = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanTitle)),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(20),
              child: Text(
                _sawInvalid ? context.l10n.scanInvalid : context.l10n.scanHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
