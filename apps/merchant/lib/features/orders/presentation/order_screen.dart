import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../menu/application/providers.dart';
import '../application/providers.dart';
import 'modifier_picker_dialog.dart';

class OrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider(widget.orderId)).value;
    final lines =
        ref.watch(orderLinesProvider(widget.orderId)).value ?? const [];
    final isOpen = order?.status == domain.OrderStatus.open;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/orders')),
        title: Text(_title(order)),
        actions: [
          if (isOpen)
            TextButton.icon(
              onPressed: () => _voidOrder(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Void order'),
            ),
        ],
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _MenuPicker(
                    enabled: isOpen,
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: (id) =>
                        setState(() => _selectedCategoryId = id),
                    onItemTapped: _addItem,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: _Ticket(order: order, lines: lines, isOpen: isOpen),
                ),
              ],
            ),
    );
  }

  String _title(domain.Order? order) => switch (order?.type) {
    domain.OrderType.dineIn => 'Dine-in order',
    domain.OrderType.takeout => 'Takeout order',
    domain.OrderType.online => 'Online order',
    null => 'Order',
  };

  Future<void> _addItem(domain.MenuItem item) async {
    final menuRepo = ref.read(menuRepositoryProvider);
    final orderRepo = ref.read(orderRepositoryProvider);
    final groups = await menuRepo.getModifierGroupsForItem(item.id);

    var selected = const <domain.Modifier>[];
    if (groups.isNotEmpty) {
      if (!mounted) return;
      final picked = await showModifierPicker(
        context,
        itemName: item.name,
        groups: groups,
      );
      if (picked == null) return;
      selected = picked;
    }
    await orderRepo.addLine(
      orderId: widget.orderId,
      item: item,
      selectedModifiers: selected,
    );
  }

  Future<void> _voidOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void this order?'),
        content: const Text('The order is kept in history as voided.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Void order'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(orderRepositoryProvider).voidOrder(widget.orderId);
      if (context.mounted) context.go('/orders');
    }
  }
}

class _MenuPicker extends ConsumerWidget {
  final bool enabled;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<domain.MenuItem> onItemTapped;

  const _MenuPicker({
    required this.enabled,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => c.isActive)
        .toList();
    if (categories.isEmpty) {
      return const Center(
        child: Text('No menu yet - add categories and items in Menu.'),
      );
    }
    final activeCategoryId = selectedCategoryId ?? categories.first.id;
    final items =
        (ref.watch(itemsInCategoryProvider(activeCategoryId)).value ?? const [])
            .where((i) => i.isActive)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.name),
                    selected: c.id == activeCategoryId,
                    onSelected: (_) => onCategorySelected(c.id),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisExtent: 90,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                child: InkWell(
                  onTap: enabled ? () => onItemTapped(item) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item.price.format(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Ticket extends ConsumerWidget {
  final domain.Order order;
  final List<domain.OrderLine> lines;
  final bool isOpen;

  const _Ticket({
    required this.order,
    required this.lines,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(orderRepositoryProvider);
    final visibleLines = lines
        .where((l) => l.status == domain.OrderLineStatus.active)
        .toList();

    return Column(
      children: [
        Expanded(
          child: visibleLines.isEmpty
              ? const Center(child: Text('Tap menu items to add them.'))
              : ListView.builder(
                  itemCount: visibleLines.length,
                  itemBuilder: (context, i) {
                    final line = visibleLines[i];
                    return ListTile(
                      title: Text(line.nameSnapshot),
                      subtitle: line.modifiers.isEmpty
                          ? null
                          : Text(
                              line.modifiers
                                  .map((m) => m.nameSnapshot)
                                  .join(', '),
                            ),
                      leading: isOpen
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: line.qty == 1 ? 'Void line' : 'Decrease',
                              onPressed: () => line.qty == 1
                                  ? repo.voidLine(line.id)
                                  : repo.setLineQty(line.id, line.qty - 1),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('x${line.qty}'),
                          if (isOpen)
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  repo.setLineQty(line.id, line.qty + 1),
                            ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              line.lineTotal.format(),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _totalRow(context, 'Subtotal', order.subtotal),
              _totalRow(
                context,
                'Tax (${(order.taxRateBp / 100).toStringAsFixed(2)}%)',
                order.tax,
              ),
              const SizedBox(height: 4),
              _totalRow(context, 'Total', order.total, emphasized: true),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isOpen && visibleLines.isNotEmpty
                      ? () => _pay(context, ref)
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                  ),
                  child: Text(
                    isOpen ? 'Pay ${order.total.format()}' : 'Closed',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    domain.Money amount, {
    bool emphasized = false,
  }) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.format(), style: style),
      ],
    );
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final method = await showDialog<domain.PaymentMethod>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Collect ${order.total.format()}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, domain.PaymentMethod.cash),
            child: const ListTile(
              leading: Icon(Icons.payments_outlined),
              title: Text('Cash'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, domain.PaymentMethod.manual),
            child: const ListTile(
              leading: Icon(Icons.credit_card_outlined),
              title: Text('Card (keyed on terminal)'),
              subtitle: Text('Semi-integrated terminal arrives in Phase 3'),
            ),
          ),
        ],
      ),
    );
    if (method == null) return;
    await ref
        .read(orderRepositoryProvider)
        .closeOrder(orderId: order.id, method: method);
    if (context.mounted) context.go('/orders');
  }
}
