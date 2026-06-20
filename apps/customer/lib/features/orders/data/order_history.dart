import 'dart:convert';

import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

/// One preorder the customer placed, remembered on this device so they can
/// see their history and track status. Device-local only — no account, no
/// server. The status is the last one we saw while polling.
class PlacedOrder {
  final String orderId;

  /// Which saved restaurant this order belongs to (wallet storefront id).
  final String storefrontId;

  /// A snapshot of the restaurant's label at order time, for display even if
  /// the restaurant is later removed.
  final String restaurantLabel;
  final int totalCents;
  final DateTime placedAt;
  final domain.OnlineOrderStatus status;

  const PlacedOrder({
    required this.orderId,
    required this.storefrontId,
    required this.restaurantLabel,
    required this.totalCents,
    required this.placedAt,
    required this.status,
  });

  domain.Money get total => domain.Money(totalCents);

  /// True once the order can't change any further.
  bool get isTerminal =>
      status == domain.OnlineOrderStatus.rejected ||
      status == domain.OnlineOrderStatus.pickedUp;

  PlacedOrder copyWith({domain.OnlineOrderStatus? status}) => PlacedOrder(
    orderId: orderId,
    storefrontId: storefrontId,
    restaurantLabel: restaurantLabel,
    totalCents: totalCents,
    placedAt: placedAt,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'storefrontId': storefrontId,
    'restaurantLabel': restaurantLabel,
    'totalCents': totalCents,
    'placedAt': placedAt.toIso8601String(),
    'status': status.name,
  };

  factory PlacedOrder.fromJson(Map<String, dynamic> j) => PlacedOrder(
    orderId: j['orderId'] as String,
    storefrontId: j['storefrontId'] as String,
    restaurantLabel: j['restaurantLabel'] as String,
    totalCents: j['totalCents'] as int,
    placedAt: DateTime.parse(j['placedAt'] as String),
    status: domain.OnlineOrderStatus.values.byName(j['status'] as String),
  );
}

/// Device-local store of placed orders (newest first). Backed by
/// [SharedPreferences]; capped so it can't grow without bound.
class OrderHistoryRepository {
  static const _key = 'placedOrders';
  static const _max = 50;

  final SharedPreferences prefs;

  OrderHistoryRepository(this.prefs);

  List<PlacedOrder> all() {
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(PlacedOrder.fromJson)
        .toList();
  }

  Future<void> _save(List<PlacedOrder> orders) =>
      prefs.setString(_key, jsonEncode(orders.map((o) => o.toJson()).toList()));

  Future<List<PlacedOrder>> add(PlacedOrder order) async {
    final list = [order, ...all().where((o) => o.orderId != order.orderId)];
    if (list.length > _max) list.removeRange(_max, list.length);
    await _save(list);
    return list;
  }

  Future<List<PlacedOrder>> updateStatus(
    String orderId,
    domain.OnlineOrderStatus status,
  ) async {
    final list = all()
        .map((o) => o.orderId == orderId ? o.copyWith(status: status) : o)
        .toList();
    await _save(list);
    return list;
  }

  Future<List<PlacedOrder>> remove(String orderId) async {
    final list = all().where((o) => o.orderId != orderId).toList();
    await _save(list);
    return list;
  }
}
