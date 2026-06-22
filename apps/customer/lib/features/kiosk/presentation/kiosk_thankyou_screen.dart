import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';

/// Kiosk order confirmation. Shown after a customer places an order; auto-resets
/// back to the attract screen (the first route) after a few seconds so the next
/// customer starts fresh, with a "start new order" button to skip the wait.
class KioskThankYouScreen extends StatefulWidget {
  const KioskThankYouScreen({super.key});

  @override
  State<KioskThankYouScreen> createState() => _KioskThankYouScreenState();
}

class _KioskThankYouScreenState extends State<KioskThankYouScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 6), _reset);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 112, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                context.l10n.kioskThankYou,
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.kioskThankYouBody,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _reset,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  textStyle: theme.textTheme.titleLarge,
                ),
                child: Text(context.l10n.kioskStartNewOrder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
