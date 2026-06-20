import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../storefront/application/providers.dart';
import '../../storefront/drivers/supabase_storefront.dart';
import '../data/order_history.dart';

final orderHistoryRepositoryProvider = Provider<OrderHistoryRepository>(
  (ref) => OrderHistoryRepository(ref.watch(sharedPreferencesProvider)),
);

/// The customer's placed orders on this device, newest first.
class OrderHistoryNotifier extends Notifier<List<PlacedOrder>> {
  @override
  List<PlacedOrder> build() => ref.watch(orderHistoryRepositoryProvider).all();

  OrderHistoryRepository get _repo => ref.read(orderHistoryRepositoryProvider);

  Future<void> add(PlacedOrder order) async => state = await _repo.add(order);

  Future<void> updateStatus(
    String orderId,
    domain.OnlineOrderStatus status,
  ) async {
    if (state.any((o) => o.orderId == orderId && o.status == status)) return;
    state = await _repo.updateStatus(orderId, status);
  }

  Future<void> remove(String orderId) async =>
      state = await _repo.remove(orderId);
}

final orderHistoryProvider =
    NotifierProvider<OrderHistoryNotifier, List<PlacedOrder>>(
      OrderHistoryNotifier.new,
    );

/// Placed orders for one storefront (the one currently open).
final ordersForStorefrontProvider = Provider.family<List<PlacedOrder>, String>((
  ref,
  storefrontId,
) {
  return ref
      .watch(orderHistoryProvider)
      .where((o) => o.storefrontId == storefrontId)
      .toList();
});

/// Live status of one placed order, polled from the active storefront. As a
/// side effect it writes each change into the order history (so badges stay
/// current) and fires an on-device notification when the status changes.
final orderStatusTrackProvider = StreamProvider.autoDispose
    .family<OrderState, String>((ref, orderId) async* {
      final storefront = ref.watch(storefrontProvider);
      if (storefront == null) return;
      await for (final state in storefront.watchState(orderId)) {
        final previous = ref
            .read(orderHistoryProvider)
            .where((o) => o.orderId == orderId)
            .firstOrNull;
        if (previous != null && previous.status != state.status) {
          await _notify(ref, previous, state.status);
        }
        await ref
            .read(orderHistoryProvider.notifier)
            .updateStatus(orderId, state.status);
        yield state;
      }
    });

/// Fires a localized on-device notification for a status change worth telling
/// the customer about. Loads the app's current locale directly (no context).
Future<void> _notify(
  Ref ref,
  PlacedOrder order,
  domain.OnlineOrderStatus status,
) async {
  final body = switch (status) {
    domain.OnlineOrderStatus.accepted =>
      (AppLocalizations l) => l.orderNotifyAccepted,
    domain.OnlineOrderStatus.ready =>
      (AppLocalizations l) => l.orderNotifyReady,
    domain.OnlineOrderStatus.timeProposed =>
      (AppLocalizations l) => l.orderNotifyTimeProposed,
    domain.OnlineOrderStatus.rejected =>
      (AppLocalizations l) => l.orderNotifyRejected,
    _ => null,
  };
  if (body == null) return; // submitted / pickedUp: nothing to announce
  final locale =
      ref.read(localePreferenceProvider) ??
      WidgetsBinding.instance.platformDispatcher.locale;
  final l10n = AppLocalizations.delegate.isSupported(locale)
      ? await AppLocalizations.delegate.load(locale)
      : await AppLocalizations.delegate.load(const Locale('en'));
  await ref
      .read(notificationServiceProvider)
      .showOrderStatus(
        id: order.orderId.hashCode,
        title: order.restaurantLabel,
        body: body(l10n),
      );
}
