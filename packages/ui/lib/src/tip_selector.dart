import 'package:flutter/material.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// A customer-facing tip picker for the kiosk / online checkout: a row of
/// preset buttons (a `0` preset shows as [noTipLabel], others as "N%" with the
/// computed dollar amount) plus a "Custom" field for an exact amount.
///
/// Tip percentages apply to [subtotal] (pre-tax). The host owns the current
/// [tip] and is told of changes through [onChanged]; all wording is passed in
/// so both the kiosk (its own labels) and the customer app (l10n) can use it.
class TipSelector extends StatefulWidget {
  /// Suggested tip percentages in basis points (e.g. 1500 = 15%); a 0 entry is
  /// the "No tip" button.
  final List<int> presetsBp;

  /// The pre-tax subtotal the percentages apply to.
  final domain.Money subtotal;

  /// The currently-chosen tip (host-owned).
  final domain.Money tip;
  final ValueChanged<domain.Money> onChanged;

  final String title;
  final String noTipLabel;
  final String customLabel;
  final String customHint;

  const TipSelector({
    super.key,
    required this.presetsBp,
    required this.subtotal,
    required this.tip,
    required this.onChanged,
    required this.title,
    required this.noTipLabel,
    required this.customLabel,
    required this.customHint,
  });

  @override
  State<TipSelector> createState() => _TipSelectorState();
}

class _TipSelectorState extends State<TipSelector> {
  late final TextEditingController _custom;
  bool _customMode = false;

  @override
  void initState() {
    super.initState();
    _custom = TextEditingController(
      text: widget.tip.isZero
          ? ''
          : (widget.tip.cents / 100).toStringAsFixed(2),
    );
    // Start in custom mode if the initial tip matches no preset.
    _customMode = widget.tip.cents > 0 && !_matchesAnyPreset(widget.tip);
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  domain.Money _presetTip(int bp) => widget.subtotal.percent(bp / 100);

  bool _matchesAnyPreset(domain.Money tip) =>
      widget.presetsBp.any((bp) => _presetTip(bp) == tip);

  void _pickPreset(int bp) {
    setState(() => _customMode = false);
    widget.onChanged(_presetTip(bp));
  }

  void _pickCustom() {
    setState(() => _customMode = true);
    widget.onChanged(domain.Money.tryParse(_custom.text) ?? domain.Money.zero);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final bp in widget.presetsBp)
              _TipChip(
                label: bp == 0 ? widget.noTipLabel : '${bp ~/ 100}%',
                sub: bp == 0 ? null : _presetTip(bp).format(),
                selected: !_customMode && widget.tip == _presetTip(bp),
                onTap: () => _pickPreset(bp),
              ),
            _TipChip(
              label: widget.customLabel,
              sub: _customMode && !widget.tip.isZero
                  ? widget.tip.format()
                  : null,
              selected: _customMode,
              onTap: _pickCustom,
            ),
          ],
        ),
        if (_customMode) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _custom,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: r'$ ',
              hintText: widget.customHint,
            ),
            onChanged: (_) => widget.onChanged(
              domain.Money.tryParse(_custom.text) ?? domain.Money.zero,
            ),
          ),
        ],
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;

  const _TipChip({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimary : cs.onSurface;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 84, minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: fg),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
