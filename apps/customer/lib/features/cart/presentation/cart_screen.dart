import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_ui/restaurant_ui.dart';

import '../../../core/l10n_ext.dart';
import '../cart.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cartTitle)),
      body: cart.isEmpty
          ? Center(child: Text(context.l10n.cartEmpty))
          : ListView(
              children: [
                for (var i = 0; i < cart.lines.length; i++)
                  _CartLineTile(
                    line: cart.lines[i],
                    onDecrement: () =>
                        notifier.setQty(i, cart.lines[i].qty - 1),
                    onIncrement: () =>
                        notifier.setQty(i, cart.lines[i].qty + 1),
                    onRemove: () => notifier.removeAt(i),
                  ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.cartTotal,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          cart.total.format(),
                          style: moneyTextStyle(
                            Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        ),
                        child: Text(context.l10n.cartCheckout),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  final CartLine line;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  const _CartLineTile({
    required this.line,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(line.item.name),
      subtitle: line.modifiers.isEmpty
          ? null
          : Text(line.modifiers.map((m) => m.name).join(', ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onDecrement,
          ),
          Text('${line.qty}'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onIncrement,
          ),
          SizedBox(
            width: 72,
            child: Text(
              line.lineTotal.format(),
              textAlign: TextAlign.right,
              style: moneyTextStyle(Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
