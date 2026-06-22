import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_ui/restaurant_ui.dart';

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
      theme: buildPosTheme(),
      home: CustomerDisplayScreen(
        businessName: args['businessName'] as String? ?? '',
        brandLogo: args['brandLogo'] as String?,
        promoLines:
            (args['promo'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        promoImages:
            (args['promoImages'] as List?)?.map((e) => e.toString()).toList() ??
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
  final String? brandLogo;
  final List<String> promoLines;
  final List<String> promoImages;
  final CustomerDisplayMode mode;

  const CustomerDisplayScreen({
    super.key,
    required this.businessName,
    required this.brandLogo,
    required this.promoLines,
    required this.promoImages,
    required this.mode,
  });

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  final _channel = WindowMethodChannel(kCustomerDisplayChannel);

  late CustomerDisplayMode _mode = widget.mode;
  late String _businessName = widget.businessName;
  // Promo is mutable so the POS can update it live (owner edits in Settings)
  // without the customer having to reopen the display window.
  late List<String> _promoLines = widget.promoLines;
  late List<String> _promoImages = widget.promoImages;
  Map<String, dynamic>? _order;
  KioskMenu? _menu;

  /// Hybrid only: the customer tapped "order" on the promo screen and is in the
  /// kiosk flow. Reset when the cashier starts ringing an order.
  bool _hybridKiosk = false;

  Timer? _promoTimer;
  int _promoIndex = 0;
  int _photoIndex = 0;

  bool get _interactive =>
      _mode == CustomerDisplayMode.kiosk ||
      (_mode == CustomerDisplayMode.hybrid && _hybridKiosk);

  @override
  void initState() {
    super.initState();
    _connect();
    _restartPromoTimer();
  }

  /// (Re)starts the idle rotation for the current promo set. Cancels any
  /// existing timer first, so a live promo update swaps cleanly.
  void _restartPromoTimer() {
    _promoTimer?.cancel();
    _promoTimer = null;
    // Only rotate if there's more than one thing to cycle through.
    if (_promoLines.length > 1 || _promoImages.length > 1) {
      _promoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted && !_interactive) {
          setState(() {
            if (_promoLines.isNotEmpty) {
              _promoIndex = (_promoIndex + 1) % _promoLines.length;
            }
            if (_promoImages.isNotEmpty) {
              _photoIndex = (_photoIndex + 1) % _promoImages.length;
            }
          });
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

  /// Connects the window channel, retrying until the sub-window's native
  /// plugins are up.
  ///
  /// This engine's `main()` starts *before* the desktop_multi_window plugin (and
  /// its window-channel plugin) is registered for this window — that happens in
  /// the native window-created callback a moment later. So the very first
  /// `setMethodCallHandler` can throw `MissingPluginException`. We retry until it
  /// sticks, then pull the menu. Without this the handler never registers and the
  /// screen stays static (no order mirror, no menu, no "tap to order").
  Future<void> _connect() async {
    for (var attempt = 0; attempt < 40 && mounted; attempt++) {
      try {
        await _channel.setMethodCallHandler(_handleFromPos);
        await _requestMenu();
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
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
      case 'promo':
        final data = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        final lines =
            (data['promo'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
        final imgs =
            (data['promoImages'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
        if (mounted) {
          setState(() {
            _promoLines = lines;
            _promoImages = imgs;
            _promoIndex = 0;
            _photoIndex = 0;
          });
          _restartPromoTimer();
        }
    }
    return null;
  }

  Future<void> _requestMenu() async {
    // Retry a few times: right after launch the POS handler may not be paired
    // on the channel yet, and the menu can also be empty until the POS is ready.
    for (var attempt = 0; attempt < 8 && mounted && _menu == null; attempt++) {
      try {
        final json = await _channel.invokeMethod<String>('requestMenu');
        if (json != null && json.isNotEmpty) {
          _applyMenu(json);
          return;
        }
      } catch (_) {
        // Not paired/ready yet — fall through to a short wait and retry.
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
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
        brandLogo: widget.brandLogo,
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
          brandLogo: widget.brandLogo,
          lines: lines.cast<Map<String, dynamic>>(),
          order: order!,
        ),
      );
    }
    return Scaffold(
      body: _IdlePromo(
        businessName: _businessName,
        brandLogo: widget.brandLogo,
        promo: _promoLines.isEmpty
            ? null
            : _promoLines[_promoIndex % _promoLines.length],
        photo: _promoImages.isEmpty
            ? null
            : _promoImages[_photoIndex % _promoImages.length],
        // Hybrid invites the customer to order; passive is view-only. Kept
        // gated on a loaded menu on purpose: if the menu failed to load the
        // missing button is a visible signal that something's wrong (the menu
        // load itself now awaits channel pairing + retries, so this should only
        // stay hidden on a real fault).
        onTapToOrder: _mode == CustomerDisplayMode.hybrid && _menu != null
            ? () => setState(() => _hybridKiosk = true)
            : null,
      ),
    );
  }
}

/// The idle / promo screen. When promo photos are configured they play as a
/// full-bleed cross-fading slideshow with the business name + rotating promo
/// line overlaid; otherwise it's a plain branded card. A "tap to order" call to
/// action is added in hybrid mode.
class _IdlePromo extends StatelessWidget {
  final String businessName;
  final String? brandLogo;
  final String? promo;
  final String? photo;
  final VoidCallback? onTapToOrder;

  const _IdlePromo({
    required this.businessName,
    required this.brandLogo,
    required this.promo,
    required this.photo,
    this.onTapToOrder,
  });

  @override
  Widget build(BuildContext context) {
    final content = (photo != null && photo!.isNotEmpty)
        ? _slideshow(context)
        : _branded(context);
    if (onTapToOrder == null) return content;
    // A small "Tap to order" pill in the bottom-right corner — the promo stays
    // the focus; ordering is a discreet call to action (matches the mockup).
    return Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(right: 24, bottom: 24, child: _tapToOrderButton(context)),
      ],
    );
  }

  /// Photo slideshow: the current image fills the screen (cross-fading on
  /// change) with a dark gradient and the business name + promo overlaid.
  Widget _slideshow(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Image.file(
            File(photo!),
            key: ValueKey(photo),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: Colors.black),
          ),
        ),
        // Legibility scrim behind the overlaid text.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (businessName.isNotEmpty)
                  Text(
                    businessName,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (promo != null && promo!.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      promo!,
                      key: ValueKey(promo),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _branded(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(
            logoPath: brandLogo,
            size: 140,
            fallbackColor: theme.colorScheme.onPrimaryContainer,
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
        ],
      ),
    );
  }

  /// A compact ordering CTA — sits in the bottom-right corner over the promo,
  /// not a full-screen target.
  Widget _tapToOrderButton(BuildContext context) => FilledButton.icon(
    onPressed: onTapToOrder,
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: Theme.of(context).textTheme.titleMedium,
    ),
    icon: const Icon(Icons.touch_app, size: 20),
    label: const Text('Tap to order'),
  );
}

class _OrderMirror extends StatelessWidget {
  final String businessName;
  final String? brandLogo;
  final List<Map<String, dynamic>> lines;
  final Map<String, dynamic> order;

  const _OrderMirror({
    required this.businessName,
    required this.brandLogo,
    required this.lines,
    required this.order,
  });

  String _pct(num bp) => (bp / 100).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = order['subtotal'] as String?;
    final discount = order['discount'] as String?;
    final serviceFee = order['serviceFee'] as String?;
    final serviceFeeBp = (order['serviceFeeBp'] as num?) ?? 0;
    final tax = order['tax'] as String?;
    final taxRateBp = (order['taxRateBp'] as num?) ?? 0;
    final total = order['total'] as String? ?? '';
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.colorScheme.primary,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                BrandMark(
                  logoPath: brandLogo,
                  size: 44,
                  fallbackColor: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    businessName.isEmpty ? 'Your order' : businessName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
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
          // The same breakdown the cashier sees, so the customer can follow how
          // the total is reached (subtotal, discount, service fee, tax).
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                if (subtotal != null) _row(theme, 'Subtotal', subtotal),
                if (discount != null) _row(theme, 'Discount', discount),
                if (serviceFee != null)
                  _row(theme, 'Service (${_pct(serviceFeeBp)}%)', serviceFee),
                if (tax != null) _row(theme, 'Tax (${_pct(taxRateBp)}%)', tax),
                const Divider(height: 20),
                _row(theme, 'Total', total, emphasized: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String amount, {
    bool emphasized = false,
  }) {
    final style = emphasized
        ? theme.textTheme.headlineMedium
        : theme.textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(amount, style: style),
        ],
      ),
    );
  }
}
