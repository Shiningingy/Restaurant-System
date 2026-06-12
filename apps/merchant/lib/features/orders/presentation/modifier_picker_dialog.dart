import 'package:flutter/material.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Lets the server pick modifiers for an item, enforcing each group's
/// min/max selection. Returns the chosen modifiers, or null on cancel.
Future<List<domain.Modifier>?> showModifierPicker(
  BuildContext context, {
  required String itemName,
  required List<domain.ModifierGroup> groups,
}) {
  return showDialog<List<domain.Modifier>>(
    context: context,
    builder: (context) =>
        _ModifierPickerDialog(itemName: itemName, groups: groups),
  );
}

class _ModifierPickerDialog extends StatefulWidget {
  final String itemName;
  final List<domain.ModifierGroup> groups;

  const _ModifierPickerDialog({required this.itemName, required this.groups});

  @override
  State<_ModifierPickerDialog> createState() => _ModifierPickerDialogState();
}

class _ModifierPickerDialogState extends State<_ModifierPickerDialog> {
  final _selected = <String, List<domain.Modifier>>{};

  bool get _valid => widget.groups.every((g) {
    final n = (_selected[g.id] ?? const []).length;
    return n >= g.minSelect && n <= g.maxSelect;
  });

  void _toggle(domain.ModifierGroup group, domain.Modifier modifier) {
    setState(() {
      final list = _selected.putIfAbsent(group.id, () => []);
      if (list.any((m) => m.id == modifier.id)) {
        list.removeWhere((m) => m.id == modifier.id);
      } else if (group.maxSelect == 1) {
        // Single-choice groups behave like radio buttons.
        list
          ..clear()
          ..add(modifier);
      } else if (list.length < group.maxSelect) {
        list.add(modifier);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.itemName),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final group in widget.groups) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${group.name}  (${_requirementLabel(group)})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in group.modifiers)
                    FilterChip(
                      label: Text(
                        m.priceDelta.isZero
                            ? m.name
                            : '${m.name} (${m.priceDelta.isNegative ? '' : '+'}${m.priceDelta.format()})',
                      ),
                      selected: (_selected[group.id] ?? const []).any(
                        (s) => s.id == m.id,
                      ),
                      onSelected: (_) => _toggle(group, m),
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
              ? () => Navigator.pop(context, [
                  for (final list in _selected.values) ...list,
                ])
              : null,
          child: const Text('Add to order'),
        ),
      ],
    );
  }

  String _requirementLabel(domain.ModifierGroup g) {
    if (g.minSelect == 0) {
      return g.maxSelect == 1 ? 'optional' : 'up to ${g.maxSelect}';
    }
    if (g.minSelect == g.maxSelect) return 'pick ${g.minSelect}';
    return 'pick ${g.minSelect}–${g.maxSelect}';
  }
}
