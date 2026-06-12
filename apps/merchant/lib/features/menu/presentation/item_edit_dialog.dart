import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../application/providers.dart';

Future<void> showItemEditDialog(
  BuildContext context,
  WidgetRef ref, {
  required String categoryId,
  String? itemId,
}) async {
  final repo = ref.read(menuRepositoryProvider);
  final existing = itemId == null ? null : await repo.getItem(itemId);
  final allGroups = ref.read(modifierGroupsProvider).value ?? const [];
  if (!context.mounted) return;

  final result = await showDialog<domain.MenuItem>(
    context: context,
    builder: (context) => _ItemEditDialog(
      categoryId: categoryId,
      existing: existing,
      allGroups: allGroups,
    ),
  );
  if (result != null) {
    await repo.upsertItem(result);
  }
}

class _ItemEditDialog extends StatefulWidget {
  final String categoryId;
  final domain.MenuItem? existing;
  final List<domain.ModifierGroup> allGroups;

  const _ItemEditDialog({
    required this.categoryId,
    required this.existing,
    required this.allGroups,
  });

  @override
  State<_ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<_ItemEditDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.price.cents / 100).toStringAsFixed(2),
  );
  late bool _isActive = widget.existing?.isActive ?? true;
  late final Set<String> _groupIds = {...?widget.existing?.modifierGroupIds};

  domain.Money? get _parsedPrice => domain.Money.tryParse(_price.text);

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _parsedPrice != null &&
      !_parsedPrice!.isNegative;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New item' : 'Edit item'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: r'$',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible on order screen'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            if (widget.allGroups.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Modifier groups',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in widget.allGroups)
                    FilterChip(
                      label: Text(g.name),
                      selected: _groupIds.contains(g.id),
                      onSelected: (sel) => setState(
                        () =>
                            sel ? _groupIds.add(g.id) : _groupIds.remove(g.id),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.pop(
                  context,
                  domain.MenuItem(
                    id: widget.existing?.id ?? domain.newId(),
                    categoryId: widget.categoryId,
                    name: _name.text.trim(),
                    price: _parsedPrice!,
                    sortOrder: widget.existing?.sortOrder ?? 0,
                    isActive: _isActive,
                    modifierGroupIds: _groupIds.toList(),
                  ),
                )
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }
}
