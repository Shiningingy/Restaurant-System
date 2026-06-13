import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../cart/cart.dart';
import '../../cart/presentation/cart_screen.dart';
import '../application/providers.dart';
import 'item_sheet.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(menuAsync.value?.restaurantName ?? 'Menu'),
        actions: [
          IconButton(
            tooltip: 'Disconnect',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(storefrontConfigProvider.notifier).disconnect(),
          ),
        ],
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Couldn't load the menu.\n$e",
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (menu) {
          if (menu == null || menu.categories.isEmpty) {
            return const Center(
              child: Text('This restaurant has no menu published yet.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(menuProvider),
            child: ListView(
              children: [
                for (final category in menu.categories) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  for (final item in category.items)
                    ListTile(
                      title: Text(item.name),
                      subtitle: item.modifierGroups.isEmpty
                          ? null
                          : const Text('Options available'),
                      trailing: Text(item.price.format()),
                      onTap: () => _addItem(context, ref, item),
                    ),
                ],
                const SizedBox(height: 88),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                  ),
                  child: Text(
                    'View cart (${cart.itemCount}) - ${cart.total.format()}',
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _addItem(
    BuildContext context,
    WidgetRef ref,
    domain.PublishedItem item,
  ) async {
    final CartLine? line;
    if (item.modifierGroups.isEmpty) {
      line = CartLine(item: item);
    } else {
      line = await showItemSheet(context, item);
    }
    if (line == null) return;
    ref.read(cartProvider.notifier).add(line);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${line.item.name}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
