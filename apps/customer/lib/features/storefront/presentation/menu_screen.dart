import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../../core/language_menu.dart';
import '../../../core/widgets/item_name.dart';
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
        title: Text(menuAsync.value?.restaurantName ?? context.l10n.menuTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.walletTitle,
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              ref.read(walletProvider.notifier).leave();
            },
          ),
          const LanguageMenu(),
        ],
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.menuLoadError(e.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (menu) {
          if (menu == null || menu.categories.isEmpty) {
            return Center(child: Text(context.l10n.menuEmpty));
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
                      title: ItemName(
                        name: item.name,
                        nameSecondary: item.nameSecondary,
                      ),
                      subtitle: item.modifierGroups.isEmpty
                          ? null
                          : Text(context.l10n.menuOptionsAvailable),
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
                    context.l10n.menuViewCart(
                      cart.itemCount,
                      cart.total.format(),
                    ),
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
    final l10n = context.l10n;
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
          content: Text(l10n.menuItemAdded(line.item.name)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
