import 'dart:convert';
import 'dart:io';

import 'package:customer/features/storefront/drivers/supabase_storefront.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Minimal PostgREST emulation for the storefront tables, mirroring the
/// merchant side: GET with col=eq.val filters, POST insert, PATCH by id
/// (used here to simulate the merchant changing a preorder's status).
class FakeStorefrontServer {
  final String apiKey;
  final Map<String, List<Map<String, dynamic>>> tables = {};
  late final HttpServer _server;

  FakeStorefrontServer({this.apiKey = 'anon'});

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  void seed(String table, Map<String, dynamic> row) =>
      tables.putIfAbsent(table, () => []).add(row);

  List<Map<String, dynamic>> rowsOf(String t) => tables[t] ?? [];

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    if (req.headers.value('apikey') != apiKey) {
      res.statusCode = HttpStatus.unauthorized;
      await res.close();
      return;
    }
    final table = req.uri.pathSegments.last;
    final rows = tables.putIfAbsent(table, () => []);
    final q = req.uri.queryParameters;
    final body = req.method == 'GET'
        ? null
        : await utf8.decoder.bind(req).join();

    bool matches(Map<String, dynamic> r) {
      for (final e in q.entries) {
        if (const {'select', 'order', 'limit'}.contains(e.key)) continue;
        if (e.value.startsWith('eq.') &&
            '${r[e.key]}' != e.value.substring(3)) {
          return false;
        }
      }
      return true;
    }

    switch (req.method) {
      case 'POST':
        for (final r
            in (jsonDecode(body!) as List).cast<Map<String, dynamic>>()) {
          rows.add(r);
        }
        res.statusCode = HttpStatus.created;
        break;
      case 'PATCH':
        final patch = jsonDecode(body!) as Map<String, dynamic>;
        for (final r in rows.where(matches)) {
          r.addAll(patch);
        }
        res.statusCode = HttpStatus.ok;
        break;
      case 'GET':
        res.statusCode = HttpStatus.ok;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(rows.where(matches).toList()));
        break;
      default:
        res.statusCode = HttpStatus.methodNotAllowed;
    }
    await res.close();
  }
}

void main() {
  late FakeStorefrontServer server;
  late SupabaseStorefront storefront;

  setUp(() async {
    server = FakeStorefrontServer();
    await server.start();
    storefront = SupabaseStorefront(
      url: server.baseUrl,
      anonKey: server.apiKey,
    );
  });
  tearDown(() => server.stop());

  test('fetchMenu parses the published menu', () async {
    const menu = domain.PublishedMenu(
      restaurantName: 'Test Diner',
      categories: [
        domain.PublishedCategory(
          id: 'c1',
          name: 'Mains',
          items: [
            domain.PublishedItem(
              id: 'i1',
              name: 'Burger',
              price: domain.Money(1000),
            ),
          ],
        ),
      ],
    );
    server.seed('published_menu', {'id': 'menu', 'menu': menu.toJson()});

    final fetched = await storefront.fetchMenu();
    expect(fetched!.restaurantName, 'Test Diner');
    expect(fetched.categories.single.items.single.name, 'Burger');
  });

  test('fetchMenu returns null when nothing is published', () async {
    expect(await storefront.fetchMenu(), isNull);
  });

  test('submit a preorder, then watch it through to ready '
      '(Phase 6 exit criterion, customer side)', () async {
    final orderId = await storefront.submitPreorder(
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
    );

    // The row landed with status submitted.
    final row = server.rowsOf('online_orders').single;
    expect(row['id'], orderId);
    expect(row['customer_name'], 'Sam');
    expect(row['status'], 'submitted');
    expect(
      await storefront.fetchStatus(orderId),
      domain.OnlineOrderStatus.submitted,
    );

    // The merchant accepts, then marks ready (simulated via PATCH).
    row['status'] = 'accepted';
    expect(
      await storefront.fetchStatus(orderId),
      domain.OnlineOrderStatus.accepted,
    );
    row['status'] = 'ready';

    // watchState streams the current status and stops at a terminal one.
    final seen = <domain.OnlineOrderStatus>[];
    await for (final s in storefront.watchState(
      orderId,
      interval: const Duration(milliseconds: 1),
    )) {
      seen.add(s.status);
      if (s.status == domain.OnlineOrderStatus.ready) {
        row['status'] = 'pickedUp'; // customer collects
      }
      if (s.status == domain.OnlineOrderStatus.pickedUp) break;
    }
    expect(seen, contains(domain.OnlineOrderStatus.ready));
    expect(seen.last, domain.OnlineOrderStatus.pickedUp);
  });
}
