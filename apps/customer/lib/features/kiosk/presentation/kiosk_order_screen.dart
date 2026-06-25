import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

import '../../../core/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../../storefront/application/providers.dart';
import '../data/published_to_kiosk.dart';

/// Hosts the shared [KioskSurface] in the customer tablet kiosk: feeds it the
/// published menu (mapped to the kiosk model) and turns a placed cart into a
/// cloud preorder. The order is pay-at-counter — it lands in the merchant
/// Inbox like any online order, labelled "Kiosk N" so staff know its source.
class KioskOrderScreen extends ConsumerWidget {
  const KioskOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final menu = ref.watch(menuProvider).value;
    final kioskMenu = menu == null
        ? null
        : publishedToKioskMenu(menu, appLanguageCode: lang);
    return KioskSurface(
      businessName: menu?.restaurantName ?? '',
      // The shop logo isn't synced to the customer app, so the generic glyph
      // shows (BrandMark's fallback).
      brandHeader: null,
      brandConfirm: null,
      menu: kioskMenu,
      labels: _labels(l10n),
      onRefreshMenu: () async => ref.invalidate(menuProvider),
      onExit: () => Navigator.of(context).pop(),
      onSubmit: (cart) => _submit(ref, l10n, cart),
    );
  }

  Future<Map<String, dynamic>> _submit(
    WidgetRef ref,
    AppLocalizations l10n,
    List<KioskCartLine> cart,
  ) async {
    final storefront = ref.read(storefrontProvider);
    if (storefront == null) return {'ok': false};
    final menu = ref.read(menuProvider).value;
    final number = ref.read(storefrontConfigRepositoryProvider).kioskNumber;
    final submission = domain.PreorderSubmission(
      customerName: number != null
          ? l10n.kioskOrderName(number)
          : l10n.kioskDefaultName,
      requestedPickupAt: DateTime.now().add(
        Duration(minutes: menu?.pickupLeadMinutes ?? 0),
      ),
      // In-store kiosk → the merchant can auto-accept straight to the board.
      kiosk: true,
      lines: [
        for (final l in cart)
          domain.PreorderLine(
            itemId: l.item.id,
            nameSnapshot: l.item.name,
            priceSnapshot: domain.Money(l.item.priceCents),
            qty: l.qty,
            modifiers: [
              for (final m in l.modifiers)
                domain.PreorderModifier(
                  nameSnapshot: m.name,
                  priceDeltaSnapshot: domain.Money(m.deltaCents),
                ),
            ],
          ),
      ],
    );
    try {
      await storefront.submitPreorder(
        submission,
        customerUid: ref.read(storefrontConfigProvider).customerUid,
      );
      return {'ok': true};
    } on Object {
      return {'ok': false};
    }
  }
}

/// Builds the kiosk strings from the customer app's localizations so the shared
/// surface is bilingual (the merchant passes its own English [KioskLabels.en]).
KioskLabels _labels(AppLocalizations l10n) => KioskLabels(
  loadingMenu: l10n.kioskLoadingMenu,
  retry: l10n.kioskRetry,
  back: l10n.kioskBack,
  headerFallbackTitle: l10n.kioskHeaderFallback,
  cancel: l10n.commonCancel,
  cartEmpty: l10n.kioskCartEmpty,
  reviewOrder: l10n.kioskReviewOrder,
  reviewTitle: l10n.kioskReviewTitle,
  addMore: l10n.kioskAddMore,
  payAtCounter: l10n.kioskPayAtCounter,
  placing: l10n.kioskPlacing,
  payHereSoon: l10n.kioskPayHereSoon,
  subtotal: l10n.kioskSubtotal,
  total: l10n.kioskTotal,
  orderPlaced: l10n.kioskOrderPlaced,
  yourNumber: l10n.kioskYourNumber,
  payAtCounterNote: l10n.kioskPayAtCounterNote,
  done: l10n.kioskDone,
  addToOrder: l10n.kioskAddToOrder,
  submitFailed: l10n.kioskSubmitFailed,
  cartSummary: (count, total) => l10n.kioskCartSummary(count, total),
  service: (pct) => l10n.kioskService(pct),
  tax: (pct) => l10n.kioskTax(pct),
  addToOrderExtra: (extra) => l10n.kioskAddToOrderExtra(extra),
);
