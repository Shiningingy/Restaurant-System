import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/l10n_ext.dart';
import '../data/storefront_link.dart';

/// Whether this device can scan QR codes (needs a camera + a mobile_scanner
/// platform implementation). Desktop falls back to manual entry.
bool get qrScanSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Where the camera permission currently stands for this screen.
enum _CamState { checking, granted, denied, blocked }

/// Full-screen camera that resolves to a [StorefrontLink] when a valid
/// storefront QR is scanned (pop with the link), or null if cancelled.
///
/// Camera is a runtime permission on Android/iOS: declaring it in the manifest
/// isn't enough, something has to *request* it. We ask up front, then show the
/// scanner only once it's granted — otherwise the user just gets a black screen
/// with no explanation.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController? _controller;
  _CamState _state = _CamState.checking;
  bool _handled = false;
  bool _sawInvalid = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    setState(() => _state = _CamState.checking);
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      if (status.isGranted || status.isLimited) {
        _controller ??= MobileScannerController();
        _state = _CamState.granted;
      } else if (status.isPermanentlyDenied || status.isRestricted) {
        _state = _CamState.blocked; // can't re-prompt; must use Settings
      } else {
        _state = _CamState.denied; // can ask again
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
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
      body: switch (_state) {
        _CamState.checking => const Center(child: CircularProgressIndicator()),
        _CamState.granted => _buildScanner(context),
        _CamState.denied => _PermissionMessage(
          message: context.l10n.scanCameraNeeded,
          actionLabel: context.l10n.scanAllowCamera,
          onAction: _requestPermission,
        ),
        _CamState.blocked => _PermissionMessage(
          message: context.l10n.scanCameraBlocked,
          actionLabel: context.l10n.scanOpenSettings,
          onAction: openAppSettings,
        ),
      },
    );
  }

  Widget _buildScanner(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) => _PermissionMessage(
            message: context.l10n.scanCameraError,
            actionLabel: context.l10n.scanOpenSettings,
            onAction: openAppSettings,
          ),
        ),
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
    );
  }
}

/// A centred "we need the camera" explainer with a single action button —
/// reused for the can-ask-again, permanently-blocked and camera-error cases.
class _PermissionMessage extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _PermissionMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
