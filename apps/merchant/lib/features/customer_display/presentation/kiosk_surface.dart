import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

import 'kiosk_menu.dart';

/// The interactive self-order surface shown in the customer-display window when
/// it's in kiosk (or hybrid-tapped) mode. The customer browses the menu, builds
/// a cart, and places the order — which is sent back to the POS to register.
///
/// Owns no database: it renders the [menu] the POS pushed and returns the cart
/// through [onSubmit]. Everything is local to the one machine — fully offline.
class KioskSurface extends StatefulWidget {
  final String businessName;
  final KioskMenu? menu;

  /// Sends the built cart to the POS; resolves with `{ok, code}` (or `{ok:
  /// false}` on failure). The POS creates the real order on its DB connection.
  final Future<Map<String, dynamic>> Function(List<CartLine>) onSubmit;

  /// Asks the POS to re-push the menu (used while waiting for the first push).
  final Future<void> Function() onRefreshMenu;

  /// Hybrid only: leave the kiosk flow back to the promo screen. Null for a
  /// dedicated kiosk (nowhere to exit to).
  final VoidCallback? onExit;

  const KioskSurface({
    super.key,
    required this.businessName,
    required this.menu,
    required this.onSubmit,
    required this.onRefreshMenu,
    this.onExit,
  });

  @override
  State<KioskSurface> createState() => _KioskSurfaceState();
}

enum _Stage { browse, review, confirm }

class _KioskSurfaceState extends State<KioskSurface> {
  final List<CartLine> _cart = [];
  int _categoryIndex = 0;
  _Stage _stage = _Stage.browse;
  bool _submitting = false;
  String? _confirmCode;
  Timer? _resetTimer;

  int get _cartCount => _cart.fold(0, (s, l) => s + l.qty);
  int get _cartCents => _cart.fold(0, (s, l) => s + l.lineCents);

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _addToCart(KioskItem item, List<KioskModifier> modifiers) {
    final line = CartLine(item: item, modifiers: modifiers);
    final existing = _cart
        .where((l) => l.signature == line.signature)
        .firstOrNull;
    setState(() {
      if (existing != null) {
        existing.qty += 1;
      } else {
        _cart.add(line);
      }
    });
  }

  Future<void> _onItemTap(KioskItem item) async {
    if (!item.hasModifiers) {
      _addToCart(item, const []);
      return;
    }
    final mods = await showModalBottomSheet<List<KioskModifier>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ModifierSheet(item: item),
    );
    if (mods != null) _addToCart(item, mods);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not place the order. Please ask staff.'),
        ),
      );
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
          const Text('Loading menu…'),
          TextButton(
            onPressed: widget.onRefreshMenu,
            child: const Text('Retry'),
          ),
          if (widget.onExit != null)
            TextButton(onPressed: widget.onExit, child: const Text('Back')),
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
                  Expanded(
                    child: Text(
                      widget.businessName.isEmpty
                          ? 'Order here'
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
                        'Cancel',
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
      mainAxisExtent: 150,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: items.length,
    itemBuilder: (context, i) {
      final item = items[i];
      final theme = Theme.of(context);
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _onItemTap(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                          style: theme.textTheme.bodyMedium,
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
                    Icon(Icons.add_circle, color: theme.colorScheme.primary),
                  ],
                ),
              ],
            ),
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
            Icon(Icons.shopping_cart_outlined, size: 28),
            const SizedBox(width: 12),
            Text(
              empty
                  ? 'Your cart is empty'
                  : '$_cartCount item${_cartCount == 1 ? '' : 's'}  ·  ${formatCents(_cartCents)}',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: empty
                  ? null
                  : () => setState(() => _stage = _Stage.review),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 56)),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Review order'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _review() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your order'),
        leading: BackButton(
          onPressed: () => setState(() => _stage = _Stage.browse),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _cart.isEmpty
                  ? const Center(child: Text('Your cart is empty'))
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
        row('Subtotal', t.subtotal),
        if (!t.serviceFee.isZero)
          row('Service (${_pct(serviceFeeBp)}%)', t.serviceFee),
        row('Tax (${_pct(taxBp)}%)', t.tax),
        const Divider(height: 16),
        row('Total', t.total, bold: true),
      ],
    );
  }

  Widget _paymentActions() {
    final addMore = OutlinedButton.icon(
      onPressed: () => setState(() => _stage = _Stage.browse),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
      icon: const Icon(Icons.add),
      label: const Text('Add more'),
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
      label: Text(_submitting ? 'Placing…' : 'Pay at counter'),
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
      label: const Text('Pay here (soon)'),
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

  Widget _cartTile(CartLine line) {
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
              Icon(
                Icons.check_circle,
                size: 120,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Order placed!',
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              if (_confirmCode != null) ...[
                const SizedBox(height: 16),
                Text('Your number', style: theme.textTheme.titleMedium),
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
                'Please pay at the counter.',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _reset,
                style: FilledButton.styleFrom(minimumSize: const Size(200, 60)),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing an item's modifiers. Single-select required groups
/// render as radios (first option pre-selected); multi-select groups as checks.
class _ModifierSheet extends StatefulWidget {
  final KioskItem item;

  const _ModifierSheet({required this.item});

  @override
  State<_ModifierSheet> createState() => _ModifierSheetState();
}

class _ModifierSheetState extends State<_ModifierSheet> {
  /// groupId -> selected modifier ids.
  final Map<String, Set<String>> _selected = {};

  @override
  void initState() {
    super.initState();
    // Pre-select the first option of required single-choice groups.
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(widget.item.name, style: theme.textTheme.headlineSmall),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final g in widget.item.modifierGroups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Text(
                      g.isRequired ? '${g.name} *' : g.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  for (final m in g.modifiers) _modifierTile(g, m),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _satisfied
                    ? () => Navigator.pop(context, [
                        for (final g in widget.item.modifierGroups)
                          for (final m in g.modifiers)
                            if (_selected[g.id]?.contains(m.id) ?? false) m,
                      ])
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: theme.textTheme.titleMedium,
                ),
                child: Text(
                  _extraCents == 0
                      ? 'Add to order'
                      : 'Add to order  ·  +${formatCents(_extraCents)}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modifierTile(KioskModifierGroup g, KioskModifier m) {
    final checked = _selected[g.id]?.contains(m.id) ?? false;
    final trailing = m.deltaCents == 0 ? null : Text(m.delta);
    if (g.isSingleChoice) {
      return RadioListTile<String>(
        value: m.id,
        // ignore: deprecated_member_use
        groupValue: _selected[g.id]?.firstOrNull,
        // ignore: deprecated_member_use
        onChanged: (_) => _toggle(g, m),
        title: Text(m.name),
        secondary: trailing,
      );
    }
    return CheckboxListTile(
      value: checked,
      onChanged: (_) => _toggle(g, m),
      title: Text(m.name),
      secondary: trailing,
    );
  }
}
