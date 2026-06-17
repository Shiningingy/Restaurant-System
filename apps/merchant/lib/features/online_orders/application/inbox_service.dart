import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../orders/data/order_repository.dart';
import '../../../core/settings/settings_repository.dart';
import '../data/menu_publisher.dart';
import '../drivers/supabase_online_order_channel.dart';

final _pickupFormat = DateFormat('HH:mm');

/// The merchant side of online ordering: surface incoming preorders,
/// accept one into a normal local order (so it flows through printing,
/// payment and reports like any other), reject, or push pickup status
/// back to the customer.
class InboxService {
  final domain.OnlineOrderChannel channel;
  final OrderRepository orders;
  final SettingsRepository settings;
  final MenuPublisher publisher;

  InboxService({
    required this.channel,
    required this.orders,
    required this.settings,
    required this.publisher,
  });

  Stream<domain.IncomingOnlineOrder> watchIncoming() =>
      channel.watchIncomingOrders();

  /// Preorders in [status]. Empty when no cloud is configured. The inbox
  /// UI polls this.
  Future<List<domain.IncomingOnlineOrder>> currentByStatus(
    domain.OnlineOrderStatus status,
  ) async {
    final c = channel;
    if (c is SupabaseOnlineOrderChannel) return c.fetchByStatus(status);
    return const [];
  }

  /// Preorders currently awaiting a decision.
  Future<List<domain.IncomingOnlineOrder>> currentPending() =>
      currentByStatus(domain.OnlineOrderStatus.submitted);

  /// Publishes the current menu so the customer app can browse it.
  Future<void> publishMenu() async {
    final menu = await publisher.build();
    await channel.publishMenu(jsonEncode(menu.toJson()));
  }

  /// Turns an accepted preorder into a normal local order (type=online),
  /// then tells the customer it was accepted. Returns the local order id.
  /// Line prices use the customer's submitted snapshots; tax is applied
  /// locally (pickup is pay-at-store, tax included).
  Future<String> accept(domain.IncomingOnlineOrder incoming) async {
    final lines = (jsonDecode(incoming.linesJson) as List)
        .cast<Map<String, dynamic>>()
        .map(domain.PreorderLine.fromJson)
        .toList();

    final pickup = _pickupFormat.format(incoming.requestedPickupAt);
    final orderId = await orders.createOrder(
      type: domain.OrderType.online,
      taxRateBp: settings.taxRateBp,
      note: 'Online: ${incoming.customerName} - pickup $pickup',
    );
    for (final line in lines) {
      await orders.addLine(
        orderId: orderId,
        item: domain.MenuItem(
          id: line.itemId,
          categoryId: '',
          name: line.nameSnapshot,
          price: line.priceSnapshot,
        ),
        selectedModifiers: [
          for (final m in line.modifiers)
            domain.Modifier(
              id: domain.newId(),
              groupId: '',
              name: m.nameSnapshot,
              priceDelta: m.priceDeltaSnapshot,
            ),
        ],
        qty: line.qty,
        note: line.note,
      );
    }
    await channel.updateOrderStatus(
      incoming.id,
      domain.OnlineOrderStatus.accepted,
    );
    return orderId;
  }

  Future<void> reject(String onlineOrderId) => channel.updateOrderStatus(
    onlineOrderId,
    domain.OnlineOrderStatus.rejected,
  );

  Future<void> markReady(String onlineOrderId) =>
      channel.updateOrderStatus(onlineOrderId, domain.OnlineOrderStatus.ready);

  Future<void> markPickedUp(String onlineOrderId) => channel.updateOrderStatus(
    onlineOrderId,
    domain.OnlineOrderStatus.pickedUp,
  );
}
