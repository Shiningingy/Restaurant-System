import 'package:flutter/material.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/item_name.dart';
import '../../cart/cart.dart';

/// Item detail popup: a photo (when the item has one), name + description,
/// add-ons, a quantity stepper and add-to-cart. Single-select groups
/// (maxSelect == 1) use radios, others checkboxes. Returns the resulting
/// [CartLine], or null if cancelled. [imageUrl] is the item's public photo URL
/// (null skips the photo section — no placeholder).
Future<CartLine?> showItemSheet(
  BuildContext context,
  domain.PublishedItem item, {
  String? imageUrl,
}) {
  return showModalBottomSheet<CartLine>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ItemSheet(item: item, imageUrl: imageUrl),
  );
}

class _ItemSheet extends StatefulWidget {
  final domain.PublishedItem item;
  final String? imageUrl;

  const _ItemSheet({required this.item, this.imageUrl});

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final Set<String> _selected = {};
  int _qty = 1;

  bool _isSelected(domain.PublishedModifier m) => _selected.contains(m.id);

  /// The chosen modifier id within a single-select group (for the radios).
  String? _selectedIn(domain.PublishedModifierGroup g) {
    for (final m in g.modifiers) {
      if (_selected.contains(m.id)) return m.id;
    }
    return null;
  }

  void _pickSingle(
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
    final theme = Theme.of(context);
    final desc = widget.item.description?.trim();
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                if (widget.imageUrl != null) _photo(widget.imageUrl!),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ItemName(
                        name: widget.item.name,
                        nameSecondary: widget.item.nameSecondary,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.price.format(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (desc != null && desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(desc, style: theme.textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                for (final g in widget.item.modifierGroups)
                  ..._group(context, g),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _qty == 1 ? null : () => setState(() => _qty--),
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$_qty', style: theme.textTheme.titleMedium),
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
          ),
        ],
      ),
    );
  }

  /// The item photo, full-bleed at the top. A broken/missing image just
  /// collapses (no placeholder, per the no-placeholder rule).
  Widget _photo(String url) => Image.network(
    url,
    height: 200,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
  );

  List<Widget> _group(BuildContext context, domain.PublishedModifierGroup g) {
    final single = g.maxSelect == 1;
    final selectedId = single ? _selectedIn(g) : null;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(g.name, style: Theme.of(context).textTheme.titleSmall),
      ),
      for (final m in g.modifiers)
        if (single)
          RadioListTile<String>(
            dense: true,
            value: m.id,
            // ignore: deprecated_member_use
            groupValue: selectedId,
            // ignore: deprecated_member_use
            onChanged: (_) => _pickSingle(g, m),
            title: Text(m.name),
            secondary: _delta(context, m),
          )
        else
          CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: _isSelected(m),
            onChanged: (_) => _toggleMulti(m),
            title: Text(m.name),
            secondary: _delta(context, m),
          ),
    ];
  }

  Widget? _delta(BuildContext context, domain.PublishedModifier m) =>
      m.priceDelta.isZero
      ? null
      : Text(context.l10n.itemPriceDelta(m.priceDelta.format()));
}
