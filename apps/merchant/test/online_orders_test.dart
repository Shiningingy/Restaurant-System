import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/online_orders/application/inbox_service.dart';
import 'package:merchant/features/online_orders/data/menu_publisher.dart';
import 'package:merchant/features/online_orders/drivers/supabase_online_order_channel.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/core/settings/settings_repository.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_db.dart';

/// Minimal PostgREST emulation for the online-ordering tables: POST
/// (insert / upsert-by-id), GET (col=eq.val filters + order), PATCH
/// (id=eq.x sets fields). Enough to drive the real channel end-to-end.
class FakeSupabase {
  final String apiKey;
  final Map<String, List<Map<String, dynamic>>> tables = {};
  late final HttpServer _server;

  FakeSupabase({this.apiKey = 'anon'});

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  List<Map<String, dynamic>> rowsOf(String table) => tables[table] ?? [];

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    if (req.headers.value('apikey') != apiKey) {
      res.statusCode = HttpStatus.unauthorized;
      await res.close();
      return;
    }
    final table = req.uri.pathSegments.last; // .../rest/v1/<table>
    final rows = tables.putIfAbsent(table, () => []);
    final q = req.uri.queryParameters;
    final body = req.method == 'GET'
        ? null
        : await utf8.decoder.bind(req).join();

    switch (req.method) {
      case 'POST':
        final decoded = jsonDecode(body!);
        final incoming = decoded is List ? decoded : [decoded];
        final upsert =
            req.headers.value('Prefer')?.contains('merge-duplicates') ?? false;
        for (final row in incoming.cast<Map<String, dynamic>>()) {
          if (upsert) rows.removeWhere((r) => r['id'] == row['id']);
          rows.add(row);
        }
        res.statusCode = HttpStatus.created;
        break;
      case 'PATCH':
        final patch = jsonDecode(body!) as Map<String, dynamic>;
        final matched = rows.where((r) => _matches(r, q)).toList();
        for (final row in matched) {
          row.addAll(patch);
        }
        res.statusCode = HttpStatus.ok;
        // PostgREST returns the changed rows when asked — drives the atomic
        // claim (a non-empty array means this device won the claim).
        if (req.headers.value('Prefer')?.contains('return=representation') ??
            false) {
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode(matched));
        }
        break;
      case 'GET':
        var result = rows.where((r) => _matches(r, q)).toList();
        res.statusCode = HttpStatus.ok;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(result));
        break;
      default:
        res.statusCode = HttpStatus.methodNotAllowed;
    }
    await res.close();
  }

  bool _matches(Map<String, dynamic> row, Map<String, String> q) {
    for (final entry in q.entries) {
      if (const {'select', 'order', 'limit'}.contains(entry.key)) continue;
      if (entry.value.startsWith('eq.')) {
        if ('${row[entry.key]}' != entry.value.substring(3)) return false;
      }
    }
    return true;
  }
}

void main() {
  late FakeSupabase server;

  setUp(() async {
    server = FakeSupabase();
    await server.start();
  });
  tearDown(() => server.stop());

  /// Simulates the customer app submitting a preorder.
  Future<String> submitPreorder(domain.PreorderSubmission sub) async {
    final id = domain.newId();
    await http.post(
      Uri.parse('${server.baseUrl}/rest/v1/online_orders'),
      headers: {'apikey': server.apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode([
        {
          'id': id,
          'customer_name': sub.customerName,
          'customer_phone': sub.customerPhone,
          'lines': sub.lines.map((l) => l.toJson()).toList(),
          'requested_pickup_at': sub.requestedPickupAt.toIso8601String(),
          'submitted_at': DateTime.utc(2026, 6, 1, 11).toIso8601String(),
          'status': 'submitted',
        },
      ]),
    );
    return id;
  }

  Future<InboxService> buildInbox() async {
    final db = createTestDb();
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsRepository(prefs);
    await settings.setBusinessName('Test Diner');
    final menu = MenuRepository(db);
    return InboxService(
      channel: SupabaseOnlineOrderChannel(
        url: server.baseUrl,
        anonKey: server.apiKey,
      ),
      orders: OrderRepository(db),
      settings: settings,
      publisher: MenuPublisher(menu: menu, settings: settings),
    );
  }

  test('preorder submitted -> accepted -> ready, and becomes a local '
      'online order (Phase 6 exit criterion, over HTTP)', () async {
    final inbox = await buildInbox();
    final orders = inbox.orders;

    final onlineId = await submitPreorder(
      domain.PreorderSubmission(
        customerName: 'Sam',
        customerPhone: '555-0100',
        requestedPickupAt: DateTime.utc(2026, 6, 1, 12, 30),
        lines: [
          domain.PreorderLine(
            itemId: 'i1',
            nameSnapshot: 'Burger',
            priceSnapshot: const domain.Money(1000),
            qty: 2,
            modifiers: const [
              domain.PreorderModifier(
                nameSnapshot: 'Large',
                priceDeltaSnapshot: domain.Money(200),
              ),
            ],
          ),
        ],
      ),
    );

    // The merchant sees the new preorder.
    final pending = await inbox.currentPending();
    expect(pending.single.customerName, 'Sam');

    // Accept it -> a local online order is created, status pushed back.
    final localId = (await inbox.accept(pending.single))!;
    final order = (await orders.getOrder(localId))!;
    expect(order.type, domain.OrderType.online);
    // (1000+200) * 2 = 2400 subtotal; 13% tax -> 312; total 2712.
    expect(order.subtotal, const domain.Money(2400));
    expect(order.total, const domain.Money(2712));
    final lines = await orders.getLines(localId);
    expect(lines.single.nameSnapshot, 'Burger');
    expect(lines.single.modifiers.single.nameSnapshot, 'Large');
    expect(order.note, contains('Sam'));

    // Server row is now accepted; no longer pending.
    expect(server.rowsOf('online_orders').single['status'], 'accepted');
    expect(await inbox.currentPending(), isEmpty);

    // Mark ready -> the customer would see "ready".
    await inbox.markReady(onlineId);
    expect(server.rowsOf('online_orders').single['status'], 'ready');
  });

  test(
    'rejecting a preorder sets its status and creates no local order',
    () async {
      final inbox = await buildInbox();
      await submitPreorder(
        domain.PreorderSubmission(
          customerName: 'Lee',
          requestedPickupAt: DateTime.utc(2026, 6, 1, 12),
          lines: [
            domain.PreorderLine(
              itemId: 'i1',
              nameSnapshot: 'Fries',
              priceSnapshot: const domain.Money(350),
              qty: 1,
            ),
          ],
        ),
      );
      final pending = await inbox.currentPending();
      await inbox.reject(pending.single.id);

      expect(server.rowsOf('online_orders').single['status'], 'rejected');
      expect(await inbox.orders.watchOpenOrders().first, isEmpty);
    },
  );

  test(
    'kiosk order auto-accepts to a local order; the claim is atomic',
    () async {
      final inbox = await buildInbox();

      // A kiosk order carries is_kiosk = true.
      await http.post(
        Uri.parse('${server.baseUrl}/rest/v1/online_orders'),
        headers: {'apikey': server.apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode([
          {
            'id': domain.newId(),
            'customer_name': 'Kiosk 3',
            'lines': [
              domain.PreorderLine(
                itemId: 'i1',
                nameSnapshot: 'Tea',
                priceSnapshot: const domain.Money(300),
                qty: 1,
              ).toJson(),
            ],
            'requested_pickup_at': DateTime.utc(
              2026,
              6,
              1,
              12,
            ).toIso8601String(),
            'submitted_at': DateTime.utc(2026, 6, 1, 11).toIso8601String(),
            'status': 'submitted',
            'is_kiosk': true,
          },
        ]),
      );

      final pending = await inbox.currentPending();
      expect(pending.single.kiosk, isTrue);

      // Auto-accept → a local online order appears on the board, server accepted.
      await inbox.autoAcceptKiosk(pending);
      final board = await inbox.orders.watchOpenOrders().first;
      expect(
        board.where((o) => o.type == domain.OrderType.online),
        hasLength(1),
      );
      expect(server.rowsOf('online_orders').single['status'], 'accepted');

      // A second claim loses — it's no longer 'submitted' (no double-build).
      expect(await inbox.channel.claimForAccept(pending.single.id), isFalse);
    },
  );

  test('publishMenu writes the live menu to the storefront table', () async {
    final inbox = await buildInbox();
    final menu = MenuRepository(inbox.orders.db);
    final cat = domain.Category(id: domain.newId(), name: 'Mains');
    await menu.upsertCategory(cat);
    await menu.upsertItem(
      domain.MenuItem(
        id: domain.newId(),
        categoryId: cat.id,
        name: 'Burger',
        price: const domain.Money(1000),
      ),
    );

    await inbox.publishMenu();

    final row = server.rowsOf('published_menu').single;
    final published = domain.PublishedMenu.fromJson(
      row['menu'] as Map<String, dynamic>,
    );
    expect(published.restaurantName, 'Test Diner');
    expect(published.categories.single.name, 'Mains');
    expect(published.categories.single.items.single.name, 'Burger');
  });
}
