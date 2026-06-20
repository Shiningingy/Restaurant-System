import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
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

  OrderHistoryRepository get _repo =>
      ref.read(orderHistoryRepositoryProvider);

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
final ordersForStorefrontProvider =
    Provider.family<List<PlacedOrder>, String>((ref, storefrontId) {
      return ref
          .watch(orderHistoryProvider)
          .where((o) => o.storefrontId == storefrontId)
          .toList();
    });

/// Live status of one placed order, polled from the active storefront. As a
/// side effect it writes each change into the order history, so badges stay
/// current and [orderStatusChangeProvider] can notify on it.
final orderStatusTrackProvider = StreamProvider.autoDispose
    .family<OrderState, String>((ref, orderId) async* {
      final storefront = ref.watch(storefrontProvider);
      if (storefront == null) return;
      await for (final state in storefront.watchState(orderId)) {
        await ref
            .read(orderHistoryProvider.notifier)
            .updateStatus(orderId, state.status);
        yield state;
      }
    });
