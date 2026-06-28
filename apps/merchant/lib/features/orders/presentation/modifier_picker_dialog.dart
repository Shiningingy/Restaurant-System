import 'package:flutter/material.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';

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
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                child: Text(
                  '${group.name}  (${_requirementLabel(context, group)})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (final m in group.modifiers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _optionButton(group, m),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.pop(context, [
                  for (final list in _selected.values) ...list,
                ])
              : null,
          child: Text(context.l10n.modAddToOrder),
        ),
      ],
    );
  }

  /// A full-width option row (matching the kiosk/customer popups): a tonal tile
  /// that fills with the secondary colour when selected, a radio/check leading
  /// icon, the name, and the price delta.
  Widget _optionButton(domain.ModifierGroup g, domain.Modifier m) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final on = (_selected[g.id] ?? const []).any((s) => s.id == m.id);
    final single = g.maxSelect == 1;
    final icon = single
        ? (on ? Icons.radio_button_checked : Icons.radio_button_unchecked)
        : (on ? Icons.check_box : Icons.check_box_outline_blank);
    return Material(
      color: on ? cs.secondaryContainer : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggle(g, m),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: on ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(m.name, style: theme.textTheme.titleSmall)),
              if (!m.priceDelta.isZero)
                Text(
                  '${m.priceDelta.isNegative ? '' : '+'}${m.priceDelta.format()}',
                  style: theme.textTheme.bodyLarge,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _requirementLabel(BuildContext context, domain.ModifierGroup g) {
    if (g.minSelect == 0) {
      return g.maxSelect == 1
          ? context.l10n.modOptional
          : context.l10n.modUpTo(g.maxSelect);
    }
    if (g.minSelect == g.maxSelect) return context.l10n.modPick(g.minSelect);
    return context.l10n.modPickRange(g.minSelect, g.maxSelect);
  }
}
