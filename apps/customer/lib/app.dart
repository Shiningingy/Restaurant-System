import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/storefront/application/providers.dart';
import 'features/storefront/presentation/connect_screen.dart';
import 'features/storefront/presentation/menu_screen.dart';

class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Preorder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const _HomeGate(),
    );
  }
}

/// Shows the connect screen until a storefront is configured, then the
/// menu.
class _HomeGate extends ConsumerWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(storefrontConfigProvider).isConnected;
    return connected ? const MenuScreen() : const ConnectScreen();
  }
}
