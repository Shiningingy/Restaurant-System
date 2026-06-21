import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

/// Root of the customer-facing display sub-window (runs in its own engine on
/// the extended monitor). It owns no database; the POS window pushes it order
/// snapshots and the active mode over the multi-window method channel.
class CustomerDisplayApp extends StatelessWidget {
  final WindowController windowController;
  final Map<String, dynamic> args;

  const CustomerDisplayApp({
    super.key,
    required this.windowController,
    required this.args,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: CustomerDisplayScreen(
        windowController: windowController,
        businessName: args['businessName'] as String? ?? '',
        promoLines:
            (args['promo'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      ),
    );
  }
}

/// Two modes for now: a welcome/promo screen when idle, and a live mirror of
/// the order the cashier is ringing up. The POS pushes updates via
/// `DesktopMultiWindow.invokeMethod(windowId, 'order', json)`.
class CustomerDisplayScreen extends StatefulWidget {
  final WindowController windowController;
  final String businessName;
  final List<String> promoLines;

  const CustomerDisplayScreen({
    super.key,
    required this.windowController,
    required this.businessName,
    this.promoLines = const [],
  });

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  Map<String, dynamic>? _order;
  Timer? _promoTimer;
  int _promoIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.windowController.setWindowMethodHandler((call) async {
      if (call.method == 'order') {
        final raw = call.arguments as String?;
        if (mounted) {
          setState(() {
            _order = (raw == null || raw.isEmpty)
                ? null
                : jsonDecode(raw) as Map<String, dynamic>;
          });
        }
      }
      return null;
    });
    // Rotate promo lines while idle.
    if (widget.promoLines.length > 1) {
      _promoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final lines = (order?['lines'] as List?) ?? const [];
    final hasOrder = lines.isNotEmpty;
    // Idle: passive promo. Order active: live mirror. (Auto-switch.)
    return Scaffold(
      body: hasOrder
          ? _OrderMirror(
              businessName: widget.businessName,
              lines: lines.cast<Map<String, dynamic>>(),
              total: order?['total'] as String? ?? '',
            )
          : _IdlePromo(
              businessName: widget.businessName,
              promo: widget.promoLines.isEmpty
                  ? null
                  : widget.promoLines[_promoIndex % widget.promoLines.length],
            ),
    );
  }
}

/// The idle / promo screen: business name with a rotating promo line beneath.
class _IdlePromo extends StatelessWidget {
  final String businessName;
  final String? promo;

  const _IdlePromo({required this.businessName, required this.promo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
        ],
      ),
    );
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
