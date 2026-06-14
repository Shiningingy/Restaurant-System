import 'package:flutter/material.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../cart/cart.dart';

/// Lets the customer pick modifiers and a quantity for an item with
/// options. Single-select groups (maxSelect == 1) use radios, others
/// checkboxes. Returns the resulting [CartLine], or null if cancelled.
Future<CartLine?> showItemSheet(
  BuildContext context,
  domain.PublishedItem item,
) {
  return showModalBottomSheet<CartLine>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ItemSheet(item: item),
  );
}

class _ItemSheet extends StatefulWidget {
  final domain.PublishedItem item;

  const _ItemSheet({required this.item});

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final Set<String> _selected = {};
  int _qty = 1;

  bool _isSelected(domain.PublishedModifier m) => _selected.contains(m.id);

  void _toggleSingle(
    domain.PublishedModifierGroup g,
    domain.PublishedModifier m,
  ) {
    setState(() {
      for (final other in g.modifiers) {
        _selected.remove(other.id);
      }
      _selected.add(m.id);
    });
  }

  void _toggleMulti(domain.PublishedModifier m) {
    setState(() {
      if (!_selected.remove(m.id)) _selected.add(m.id);
    });
  }

  List<domain.PublishedModifier> get _chosen => [
    for (final g in widget.item.modifierGroups)
      ...g.modifiers.where(_isSelected),
  ];

  domain.Money get _unit =>
      _chosen.fold(widget.item.price, (sum, m) => sum + m.priceDelta);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final g in widget.item.modifierGroups) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        g.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    for (final m in g.modifiers)
                      CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _isSelected(m),
                        title: Text(m.name),
                        secondary: m.priceDelta.isZero
                            ? null
                            : Text(
                                context.l10n.itemPriceDelta(
                                  m.priceDelta.format(),
                                ),
                              ),
                        onChanged: (_) => g.maxSelect == 1
                            ? _toggleSingle(g, m)
                            : _toggleMulti(m),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _qty == 1 ? null : () => setState(() => _qty--),
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$_qty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _qty++),
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    CartLine(item: widget.item, modifiers: _chosen, qty: _qty),
                  ),
                  child: Text(context.l10n.itemAdd((_unit * _qty).format())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
