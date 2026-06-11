import 'package:flutter/material.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const _ScaffoldPlaceholder(),
    );
  }
}

/// Placeholder shell until Phase 1 lands the real order-taking UI.
/// Renders a Money value to prove the domain package is wired up.
class _ScaffoldPlaceholder extends StatelessWidget {
  const _ScaffoldPlaceholder();

  @override
  Widget build(BuildContext context) {
    final sample = const Money(1234) + const Money(66);
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant System — Merchant')),
      body: Center(
        child: Text(
          'Phase 0 scaffold OK — sample total: ${sample.format()}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
