import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/settings/settings_repository.dart'
    show CustomerDisplayMode;
import '../customer_display_channel.dart';
import 'kiosk_menu.dart';
import 'kiosk_surface.dart';

/// Root of the customer-facing display sub-window (runs in its own engine on
/// the extended monitor). It owns no database; the POS window pushes it the
/// menu, order snapshots and the active mode over the customer-display channel
/// (addressed by name, so no window-controller reference is needed), and — in
/// kiosk/hybrid mode — the customer's built order is pushed back to the POS to
/// register.
class CustomerDisplayApp extends StatelessWidget {
  final Map<String, dynamic> args;

  const CustomerDisplayApp({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: CustomerDisplayScreen(
        businessName: args['businessName'] as String? ?? '',
        promoLines:
            (args['promo'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        mode:
            CustomerDisplayMode.values.asNameMap()[args['mode']] ??
            CustomerDisplayMode.passive,
      ),
    );
  }
}

/// Switches between three surfaces depending on the configured mode and what
/// the POS is pushing:
/// - **mirror** — live view of the order the cashier is ringing up;
/// - **promo** — rotating idle screen (with a "tap to order" call in hybrid);
/// - **kiosk** — the interactive self-order flow.
class CustomerDisplayScreen extends StatefulWidget {
  final String businessName;
  final List<String> promoLines;
  final CustomerDisplayMode mode;

  const CustomerDisplayScreen({
    super.key,
    required this.businessName,
    required this.promoLines,
    required this.mode,
  });

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  final _channel = WindowMethodChannel(kCustomerDisplayChannel);

  late CustomerDisplayMode _mode = widget.mode;
  late String _businessName = widget.businessName;
  Map<String, dynamic>? _order;
  KioskMenu? _menu;

  /// Hybrid only: the customer tapped "order" on the promo screen and is in the
  /// kiosk flow. Reset when the cashier starts ringing an order.
  bool _hybridKiosk = false;

  Timer? _promoTimer;
  int _promoIndex = 0;

  bool get _interactive =>
      _mode == CustomerDisplayMode.kiosk ||
      (_mode == CustomerDisplayMode.hybrid && _hybridKiosk);

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleFromPos);
    _requestMenu();
    if (widget.promoLines.length > 1) {
      _promoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted && !_interactive) {
          setState(
            () => _promoIndex = (_promoIndex + 1) % widget.promoLines.length,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<dynamic> _handleFromPos(MethodCall call) async {
    switch (call.method) {
      case 'order':
        final raw = call.arguments as String?;
        final order = (raw == null || raw.isEmpty)
            ? null
            : jsonDecode(raw) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _order = order;
            // A cashier order takes the screen back from a hybrid kiosk session.
            if (order != null) _hybridKiosk = false;
          });
        }
      case 'menu':
        _applyMenu(call.arguments as String?);
      case 'mode':
        final m = CustomerDisplayMode.values.asNameMap()[call.arguments];
        if (m != null && mounted) setState(() => _mode = m);
    }
    return null;
  }

  Future<void> _requestMenu() async {
    try {
      final json = await _channel.invokeMethod<String>('requestMenu');
      _applyMenu(json);
    } catch (_) {
      // POS not ready yet — the menu also arrives via a 'menu' push.
    }
  }

  void _applyMenu(String? json) {
    if (json == null || json.isEmpty) return;
    final menu = KioskMenu.fromJson(jsonDecode(json) as Map<String, dynamic>);
    if (mounted) {
      setState(() {
        _menu = menu;
        if (menu.businessName.isNotEmpty) _businessName = menu.businessName;
      });
    }
  }

  Future<Map<String, dynamic>> _submit(List<CartLine> cart) async {
    final res = await _channel.invokeMethod<String>(
      'submitOrder',
      jsonEncode({
        'lines': [for (final l in cart) l.toSubmitJson()],
      }),
    );
    if (res == null) return {'ok': false};
    return jsonDecode(res) as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final lines = (order?['lines'] as List?) ?? const [];
    final hasOrder = lines.isNotEmpty;

    // Dedicated kiosk, or hybrid with the customer ordering: interactive flow.
    if (_interactive) {
      return KioskSurface(
        businessName: _businessName,
        menu: _menu,
        onSubmit: _submit,
        onRefreshMenu: _requestMenu,
        // Hybrid sessions can bow out back to the promo screen; a dedicated
        // kiosk has nowhere to exit to.
        onExit: _mode == CustomerDisplayMode.hybrid
            ? () => setState(() => _hybridKiosk = false)
            : null,
      );
    }

    // Passive / hybrid-idle: mirror the cashier's order, else show promo.
    if (hasOrder) {
      return Scaffold(
        body: _OrderMirror(
          businessName: _businessName,
          lines: lines.cast<Map<String, dynamic>>(),
          total: order?['total'] as String? ?? '',
        ),
      );
    }
    return Scaffold(
      body: _IdlePromo(
        businessName: _businessName,
        promo: widget.promoLines.isEmpty
            ? null
            : widget.promoLines[_promoIndex % widget.promoLines.length],
        // Hybrid invites the customer to order; passive is view-only.
        onTapToOrder: _mode == CustomerDisplayMode.hybrid && _menu != null
            ? () => setState(() => _hybridKiosk = true)
            : null,
      ),
    );
  }
}

/// The idle / promo screen: business name with a rotating promo line beneath,
/// and (hybrid) a prominent "tap to order" call to action.
class _IdlePromo extends StatelessWidget {
  final String businessName;
  final String? promo;
  final VoidCallback? onTapToOrder;

  const _IdlePromo({
    required this.businessName,
    required this.promo,
    this.onTapToOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant,
            size: 120,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 24),
          Text(
            businessName.isEmpty ? 'Welcome' : businessName,
            style: theme.textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          if (promo != null && promo!.isNotEmpty) ...[
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                promo!,
                key: ValueKey(promo),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (onTapToOrder != null) ...[
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: onTapToOrder,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                textStyle: theme.textTheme.headlineSmall,
              ),
              icon: const Icon(Icons.touch_app, size: 32),
              label: const Text('Tap to order'),
            ),
          ],
        ],
      ),
    );
    // The whole idle screen is tappable in hybrid, so anywhere starts an order.
    return onTapToOrder == null
        ? content
        : GestureDetector(onTap: onTapToOrder, child: content);
  }
}

class _OrderMirror extends StatelessWidget {
  final String businessName;
  final List<Map<String, dynamic>> lines;
  final String total;

  const _OrderMirror({
    required this.businessName,
    required this.lines,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.colorScheme.primary,
            padding: const EdgeInsets.all(24),
            child: Text(
              businessName.isEmpty ? 'Your order' : businessName,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: lines.length,
              itemBuilder: (context, i) {
                final line = lines[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${line['qty']}×',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          line['name'] as String? ?? '',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        line['amount'] as String? ?? '',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.headlineMedium),
                Text(total, style: theme.textTheme.headlineMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
