import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens and feeds the customer-facing display sub-window. The window opens on
/// the primary monitor; staff drag it to the extended customer-facing screen.
/// The POS pushes it order snapshots so it mirrors what's being rung up, and it
/// shows a welcome/promo screen when idle.
class CustomerDisplayController {
  WindowController? _window;

  bool get isOpen => _window != null;

  Future<void> open({required String businessName}) async {
    if (_window != null) return;
    final window = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode({'businessName': businessName}),
        hiddenAtLaunch: false,
      ),
    );
    _window = window;
    await window.show();
  }

  /// Pushes the current order (or null to show the idle/welcome screen).
  Future<void> pushOrder(Map<String, dynamic>? order) async {
    await _window?.invokeMethod(
      'order',
      order == null ? null : jsonEncode(order),
    );
  }
}

final customerDisplayProvider = Provider<CustomerDisplayController>(
  (ref) => CustomerDisplayController(),
);
