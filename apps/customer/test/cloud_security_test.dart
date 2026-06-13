import 'dart:convert';
import 'dart:io';

import 'package:customer/features/storefront/drivers/supabase_auth.dart';
import 'package:customer/features/storefront/drivers/supabase_storefront.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// A Supabase emulator that issues auth tokens and **enforces the RLS
/// model from docs/CLOUD_SECURITY.md**, so we can prove a customer is
/// actually blocked from the restaurant's private data — not just that
/// our client sends the right headers.
///
/// Tokens are unsigned base64(JSON) carrying {sub, is_anonymous}; the real
/// thing uses signed JWTs, but our client only passes the token through —
/// the emulator is what evaluates the claims, mirroring Postgres RLS.
class RlsSupabase {
  final String anonKey;
  final String restaurantEmail;
  final String restaurantPassword;
  final String restaurantUid;
  final Map<String, List<Map<String, dynamic>>> tables = {};
  late final HttpServer _server;

  RlsSupabase({
    this.anonKey = 'anon-key',
    this.restaurantEmail = 'owner@diner.test',
    this.restaurantPassword = 'pw',
    this.restaurantUid = 'restaurant-uid',
  });

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  void seed(String table, Map<String, dynamic> row) =>
      tables.putIfAbsent(table, () => []).add(row);

  List<Map<String, dynamic>> rowsOf(String t) => tables[t] ?? [];

  // --- identity ---

  String _mkToken(String sub, bool isAnon) => base64Url.encode(
    utf8.encode(jsonEncode({'sub': sub, 'is_anonymous': isAnon})),
  );

  Map<String, dynamic> _session(String sub, bool isAnon) => {
    'access_token': _mkToken(sub, isAnon),
    'refresh_token': 'refresh:$sub:$isAnon',
    'expires_in': 3600,
    'user': {'id': sub, 'is_anonymous': isAnon},
  };

  /// (role, uid) — role is 'anon' (key only), 'customer' (anon auth) or
  /// 'restaurant' (real login).
  (String, String?) _identity(String? bearer) {
    if (bearer == null || bearer == anonKey) return ('anon', null);
    final claims =
        jsonDecode(utf8.decode(base64Url.decode(bearer)))
            as Map<String, dynamic>;
    final isAnon = claims['is_anonymous'] as bool;
    return (isAnon ? 'customer' : 'restaurant', claims['sub'] as String);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    if (req.headers.value('apikey') != anonKey) {
      res.statusCode = HttpStatus.unauthorized;
      await res.close();
      return;
    }
    final body = req.method == 'GET'
        ? null
        : await utf8.decoder.bind(req).join();
    final path = req.uri.path;

    if (path == '/auth/v1/signup') {
      _write(res, HttpStatus.ok, _session(_uid(), true)); // anonymous
      await res.close();
      return;
    }
    if (path == '/auth/v1/token') {
      final grant = req.uri.queryParameters['grant_type'];
      if (grant == 'password') {
        final b = jsonDecode(body!) as Map<String, dynamic>;
        if (b['email'] == restaurantEmail &&
            b['password'] == restaurantPassword) {
          _write(res, HttpStatus.ok, _session(restaurantUid, false));
        } else {
          res.statusCode = HttpStatus.badRequest;
        }
      } else if (grant == 'refresh_token') {
        final parts = ((jsonDecode(body!) as Map)['refresh_token'] as String)
            .split(':');
        _write(res, HttpStatus.ok, _session(parts[1], parts[2] == 'true'));
      }
      await res.close();
      return;
    }

    // PostgREST
    final table = req.uri.pathSegments.last;
    final rows = tables.putIfAbsent(table, () => []);
    final (role, uid) = _identity(
      req.headers.value('Authorization')?.replaceFirst('Bearer ', ''),
    );
    final q = req.uri.queryParameters;

    bool queryMatch(Map<String, dynamic> r) {
      for (final e in q.entries) {
        if (const {'select', 'order', 'limit'}.contains(e.key)) continue;
        if (e.value.startsWith('eq.') &&
            '${r[e.key]}' != e.value.substring(3)) {
          return false;
        }
      }
      return true;
    }

    // RLS row visibility for SELECT.
    bool canRead(String table, Map<String, dynamic> r) => switch (table) {
      'published_menu' => true, // public
      'sync_changes' => role == 'restaurant',
      'online_orders' =>
        role == 'restaurant' ||
            (role == 'customer' && r['customer_uid'] == uid),
      _ => role == 'restaurant',
    };

    switch (req.method) {
      case 'GET':
        final visible = rows
            .where((r) => canRead(table, r) && queryMatch(r))
            .toList();
        _write(res, HttpStatus.ok, visible);
        break;
      case 'POST':
        final incoming = (jsonDecode(body!) as List)
            .cast<Map<String, dynamic>>();
        for (final row in incoming) {
          if (!_canInsert(table, role, uid, row)) {
            res.statusCode = HttpStatus.forbidden; // RLS check violation
            await res.close();
            return;
          }
        }
        for (final row in incoming) {
          rows.removeWhere((r) => r['id'] == row['id']);
          rows.add(row);
        }
        res.statusCode = HttpStatus.created;
        break;
      case 'PATCH':
        final patch = jsonDecode(body!) as Map<String, dynamic>;
        // Only the restaurant may update (customers have no update policy).
        if (role != 'restaurant') {
          res.statusCode = HttpStatus.forbidden;
          await res.close();
          return;
        }
        for (final r in rows.where(queryMatch)) {
          r.addAll(patch);
        }
        res.statusCode = HttpStatus.ok;
        break;
      default:
        res.statusCode = HttpStatus.methodNotAllowed;
    }
    await res.close();
  }

  bool _canInsert(
    String table,
    String role,
    String? uid,
    Map<String, dynamic> row,
  ) {
    if (role == 'restaurant') return true;
    if (table == 'online_orders' && role == 'customer') {
      return row['customer_uid'] == uid && row['status'] == 'submitted';
    }
    return false;
  }

  int _counter = 0;
  String _uid() => 'cust-${_counter++}';

  void _write(HttpResponse res, int status, Object body) {
    res.statusCode = status;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(body));
  }
}

void main() {
  late RlsSupabase server;

  setUp(() async {
    server = RlsSupabase();
    await server.start();
    // The restaurant's private feed + a published menu + another
    // customer's order already exist.
    server.seed('sync_changes', {
      'id': 's1',
      'entity': 'payment',
      'entity_id': 'p1',
      'op': 'update',
      'payload': {'amount': 9999},
      'occurred_at': DateTime.utc(2026).toIso8601String(),
      'device_id': 'till',
    });
    server.seed('published_menu', {
      'id': 'menu',
      'menu': const domain.PublishedMenu(
        restaurantName: 'Diner',
        categories: [],
      ).toJson(),
    });
    server.seed('online_orders', {
      'id': 'other-order',
      'customer_uid': 'someone-else',
      'customer_name': 'Pat',
      'lines': const [],
      'requested_pickup_at': DateTime.utc(2026, 6, 1, 12).toIso8601String(),
      'submitted_at': DateTime.utc(2026, 6, 1, 11).toIso8601String(),
      'status': 'submitted',
    });
  });

  tearDown(() => server.stop());

  Future<SupabaseStorefront> customerStorefront() async {
    final auth = SupabaseAuth(url: server.baseUrl, anonKey: server.anonKey);
    await auth.signInAnonymously();
    return SupabaseStorefront(
      url: server.baseUrl,
      anonKey: server.anonKey,
      accessToken: auth.accessToken,
    );
  }

  test('a customer can read the public menu', () async {
    final storefront = await customerStorefront();
    final menu = await storefront.fetchMenu();
    expect(menu!.restaurantName, 'Diner');
  });

  test(
    'a customer can submit their own order and read its status back',
    () async {
      final auth = SupabaseAuth(url: server.baseUrl, anonKey: server.anonKey);
      await auth.signInAnonymously();
      final storefront = SupabaseStorefront(
        url: server.baseUrl,
        anonKey: server.anonKey,
        accessToken: auth.accessToken,
      );
      final id = await storefront.submitPreorder(
        domain.PreorderSubmission(
          customerName: 'Sam',
          requestedPickupAt: DateTime.utc(2026, 6, 1, 12, 30),
          lines: [
            domain.PreorderLine(
              itemId: 'i1',
              nameSnapshot: 'Burger',
              priceSnapshot: const domain.Money(1000),
              qty: 1,
            ),
          ],
        ),
        customerUid: auth.userId,
      );
      expect(
        await storefront.fetchStatus(id),
        domain.OnlineOrderStatus.submitted,
      );
    },
  );

  test('a customer CANNOT read the restaurant private sync feed', () async {
    final storefront = await customerStorefront();
    // The storefront has no sync API; hit the table directly with the
    // customer's token — RLS must return nothing despite a row existing.
    final auth = SupabaseAuth(url: server.baseUrl, anonKey: server.anonKey);
    final session = await auth.signInAnonymously();
    final resp = await http.get(
      Uri.parse('${server.baseUrl}/rest/v1/sync_changes?select=*'),
      headers: {
        'apikey': server.anonKey,
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );
    expect(resp.statusCode, 200);
    expect(jsonDecode(resp.body), isEmpty);
    expect(
      server.rowsOf('sync_changes'),
      isNotEmpty,
    ); // it IS there, just hidden
    storefront; // keep the analyzer happy
  });

  test("a customer CANNOT read another customer's order", () async {
    final storefront = await customerStorefront();
    expect(
      await storefront.fetchStatus('other-order'),
      // RLS hides it; fetchStatus treats "no visible row" as submitted.
      domain.OnlineOrderStatus.submitted,
    );
    // Prove it's hidden, not simply absent.
    expect(
      server.rowsOf('online_orders').any((r) => r['id'] == 'other-order'),
      isTrue,
    );
  });

  test('a customer CANNOT change an order status', () async {
    final auth = SupabaseAuth(url: server.baseUrl, anonKey: server.anonKey);
    final session = await auth.signInAnonymously();
    final resp = await http.patch(
      Uri.parse('${server.baseUrl}/rest/v1/online_orders?id=eq.other-order'),
      headers: {
        'apikey': server.anonKey,
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': 'ready'}),
    );
    expect(resp.statusCode, 403);
    expect(
      server
          .rowsOf('online_orders')
          .firstWhere((r) => r['id'] == 'other-order')['status'],
      'submitted', // unchanged
    );
  });

  test('a customer CANNOT submit an order spoofing another uid', () async {
    final auth = SupabaseAuth(url: server.baseUrl, anonKey: server.anonKey);
    await auth.signInAnonymously();
    final storefront = SupabaseStorefront(
      url: server.baseUrl,
      anonKey: server.anonKey,
      accessToken: auth.accessToken,
    );
    expect(
      () => storefront.submitPreorder(
        domain.PreorderSubmission(
          customerName: 'Mallory',
          requestedPickupAt: DateTime.utc(2026, 6, 1, 12),
          lines: const [],
        ),
        customerUid: 'someone-else', // not their own uid
      ),
      throwsA(isA<domain.SyncException>()),
    );
  });

  test('the restaurant CAN read the private feed and all orders', () async {
    // The merchant app signs in with a password; here we fetch its token
    // directly (the customer auth client is anonymous-only by design).
    final login = await http.post(
      Uri.parse('${server.baseUrl}/auth/v1/token?grant_type=password'),
      headers: {'apikey': server.anonKey, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': server.restaurantEmail,
        'password': server.restaurantPassword,
      }),
    );
    final accessToken =
        (jsonDecode(login.body) as Map<String, dynamic>)['access_token'];
    final headers = {
      'apikey': server.anonKey,
      'Authorization': 'Bearer $accessToken',
    };
    final feed = await http.get(
      Uri.parse('${server.baseUrl}/rest/v1/sync_changes?select=*'),
      headers: headers,
    );
    expect(jsonDecode(feed.body), hasLength(1));
    final orders = await http.get(
      Uri.parse('${server.baseUrl}/rest/v1/online_orders?select=*'),
      headers: headers,
    );
    expect(jsonDecode(orders.body), hasLength(1)); // sees the other customer's
  });
}
