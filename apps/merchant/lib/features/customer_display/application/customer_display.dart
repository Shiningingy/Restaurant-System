import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/providers.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/window/window_control.dart';
import '../../menu/application/providers.dart';
import '../../orders/application/providers.dart';
import '../customer_display_channel.dart';
import 'kiosk_bridge.dart';

/// Opens and feeds the customer-facing display sub-window, and — for the
/// interactive kiosk modes — registers the POS-side handler that turns a cart
/// the customer built on that screen into a real order in the local database.
///
/// The window opens on the primary monitor; staff drag it to the customer-
/// facing screen. The POS pushes it order snapshots so it mirrors what's being
/// rung up, shows a rotating promo when idle, and (kiosk/hybrid) lets the
/// customer order themselves entirely offline on the one machine.
class CustomerDisplayController {
  CustomerDisplayController(this._ref);

  final Ref _ref;

  WindowController? _window;
  WindowMethodChannel? _channel;

  bool get isOpen => _window != null;

  Future<void> open({
    required String businessName,
    required CustomerDisplayMode mode,
    List<String> promoLines = const [],
    List<String> promoImages = const [],
  }) async {
    if (_window != null) return;
    // Register the POS-side handler before the window exists so the kiosk's
    // first call (requestMenu) always lands.
    final channel = WindowMethodChannel(kCustomerDisplayChannel);
    await channel.setMethodCallHandler(_handleFromDisplay);
    _channel = channel;

    final window = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode({
          'businessName': businessName,
          'promo': promoLines,
          'promoImages': promoImages,
          'mode': mode.name,
        }),
        hiddenAtLaunch: false,
      ),
    );
    _window = window;
    await window.show();
  }

  /// Closes (destroys) the display window natively and resets state so it can
  /// be reopened. The plugin exposes no close, so this goes through the native
  /// window-control channel.
  Future<void> close() async {
    await _ref.read(windowControlProvider).closeDisplay();
    await _channel?.setMethodCallHandler(null);
    _channel = null;
    _window = null;
  }

  /// Hides the display off-screen (staff control; reverse with [restore]).
  Future<void> minimize() => _ref.read(windowControlProvider).minimizeDisplay();

  /// Re-shows a hidden display.
  Future<void> restore() => _ref.read(windowControlProvider).showDisplay();

  /// Pushes the current order (or null to show the idle/promo screen). Best
  /// effort — silently no-ops if the display window isn't listening yet.
  Future<void> pushOrder(Map<String, dynamic>? order) =>
      _invoke('order', order == null ? null : jsonEncode(order));

  /// Pushes a fresh menu snapshot to the kiosk (e.g. after the menu changed).
  Future<void> pushMenu() async =>
      _invoke('menu', jsonEncode(await _buildMenuSnapshot()));

  /// Changes the display mode live without reopening the window.
  Future<void> pushMode(CustomerDisplayMode mode) => _invoke('mode', mode.name);

  Future<void> _invoke(String method, dynamic args) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.invokeMethod(method, args);
    } catch (_) {
      // The display window may not have registered its handler yet, or may be
      // closed — pushes are advisory, so swallow the channel error.
    }
  }

  /// Handles calls coming **from** the display/kiosk window.
  Future<dynamic> _handleFromDisplay(MethodCall call) async {
    switch (call.method) {
      case 'requestMenu':
        return jsonEncode(await _buildMenuSnapshot());
      case 'submitOrder':
        return jsonEncode(await _submitKioskOrder(call.arguments as String));
      default:
        return null;
    }
  }

  Future<Map<String, dynamic>> _buildMenuSnapshot() {
    final settings = _ref.read(settingsRepositoryProvider);
    return buildKioskMenuSnapshot(
      _ref.read(menuRepositoryProvider),
      businessName: settings.receiptConfig.businessName,
      taxRateBp: settings.taxRateBp,
      serviceFeeBp: settings.serviceFeeBp,
      payHere: settings.kioskPayHere,
    );
  }

  /// Turns a cart pushed from the kiosk window into a real local order. The
  /// heavy lifting lives in [registerKioskOrder] (pure, unit-tested); this just
  /// decodes the payload and supplies the repos + tax/fee settings.
  Future<Map<String, dynamic>> _submitKioskOrder(String payload) async {
    final cart = jsonDecode(payload) as Map<String, dynamic>;
    final settings = _ref.read(settingsRepositoryProvider);
    return registerKioskOrder(
      menu: _ref.read(menuRepositoryProvider),
      orders: _ref.read(orderRepositoryProvider),
      taxRateBp: settings.taxRateBp,
      serviceFeeBp: settings.serviceFeeBp,
      pickupNumber: await settings.nextKioskNumber(),
      lines: (cart['lines'] as List).cast<Map<String, dynamic>>(),
    );
  }
}

final customerDisplayProvider = Provider<CustomerDisplayController>(
  (ref) => CustomerDisplayController(ref),
);
