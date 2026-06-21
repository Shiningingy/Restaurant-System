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

  const CustomerDisplayScreen({
    super.key,
    required this.windowController,
    required this.businessName,
  });

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  Map<String, dynamic>? _order;

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
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final lines = (order?['lines'] as List?) ?? const [];
    final hasOrder = lines.isNotEmpty;
    final theme = Theme.of(context);
    return Scaffold(
      body: hasOrder
          ? _OrderMirror(
              businessName: widget.businessName,
              lines: lines.cast<Map<String, dynamic>>(),
              total: order?['total'] as String? ?? '',
            )
          : Container(
              color: theme.colorScheme.primaryContainer,
              alignment: Alignment.center,
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
                    widget.businessName.isEmpty
                        ? 'Welcome'
                        : widget.businessName,
                    style: theme.textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
