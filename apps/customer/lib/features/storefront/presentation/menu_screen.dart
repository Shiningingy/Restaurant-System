import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/language_menu.dart';
import '../../../core/widgets/item_name.dart';
import '../../cart/cart.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../application/providers.dart';
import 'item_sheet.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final cart = ref.watch(cartProvider);
    final kiosk = ref.watch(kioskModeProvider);

    // Once the menu loads, learn the restaurant's name for the wallet if we
    // didn't get one at connect time (idempotent — no-op once set).
    ref.listen(menuProvider, (_, next) {
      final menu = next.value;
      if (menu != null) {
        ref
            .read(walletProvider.notifier)
            .backfillActiveName(menu.restaurantName);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(menuAsync.value?.restaurantName ?? context.l10n.menuTitle),
        actions: [
          // In kiosk mode the customer can't browse history or switch
          // restaurants; the app-bar back button returns to the attract screen.
          if (!kiosk) ...[
            IconButton(
              tooltip: context.l10n.ordersTitle,
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
              ),
            ),
            IconButton(
              tooltip: context.l10n.walletTitle,
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                ref.read(walletProvider.notifier).leave();
              },
            ),
          ],
          const LanguageMenu(),
          if (!kiosk)
            PopupMenuButton<String>(
              onSelected: (_) => _enterKiosk(context, ref),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'kiosk',
                  child: Text(context.l10n.kioskEnter),
                ),
              ],
            ),
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
                      isThreeLine:
                          item.description != null &&
                          item.description!.isNotEmpty,
                      title: _itemName(context, menu, item),
                      subtitle: _itemSubtitle(context, item),
                      trailing: Text(
                        item.price.format(),
                        style: moneyTextStyle(
                          Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
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

  /// Shows the item name, surfacing the second name as the primary line when
  /// the app's language matches the merchant-set second-name language.
  Widget _itemName(
    BuildContext context,
    domain.PublishedMenu menu,
    domain.PublishedItem item,
  ) {
    final lang = menu.secondNameLanguage;
    final second = item.nameSecondary;
    final swap =
        lang != null &&
        lang.isNotEmpty &&
        second != null &&
        second.isNotEmpty &&
        Localizations.localeOf(context).languageCode == lang;
    return ItemName(
      name: swap ? second : item.name,
      nameSecondary: swap ? item.name : second,
    );
  }

  /// The item's description (when present) plus an "options available" hint,
  /// or null when there's neither.
  Widget? _itemSubtitle(BuildContext context, domain.PublishedItem item) {
    final desc = item.description?.trim();
    final hasDesc = desc != null && desc.isNotEmpty;
    final hasOptions = item.modifierGroups.isNotEmpty;
    if (!hasDesc && !hasOptions) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDesc) Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (hasOptions)
          Text(
            context.l10n.menuOptionsAvailable,
            style: Theme.of(context).textTheme.labelSmall,
          ),
      ],
    );
  }

  /// Locks this device into kiosk mode for the connected restaurant.
  Future<void> _enterKiosk(BuildContext context, WidgetRef ref) async {
    final active = ref.read(walletProvider).active;
    if (active == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.kioskEnterTitle),
        content: Text(context.l10n.kioskEnterBody(active.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.kioskEnter),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(kioskModeProvider.notifier).enable(active.id);
    }
  }

  Future<void> _addItem(
    BuildContext context,
    WidgetRef ref,
    domain.PublishedItem item,
  ) async {
    final l10n = context.l10n;
    // Always open the detail sheet — description, options and quantity — even
    // for items with no options, so the customer can review before adding.
    final line = await showItemSheet(context, item);
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
