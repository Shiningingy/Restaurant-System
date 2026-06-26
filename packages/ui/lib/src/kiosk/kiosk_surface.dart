import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../brand_mark.dart';
import '../pos_theme.dart';
import 'kiosk_labels.dart';
import 'kiosk_menu.dart';

/// The interactive self-order surface — the customer browses the [menu], builds
/// a cart, and places the order through [onSubmit]. Shared by the merchant's
/// customer-display kiosk and the customer app's tablet kiosk so they look and
/// behave identically.
///
/// Owns no database and no providers: it renders the [menu] it's given and
/// returns the cart through [onSubmit]; the host decides what placing an order
/// means (register it locally, or submit a cloud preorder). All wording comes
/// from [labels] so the host controls localization.
class KioskSurface extends StatefulWidget {
  final String businessName;

  /// Logo for the terracotta header (dark slot) and the confirmation screen
  /// (wordmark slot). Null falls back to the generic brand glyph.
  final String? brandHeader;
  final String? brandConfirm;
  final KioskMenu? menu;

  /// All user-facing strings (so the same widget is English on the merchant
  /// display and localized in the customer app).
  final KioskLabels labels;

  /// Sends the built cart to the host; resolves with `{ok, code}` (or `{ok:
  /// false}` on failure). `code` (when present) is shown as the pickup number.
  final Future<Map<String, dynamic>> Function(List<KioskCartLine>) onSubmit;

  /// Asks the host to re-supply the menu (used while waiting for the first one).
  final Future<void> Function() onRefreshMenu;

  /// Leave the kiosk flow (back to the host's attract/promo screen). Null when
  /// there's nowhere to exit to.
  final VoidCallback? onExit;

  const KioskSurface({
    super.key,
    required this.businessName,
    required this.brandHeader,
    required this.brandConfirm,
    required this.menu,
    required this.labels,
    required this.onSubmit,
    required this.onRefreshMenu,
    this.onExit,
  });

  @override
  State<KioskSurface> createState() => _KioskSurfaceState();
}

enum _Stage { browse, review, confirm }

class _KioskSurfaceState extends State<KioskSurface> {
  final List<KioskCartLine> _cart = [];
  int _categoryIndex = 0;
  _Stage _stage = _Stage.browse;
  bool _submitting = false;
  String? _confirmCode;
  Timer? _resetTimer;

  KioskLabels get _l => widget.labels;

  int get _cartCount => _cart.fold(0, (s, l) => s + l.qty);
  int get _cartCents => _cart.fold(0, (s, l) => s + l.lineCents);

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _addToCart(KioskItem item, List<KioskModifier> modifiers, int qty) {
    final line = KioskCartLine(item: item, modifiers: modifiers, qty: qty);
    final existing = _cart
        .where((l) => l.signature == line.signature)
        .firstOrNull;
    setState(() {
      if (existing != null) {
        existing.qty += qty;
      } else {
        _cart.add(line);
      }
    });
  }

  /// Always opens the item popup (photo, options, quantity) — even for items
  /// with no options — so the customer reviews the dish before adding, matching
  /// the storefront menu.
  Future<void> _onItemTap(KioskItem item) async {
    final result = await showDialog<(List<KioskModifier>, int)>(
      context: context,
      builder: (_) => _ItemDialog(item: item, labels: _l),
    );
    if (result != null && mounted) _addToCart(item, result.$1, result.$2);
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final res = await widget.onSubmit(_cart);
    if (!mounted) return;
    if (res['ok'] == true) {
      setState(() {
        _submitting = false;
        _confirmCode = res['code'] as String?;
        _stage = _Stage.confirm;
      });
      // Auto-reset back to a fresh menu for the next customer.
      _resetTimer = Timer(const Duration(seconds: 9), _reset);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_l.submitFailed)));
    }
  }

  void _reset() {
    _resetTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _cart.clear();
      _confirmCode = null;
      _categoryIndex = 0;
      _stage = _Stage.browse;
    });
    // A dedicated kiosk returns to its menu; a hybrid session bows out.
    widget.onExit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    if (menu == null || menu.isEmpty) return _loading();
    return switch (_stage) {
      _Stage.browse => _browse(menu),
      _Stage.review => _review(),
      _Stage.confirm => _confirm(),
    };
  }

  Widget _loading() => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_l.loadingMenu),
          TextButton(onPressed: widget.onRefreshMenu, child: Text(_l.retry)),
          if (widget.onExit != null)
            TextButton(onPressed: widget.onExit, child: Text(_l.back)),
        ],
      ),
    ),
  );

  Widget _browse(KioskMenu menu) {
    final theme = Theme.of(context);
    final category =
        menu.categories[_categoryIndex.clamp(0, menu.categories.length - 1)];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header.
            Container(
              color: theme.colorScheme.primary,
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  BrandMark(
                    logoPath: widget.brandHeader,
                    size: 40,
                    fallbackColor: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.businessName.isEmpty
                          ? _l.headerFallbackTitle
                          : widget.businessName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  if (widget.onExit != null)
                    TextButton(
                      onPressed: widget.onExit,
                      child: Text(
                        _l.cancel,
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category rail.
                  SizedBox(
                    width: 180,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: menu.categories.length,
                      itemBuilder: (context, i) {
                        final c = menu.categories[i];
                        final selected = i == _categoryIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: selected
                              ? FilledButton(
                                  onPressed: () =>
                                      setState(() => _categoryIndex = i),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                  ),
                                  child: _railLabel(c.name),
                                )
                              : OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _categoryIndex = i),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                  ),
                                  child: _railLabel(c.name),
                                ),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _itemsGrid(category.items)),
                ],
              ),
            ),
            _cartBar(),
          ],
        ),
      ),
    );
  }

  Widget _railLabel(String name) => Align(
    alignment: Alignment.centerLeft,
    child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
  );

  Widget _itemsGrid(List<KioskItem> items) => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 240,
      mainAxisExtent: 232,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    ),
    itemCount: items.length,
    itemBuilder: (context, i) {
      final item = items[i];
      final theme = Theme.of(context);
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _onItemTap(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kioskPhoto(context, item.imageUrl, height: 124, iconSize: 32),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: item.nameSecondary == null ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            if (item.nameSecondary != null &&
                                item.nameSecondary!.isNotEmpty)
                              Text(
                                item.nameSecondary!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.price,
                            style: moneyTextStyle(theme.textTheme.titleMedium),
                          ),
                          Icon(
                            Icons.add_circle,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _cartBar() {
    final theme = Theme.of(context);
    final empty = _cart.isEmpty;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 28),
            const SizedBox(width: 12),
            Text(
              empty
                  ? _l.cartEmpty
                  : _l.cartSummary(_cartCount, formatCents(_cartCents)),
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: empty
                  ? null
                  : () => setState(() => _stage = _Stage.review),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 56)),
              icon: const Icon(Icons.arrow_forward),
              label: Text(_l.reviewOrder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _review() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_l.reviewTitle),
        leading: BackButton(
          onPressed: () => setState(() => _stage = _Stage.browse),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _cart.isEmpty
                  ? Center(child: Text(_l.cartEmpty))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cart.length,
                      itemBuilder: (context, i) => _cartTile(_cart[i]),
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _breakdown(),
                  const SizedBox(height: 16),
                  _paymentActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cart totals computed with the shared domain math (so they match the
  /// receipt to the cent): subtotal, optional service fee, tax, total.
  domain.OrderTotals _totals() {
    final lines = [
      for (final l in _cart)
        domain.OrderLine(
          id: '',
          orderId: '',
          menuItemId: l.item.id,
          nameSnapshot: l.item.name,
          priceSnapshot: domain.Money(l.unitCents),
          qty: l.qty,
          lineTotal: domain.Money(l.lineCents),
        ),
    ];
    return domain.OrderTotals.compute(
      lines: lines,
      taxRateBp: widget.menu?.taxRateBp ?? 0,
      serviceFeeBp: widget.menu?.serviceFeeBp ?? 0,
    );
  }

  static String _pct(int bp) => (bp / 100).toStringAsFixed(2);

  Widget _breakdown() {
    final theme = Theme.of(context);
    final t = _totals();
    final serviceFeeBp = widget.menu?.serviceFeeBp ?? 0;
    final taxBp = widget.menu?.taxRateBp ?? 0;
    Widget row(String label, domain.Money amount, {bool bold = false}) {
      final style = bold
          ? theme.textTheme.headlineSmall
          : theme.textTheme.titleMedium;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: style),
            Text(formatCents(amount.cents), style: moneyTextStyle(style)),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(_l.subtotal, t.subtotal),
        if (!t.serviceFee.isZero)
          row(_l.service(_pct(serviceFeeBp)), t.serviceFee),
        row(_l.tax(_pct(taxBp)), t.tax),
        const Divider(height: 16),
        row(_l.total, t.total, bold: true),
      ],
    );
  }

  Widget _paymentActions() {
    final addMore = OutlinedButton.icon(
      onPressed: () => setState(() => _stage = _Stage.browse),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
      icon: const Icon(Icons.add),
      label: Text(_l.addMore),
    );
    final canPlace = _cart.isNotEmpty && !_submitting;
    final payAtCounter = FilledButton.icon(
      onPressed: canPlace ? _placeOrder : null,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
      icon: _submitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.storefront),
      label: Text(_submitting ? _l.placing : _l.payAtCounter),
    );

    // Pay-here disabled by the owner: a single counter action.
    if (!(widget.menu?.payHere ?? false)) {
      return Row(
        children: [
          Expanded(child: addMore),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: payAtCounter),
        ],
      );
    }

    // Pay-here allowed: offer it next to pay-at-counter. Card-at-kiosk isn't
    // wired to a processor yet, so it's shown disabled ("coming soon").
    final payHere = OutlinedButton.icon(
      onPressed: null,
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
      icon: const Icon(Icons.credit_card),
      label: Text(_l.payHereSoon),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: payHere),
            const SizedBox(width: 12),
            Expanded(child: payAtCounter),
          ],
        ),
        const SizedBox(height: 8),
        addMore,
      ],
    );
  }

  Widget _cartTile(KioskCartLine line) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.item.name, style: theme.textTheme.titleMedium),
                  if (line.modifiers.isNotEmpty)
                    Text(
                      line.modifiers.map((m) => m.name).join(', '),
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(formatCents(line.lineCents)),
                ],
              ),
            ),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() {
                if (line.qty == 1) {
                  _cart.remove(line);
                } else {
                  line.qty -= 1;
                }
              }),
            ),
            Text('${line.qty}', style: theme.textTheme.titleLarge),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => line.qty += 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirm() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(
                logoPath: widget.brandConfirm,
                size: 96,
                fallbackColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.check_circle,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _l.orderPlaced,
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              if (_confirmCode != null) ...[
                const SizedBox(height: 16),
                Text(_l.yourNumber, style: theme.textTheme.titleMedium),
                Text(
                  _confirmCode!,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                _l.payAtCounterNote,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _reset,
                style: FilledButton.styleFrom(minimumSize: const Size(200, 60)),
                child: Text(_l.done),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded photo box for the kiosk — the card thumbnail and the popup banner.
/// Shows the item photo, or a camera-icon placeholder on a surface-variant tile
/// when there's none (or it fails to load), so the cards stay aligned in the
/// grid. [radius] 0 leaves square corners (the card already clips its own).
Widget _kioskPhoto(
  BuildContext context,
  String? url, {
  required double height,
  double iconSize = 40,
  double radius = 0,
}) {
  final cs = Theme.of(context).colorScheme;
  final placeholder = Center(
    child: Icon(
      Icons.photo_camera_outlined,
      size: iconSize,
      color: cs.onSurfaceVariant,
    ),
  );
  // The customer kiosk passes a network URL (menu-photos bucket); the merchant
  // display passes a local file path it reads on the same machine.
  final Widget image;
  if (url == null) {
    image = placeholder;
  } else if (url.startsWith('http')) {
    image = Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (c, child, p) =>
          p == null ? child : const Center(child: CircularProgressIndicator()),
    );
  } else {
    image = Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
  final box = SizedBox(
    height: height,
    width: double.infinity,
    child: ColoredBox(color: cs.surfaceContainerHighest, child: image),
  );
  return radius == 0
      ? box
      : ClipRRect(borderRadius: BorderRadius.circular(radius), child: box);
}

/// The item popup: a centered dialog with a photo banner, options as big touch
/// targets, a quantity stepper and the running total on the add button.
/// Single-select required groups pre-select their first option. Returns the
/// chosen `(modifiers, quantity)`, or null if dismissed.
class _ItemDialog extends StatefulWidget {
  final KioskItem item;
  final KioskLabels labels;

  const _ItemDialog({required this.item, required this.labels});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  /// groupId -> selected modifier ids.
  final Map<String, Set<String>> _selected = {};
  int _qty = 1;

  KioskLabels get _l => widget.labels;

  @override
  void initState() {
    super.initState();
    for (final g in widget.item.modifierGroups) {
      if (g.isSingleChoice && g.isRequired && g.modifiers.isNotEmpty) {
        _selected[g.id] = {g.modifiers.first.id};
      } else {
        _selected[g.id] = {};
      }
    }
  }

  bool get _satisfied => widget.item.modifierGroups.every(
    (g) => (_selected[g.id]?.length ?? 0) >= g.minSelect,
  );

  int get _extraCents {
    var cents = 0;
    for (final g in widget.item.modifierGroups) {
      for (final m in g.modifiers) {
        if (_selected[g.id]?.contains(m.id) ?? false) cents += m.deltaCents;
      }
    }
    return cents;
  }

  int get _totalCents => (widget.item.priceCents + _extraCents) * _qty;

  List<KioskModifier> get _chosen => [
    for (final g in widget.item.modifierGroups)
      for (final m in g.modifiers)
        if (_selected[g.id]?.contains(m.id) ?? false) m,
  ];

  void _toggle(KioskModifierGroup g, KioskModifier m) {
    setState(() {
      final set = _selected[g.id] ??= {};
      if (g.isSingleChoice) {
        set
          ..clear()
          ..add(m.id);
      } else {
        if (set.contains(m.id)) {
          set.remove(m.id);
        } else if (g.maxSelect == 0 || set.length < g.maxSelect) {
          set.add(m.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final item = widget.item;
    final desc = item.description?.trim();
    final hasSecond =
        item.nameSecondary != null && item.nameSecondary!.isNotEmpty;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _kioskPhoto(
                      context,
                      item.imageUrl,
                      height: 200,
                      iconSize: 52,
                      radius: 12,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: theme.textTheme.headlineSmall),
                        if (hasSecond)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.nameSecondary!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (desc != null && desc.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            desc,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  for (final g in widget.item.modifierGroups)
                    ..._group(theme, g),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    iconSize: 28,
                    onPressed: _qty == 1 ? null : () => setState(() => _qty--),
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$_qty', style: theme.textTheme.headlineSmall),
                  ),
                  IconButton.filledTonal(
                    iconSize: 28,
                    onPressed: () => setState(() => _qty++),
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _satisfied
                          ? () => Navigator.pop(context, (_chosen, _qty))
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: Text(_l.addToOrderTotal(formatCents(_totalCents))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _group(ThemeData theme, KioskModifierGroup g) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        g.isRequired ? '${g.name} *' : g.name,
        style: theme.textTheme.titleMedium,
      ),
    ),
    for (final m in g.modifiers)
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: _optionButton(theme, g, m),
      ),
  ];

  Widget _optionButton(ThemeData theme, KioskModifierGroup g, KioskModifier m) {
    final cs = theme.colorScheme;
    final on = _selected[g.id]?.contains(m.id) ?? false;
    final icon = g.isSingleChoice
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
              if (m.deltaCents != 0)
                Text('+${m.delta}', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
