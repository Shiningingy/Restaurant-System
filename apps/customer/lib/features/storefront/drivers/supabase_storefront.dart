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

  /// The anonymous customer's access token; RLS scopes online_orders to
  /// this device. Falls back to the anon key when null (tests).
  final Future<String?> Function()? accessToken;

  static const _menuRowId = 'menu';

  SupabaseStorefront({
    required String url,
    required this.anonKey,
    this.accessToken,
    http.Client? client,
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

  /// The menu the restaurant has published, or null if none yet.
  Future<domain.PublishedMenu?> fetchMenu() async {
    final resp = await _client
        .get(
          _rest(domain.OnlineOrderingTables.publishedMenu, {
            'select': 'menu',
            'id': 'eq.$_menuRowId',
          }),
          headers: await _authHeaders(),
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
  /// [customerUid] ties the row to this device so RLS lets only this
  /// customer read it back; when null the server fills it from the JWT.
  Future<String> submitPreorder(
    domain.PreorderSubmission sub, {
    String? customerUid,
  }) async {
    final id = domain.newId();
    final row = <String, dynamic>{
      'id': id,
      'customer_uid': ?customerUid,
      'customer_name': sub.customerName,
      'customer_phone': sub.customerPhone,
      'lines': sub.lines.map((l) => l.toJson()).toList(),
      'requested_pickup_at': sub.requestedPickupAt.toUtc().toIso8601String(),
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
      'status': domain.OnlineOrderStatus.submitted.name,
      'note': sub.note,
    };
    // Only send the email/SMS-notification columns when the customer opted in.
    // They're optional schema (docs/EMAIL_SMS_NOTIFICATIONS.md); referencing
    // them otherwise would 400 on a storefront that hasn't added them, breaking
    // ordering for everyone.
    if (sub.notifyByEmail || sub.notifyBySms) {
      row['customer_email'] = sub.customerEmail;
      row['notify_by_email'] = sub.notifyByEmail;
      row['notify_by_sms'] = sub.notifyBySms;
    }
    final resp = await _client
        .post(
          _rest(domain.OnlineOrderingTables.onlineOrders),
          headers: await _authHeaders(),
          body: jsonEncode([row]),
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
          headers: await _authHeaders(),
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

  /// Current status plus the merchant's proposed pickup time (when the
  /// status is timeProposed).
  Future<OrderState> fetchState(String orderId) async {
    // Select '*' rather than naming proposed_pickup_at: that column is part of
    // the optional pickup-time-negotiation schema, and naming a missing column
    // would 400. Absent column simply reads back as null.
    final resp = await _client
        .get(
          _rest(domain.OnlineOrderingTables.onlineOrders, {
            'select': '*',
            'id': 'eq.$orderId',
          }),
          headers: await _authHeaders(),
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('fetch status (${resp.statusCode})');
    }
    final rows = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) {
      return (
        status: domain.OnlineOrderStatus.submitted,
        proposedPickupAt: null,
      );
    }
    final row = rows.first;
    final proposed = row['proposed_pickup_at'];
    return (
      status: domain.OnlineOrderStatus.values.byName(row['status'] as String),
      proposedPickupAt: proposed == null
          ? null
          : DateTime.parse(proposed as String).toLocal(),
    );
  }

  /// Polls [fetchState] until the order reaches a terminal state.
  Stream<OrderState> watchState(
    String orderId, {
    Duration interval = const Duration(seconds: 4),
  }) async* {
    while (true) {
      final state = await fetchState(orderId);
      yield state;
      if (state.status == domain.OnlineOrderStatus.rejected ||
          state.status == domain.OnlineOrderStatus.pickedUp) {
        return;
      }
      await Future<void>.delayed(interval);
    }
  }

  /// Customer accepts the merchant's proposed time: it becomes the agreed
  /// pickup time and the order returns to `submitted` so the merchant accepts
  /// it normally (creating the local order that drives printing/POS/reports),
  /// and the new-order chime tells them it was confirmed. Requires the RLS
  /// policy that lets a row owner update their own order (docs/CLOUD_SECURITY).
  Future<void> approveProposedTime(String orderId) async {
    final state = await fetchState(orderId);
    final body = <String, dynamic>{
      'status': domain.OnlineOrderStatus.submitted.name,
      'proposed_pickup_at': null,
    };
    if (state.proposedPickupAt != null) {
      body['requested_pickup_at'] = state.proposedPickupAt!
          .toUtc()
          .toIso8601String();
    }
    await _patchOwnOrder(orderId, body);
  }

  /// Customer rejects the proposed time, cancelling the order.
  Future<void> declineProposedTime(String orderId) => _patchOwnOrder(orderId, {
    'status': domain.OnlineOrderStatus.rejected.name,
  });

  Future<void> _patchOwnOrder(String orderId, Map<String, dynamic> body) async {
    final resp = await _client
        .patch(
          _rest(domain.OnlineOrderingTables.onlineOrders, {
            'id': 'eq.$orderId',
          }),
          headers: await _authHeaders(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('update order (${resp.statusCode})');
    }
  }
}

/// Status of a placed order plus any proposed pickup time.
typedef OrderState = ({
  domain.OnlineOrderStatus status,
  DateTime? proposedPickupAt,
});
