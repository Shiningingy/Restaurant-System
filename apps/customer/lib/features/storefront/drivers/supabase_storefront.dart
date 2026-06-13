import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Customer-side client for the restaurant's Supabase storefront — the
/// mirror of the merchant's SupabaseOnlineOrderChannel. Reads the
/// published menu, submits preorders, and reads back their status. The
/// only place the customer app knows the Supabase wire format.
///
/// No payment data ever travels here — preorders are pay-at-pickup
/// (docs/PRINCIPLES.md).
class SupabaseStorefront {
  final Uri baseUrl;
  final String anonKey;
  final http.Client _client;
  final Duration timeout;

  static const _menuRowId = 'menu';

  SupabaseStorefront({
    required String url,
    required this.anonKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
       _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  Uri _rest(String table, [Map<String, dynamic>? query]) => baseUrl
      .resolve('rest/v1/$table')
      .replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));

  /// The menu the restaurant has published, or null if none yet.
  Future<domain.PublishedMenu?> fetchMenu() async {
    final resp = await _client
        .get(
          _rest(domain.OnlineOrderingTables.publishedMenu, {
            'select': 'menu',
            'id': 'eq.$_menuRowId',
          }),
          headers: _headers,
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('fetch menu (${resp.statusCode})');
    }
    final rows = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return null;
    return domain.PublishedMenu.fromJson(
      rows.first['menu'] as Map<String, dynamic>,
    );
  }

  /// Submits a preorder and returns its id (for status polling).
  Future<String> submitPreorder(domain.PreorderSubmission sub) async {
    final id = domain.newId();
    final resp = await _client
        .post(
          _rest(domain.OnlineOrderingTables.onlineOrders),
          headers: _headers,
          body: jsonEncode([
            {
              'id': id,
              'customer_name': sub.customerName,
              'customer_phone': sub.customerPhone,
              'lines': sub.lines.map((l) => l.toJson()).toList(),
              'requested_pickup_at': sub.requestedPickupAt
                  .toUtc()
                  .toIso8601String(),
              'submitted_at': DateTime.now().toUtc().toIso8601String(),
              'status': domain.OnlineOrderStatus.submitted.name,
              'note': sub.note,
            },
          ]),
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('submit preorder (${resp.statusCode})');
    }
    return id;
  }

  /// Current status of a submitted preorder.
  Future<domain.OnlineOrderStatus> fetchStatus(String orderId) async {
    final resp = await _client
        .get(
          _rest(domain.OnlineOrderingTables.onlineOrders, {
            'select': 'status',
            'id': 'eq.$orderId',
          }),
          headers: _headers,
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('fetch status (${resp.statusCode})');
    }
    final rows = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return domain.OnlineOrderStatus.submitted;
    return domain.OnlineOrderStatus.values.byName(
      rows.first['status'] as String,
    );
  }

  /// Polls [fetchStatus] until the order reaches a terminal state.
  Stream<domain.OnlineOrderStatus> watchStatus(
    String orderId, {
    Duration interval = const Duration(seconds: 4),
  }) async* {
    while (true) {
      final status = await fetchStatus(orderId);
      yield status;
      if (status == domain.OnlineOrderStatus.rejected ||
          status == domain.OnlineOrderStatus.pickedUp) {
        return;
      }
      await Future<void>.delayed(interval);
    }
  }
}
