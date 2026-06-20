import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Real [domain.OnlineOrderChannel] over the restaurant's own Supabase —
/// the same project that carries cloud sync. The only place the merchant
/// app knows the online-ordering wire format.
///
/// Two PostgREST tables, `published_menu` and `online_orders`. Their DDL
/// and — critically — the RLS policies that keep one customer from
/// reading another's order (or the restaurant's private data) live in
/// docs/CLOUD_SECURITY.md. Applying that RLS is a blocking pre-deployment
/// gate (docs/ROADMAP.md).
///
/// New preorders are found by polling `status = submitted` (Supabase
/// Realtime would also work; polling keeps the dependency surface small
/// and is plenty for a single tablet).
class SupabaseOnlineOrderChannel implements domain.OnlineOrderChannel {
  final Uri baseUrl;
  final String anonKey;
  final http.Client _client;
  final Duration pollInterval;
  final Duration timeout;

  /// Fixed key for the single published-menu row.
  static const _menuRowId = 'menu';

  /// The signed-in restaurant user's access token; RLS lets the
  /// restaurant read/manage all orders. Falls back to the anon key when
  /// null (tests).
  final Future<String?> Function()? accessToken;

  SupabaseOnlineOrderChannel({
    required String url,
    required this.anonKey,
    this.accessToken,
    http.Client? client,
    this.pollInterval = const Duration(seconds: 5),
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
       _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await accessToken?.call() ?? anonKey;
    return {
      'apikey': anonKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _rest(String table, [Map<String, dynamic>? query]) => baseUrl
      .resolve('rest/v1/$table')
      .replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));

  /// One-shot fetch of preorders in a given [status], oldest first.
  Future<List<domain.IncomingOnlineOrder>> fetchByStatus(
    domain.OnlineOrderStatus status,
  ) async {
    final resp = await _client
        .get(
          _rest(domain.OnlineOrderingTables.onlineOrders, {
            'select': '*',
            'status': 'eq.${status.name}',
            'order': 'submitted_at.asc',
          }),
          headers: await _authHeaders(),
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('fetch online orders (${resp.statusCode})');
    }
    final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
    return list.map(_incomingFromRow).toList();
  }

  /// Preorders awaiting a decision. [watchIncomingOrders] polls this.
  Future<List<domain.IncomingOnlineOrder>> fetchSubmitted() =>
      fetchByStatus(domain.OnlineOrderStatus.submitted);

  domain.IncomingOnlineOrder _incomingFromRow(Map<String, dynamic> r) =>
      domain.IncomingOnlineOrder(
        id: r['id'] as String,
        customerName: r['customer_name'] as String,
        customerPhone: r['customer_phone'] as String?,
        linesJson: jsonEncode(r['lines']),
        requestedPickupAt: DateTime.parse(r['requested_pickup_at'] as String),
        submittedAt: DateTime.parse(r['submitted_at'] as String),
        proposedPickupAt: r['proposed_pickup_at'] == null
            ? null
            : DateTime.parse(r['proposed_pickup_at'] as String),
      );

  @override
  Stream<domain.IncomingOnlineOrder> watchIncomingOrders() async* {
    final seen = <String>{};
    while (true) {
      final orders = await fetchSubmitted();
      for (final order in orders) {
        if (seen.add(order.id)) yield order;
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  @override
  Future<void> publishMenu(String menuJson) async {
    final resp = await _client
        .post(
          _rest(domain.OnlineOrderingTables.publishedMenu),
          headers: {
            ...await _authHeaders(),
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode([
            {
              'id': _menuRowId,
              'menu': jsonDecode(menuJson),
              'published_at': DateTime.now().toUtc().toIso8601String(),
            },
          ]),
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('publish menu (${resp.statusCode})');
    }
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    domain.OnlineOrderStatus status,
  ) async {
    final resp = await _client
        .patch(
          _rest(domain.OnlineOrderingTables.onlineOrders, {
            'id': 'eq.$orderId',
          }),
          headers: await _authHeaders(),
          body: jsonEncode({'status': status.name}),
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('update order status (${resp.statusCode})');
    }
  }

  @override
  Future<void> proposePickupTime(
    String orderId,
    DateTime proposedPickupAt,
  ) async {
    final resp = await _client
        .patch(
          _rest(domain.OnlineOrderingTables.onlineOrders, {
            'id': 'eq.$orderId',
          }),
          headers: await _authHeaders(),
          body: jsonEncode({
            'status': domain.OnlineOrderStatus.timeProposed.name,
            'proposed_pickup_at': proposedPickupAt.toUtc().toIso8601String(),
          }),
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('propose pickup time (${resp.statusCode})');
    }
  }
}
