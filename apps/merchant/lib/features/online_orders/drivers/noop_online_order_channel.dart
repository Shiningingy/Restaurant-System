import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Default [domain.OnlineOrderChannel]: no online ordering. Selected when
/// the restaurant hasn't configured Supabase — the POS is unaffected.
class NoopOnlineOrderChannel implements domain.OnlineOrderChannel {
  const NoopOnlineOrderChannel();

  @override
  Stream<domain.IncomingOnlineOrder> watchIncomingOrders() =>
      const Stream.empty();

  @override
  Future<void> publishMenu(String menuJson) async {}

  @override
  Future<void> updateOrderStatus(
    String orderId,
    domain.OnlineOrderStatus status,
  ) async {}
}
