// ignore_for_file: avoid_print
//
// Live cloud smoke test — runs the docs/CLOUD_SECURITY.md model against a
// REAL Supabase project to close the pre-deployment cloud-security gate.
//
// It proves, over real HTTP against your project:
//   • the restaurant (password login) can write its private sync feed and menu;
//   • a customer (anonymous login) can read the menu and submit/track their own
//     order;
//   • a customer CANNOT read the sync feed, read another customer's order,
//     change an order's status, or spoof another customer's uid;
//   • the restaurant can see and manage everything.
//
// Nothing secret is committed — credentials come from environment variables:
//
//   SUPABASE_URL=https://<ref>.supabase.co \
//   SUPABASE_ANON_KEY=<anon/publishable key> \
//   RESTAURANT_EMAIL=<the user you created in Auth → Users> \
//   RESTAURANT_PASSWORD=<that user's password> \
//   dart run tool/live_cloud_smoke_test.dart
//
// Prerequisites in the Supabase dashboard (see docs/CLOUD_SECURITY.md):
//   1. Run the SQL in that doc (tables + RLS policies).
//   2. Authentication → Users: create the restaurant login user.
//   3. Authentication → Providers → Anonymous: enable.
//
// Exit code 0 = every check passed; non-zero = something is wrong (the gate
// is NOT closed). The script cleans up the test rows it creates.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

late final String baseUrl;
late final String anonKey;

int _passed = 0;
int _failed = 0;
final List<String> _createdSync = [];
final List<String> _createdOrders = [];

void main() async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_ANON_KEY'];
  final email = Platform.environment['RESTAURANT_EMAIL'];
  final password = Platform.environment['RESTAURANT_PASSWORD'];

  if ([url, key, email, password].any((v) => v == null || v.isEmpty)) {
    stderr.writeln(
      'Missing env vars. Set SUPABASE_URL, SUPABASE_ANON_KEY, '
      'RESTAURANT_EMAIL, RESTAURANT_PASSWORD.',
    );
    exit(2);
  }
  baseUrl = url!.replaceAll(RegExp(r'/+$'), '');
  anonKey = key!;

  print('▶ Live cloud smoke test against $baseUrl\n');

  try {
    // ── Auth ────────────────────────────────────────────────────────────
    final restaurant = await _signInPassword(email!, password!);
    await check('restaurant signs in (authenticated, not anonymous)', () async {
      if (restaurant.isAnonymous) throw 'token is flagged anonymous';
    });

    final customerA = await _signInAnonymous();
    await check('customer A signs in anonymously', () async {
      if (!customerA.isAnonymous) throw 'token is not flagged anonymous';
      if (customerA.uid.isEmpty) throw 'no uid in token';
    });

    // ── Restaurant happy path ───────────────────────────────────────────
    final syncId = _uuid();
    await check('restaurant writes a sync_changes row', () async {
      await _post('sync_changes', restaurant.token, {
        'id': syncId,
        'entity': 'payment',
        'entity_id': _uuid(),
        'op': 'update',
        'payload': {'amount': 9999},
        'occurred_at': _nowIso(),
        'device_id': 'smoke-till',
      });
      _createdSync.add(syncId);
    });

    await check('restaurant publishes the menu', () async {
      await _post('published_menu', restaurant.token, {
        'id': 'smoke-menu',
        'menu': {'restaurantName': 'Smoke Test Diner', 'categories': []},
        'published_at': _nowIso(),
      }, upsert: true);
    });

    // ── Customer happy path ─────────────────────────────────────────────
    await check('customer reads the public published menu', () async {
      final rows = await _get(
        'published_menu?id=eq.smoke-menu',
        customerA.token,
      );
      if (rows.isEmpty) throw 'menu not visible to customer';
      final name = (rows.first['menu'] as Map)['restaurantName'];
      if (name != 'Smoke Test Diner') throw 'unexpected menu: $name';
    });

    final orderId = _uuid();
    await check('customer A submits their own order', () async {
      await _post('online_orders', customerA.token, {
        'id': orderId,
        'customer_uid': customerA.uid,
        'customer_name': 'Sam',
        'lines': [
          {
            'itemId': 'i1',
            'nameSnapshot': 'Burger',
            'priceSnapshot': 1000,
            'qty': 1,
          },
        ],
        'requested_pickup_at': _nowIso(),
        'status': 'submitted',
      });
      _createdOrders.add(orderId);
    });

    await check('customer A reads back their own order status', () async {
      final rows = await _get(
        'online_orders?id=eq.$orderId&select=status',
        customerA.token,
      );
      if (rows.isEmpty) throw 'customer cannot see their own order';
      if (rows.first['status'] != 'submitted') {
        throw 'wrong status: ${rows.first['status']}';
      }
    });

    // ── RLS denials ─────────────────────────────────────────────────────
    await check(
      'customer CANNOT read the private sync feed (hidden by RLS)',
      () async {
        final rows = await _get('sync_changes?select=*', customerA.token);
        if (rows.isNotEmpty) {
          throw 'LEAK: customer saw ${rows.length} sync row(s)';
        }
      },
    );

    final customerB = await _signInAnonymous();
    await check("customer B CANNOT read customer A's order", () async {
      final rows = await _get(
        'online_orders?id=eq.$orderId&select=*',
        customerB.token,
      );
      if (rows.isNotEmpty) {
        throw "LEAK: customer B saw another customer's order";
      }
    });

    await check(
      'customer B CANNOT change an order status (no UPDATE policy)',
      () async {
        final resp = await http.patch(
          Uri.parse('$baseUrl/rest/v1/online_orders?id=eq.$orderId'),
          headers: _headers(customerB.token, json: true),
          body: jsonEncode({'status': 'ready'}),
        );
        // RLS yields either 403 or a silent no-op (200 affecting 0 rows). Verify
        // via the restaurant that the status is unchanged below; here just ensure
        // it did not error in our favour.
        if (resp.statusCode >= 500) {
          throw 'server error: ${resp.statusCode} ${resp.body}';
        }
      },
    );

    await check(
      'customer CANNOT submit an order spoofing another uid',
      () async {
        final resp = await http.post(
          Uri.parse('$baseUrl/rest/v1/online_orders'),
          headers: _headers(customerA.token, json: true),
          body: jsonEncode({
            'id': _uuid(),
            'customer_uid': customerB.uid, // not their own
            'customer_name': 'Mallory',
            'lines': [],
            'requested_pickup_at': _nowIso(),
            'status': 'submitted',
          }),
        );
        if (resp.statusCode < 400) {
          throw 'SPOOF ACCEPTED: status ${resp.statusCode}';
        }
      },
    );

    // ── Restaurant full access ──────────────────────────────────────────
    await check('restaurant sees the private sync feed', () async {
      final rows = await _get(
        'sync_changes?id=eq.$syncId&select=*',
        restaurant.token,
      );
      if (rows.isEmpty) throw 'restaurant cannot see its own sync row';
    });

    await check("restaurant sees the customer's order", () async {
      final rows = await _get(
        'online_orders?id=eq.$orderId&select=*',
        restaurant.token,
      );
      if (rows.isEmpty) throw 'restaurant cannot see the order';
    });

    await check(
      'restaurant marks the order ready; status really is unchanged-then-ready',
      () async {
        // Confirm the customer PATCH above did NOT change it.
        final before = await _get(
          'online_orders?id=eq.$orderId&select=status',
          restaurant.token,
        );
        if (before.first['status'] != 'submitted') {
          throw 'LEAK: customer changed status to ${before.first['status']}';
        }
        await http.patch(
          Uri.parse('$baseUrl/rest/v1/online_orders?id=eq.$orderId'),
          headers: _headers(restaurant.token, json: true),
          body: jsonEncode({'status': 'ready'}),
        );
        final after = await _get(
          'online_orders?id=eq.$orderId&select=status',
          restaurant.token,
        );
        if (after.first['status'] != 'ready') {
          throw 'restaurant update did not take';
        }
      },
    );

    await check('customer A sees the restaurant-set ready status', () async {
      final rows = await _get(
        'online_orders?id=eq.$orderId&select=status',
        customerA.token,
      );
      if (rows.first['status'] != 'ready') throw 'customer did not see ready';
    });

    // ── Cleanup ─────────────────────────────────────────────────────────
    await _cleanup(restaurant.token);
  } catch (e) {
    stderr.writeln('\n✗ Aborted: $e');
    await _bestEffortCleanupNote();
    exit(1);
  }

  print('\n${'─' * 50}');
  if (_failed == 0) {
    print('✓ ALL $_passed CHECKS PASSED — cloud-security gate is closed. 🎉');
    exit(0);
  } else {
    print('✗ $_failed FAILED, $_passed passed — gate is NOT closed.');
    exit(1);
  }
}

// ── helpers ───────────────────────────────────────────────────────────────

class _Session {
  final String token;
  final String uid;
  final bool isAnonymous;
  _Session(this.token, this.uid, this.isAnonymous);
}

Future<_Session> _signInPassword(String email, String password) async {
  final resp = await http.post(
    Uri.parse('$baseUrl/auth/v1/token?grant_type=password'),
    headers: {'apikey': anonKey, 'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  if (resp.statusCode != 200) {
    throw 'restaurant sign-in failed (${resp.statusCode}): ${resp.body}\n'
        '→ create this user in Authentication → Users.';
  }
  return _sessionFrom(resp.body);
}

Future<_Session> _signInAnonymous() async {
  final resp = await http.post(
    Uri.parse('$baseUrl/auth/v1/signup'),
    headers: {'apikey': anonKey, 'Content-Type': 'application/json'},
    body: '{}',
  );
  if (resp.statusCode != 200) {
    throw 'anonymous sign-in failed (${resp.statusCode}): ${resp.body}\n'
        '→ enable Authentication → Providers → Anonymous.';
  }
  return _sessionFrom(resp.body);
}

_Session _sessionFrom(String body) {
  final m = jsonDecode(body) as Map<String, dynamic>;
  final token = m['access_token'] as String;
  final claims = _decodeJwt(token);
  return _Session(
    token,
    (claims['sub'] ?? '') as String,
    (claims['is_anonymous'] ?? false) as bool,
  );
}

Map<String, dynamic> _decodeJwt(String jwt) {
  final parts = jwt.split('.');
  final payload = parts[1];
  final normalized = base64Url.normalize(payload);
  return jsonDecode(utf8.decode(base64Url.decode(normalized)))
      as Map<String, dynamic>;
}

Map<String, String> _headers(String token, {bool json = false}) => {
  'apikey': anonKey,
  'Authorization': 'Bearer $token',
  if (json) 'Content-Type': 'application/json',
};

Future<List<Map<String, dynamic>>> _get(
  String pathAndQuery,
  String token,
) async {
  final resp = await http.get(
    Uri.parse('$baseUrl/rest/v1/$pathAndQuery'),
    headers: _headers(token),
  );
  if (resp.statusCode != 200) {
    throw 'GET $pathAndQuery → ${resp.statusCode}: ${resp.body}';
  }
  return (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
}

Future<void> _post(
  String table,
  String token,
  Map<String, dynamic> row, {
  bool upsert = false,
}) async {
  final resp = await http.post(
    Uri.parse('$baseUrl/rest/v1/$table'),
    headers: {
      ..._headers(token, json: true),
      if (upsert) 'Prefer': 'resolution=merge-duplicates',
    },
    body: jsonEncode(row),
  );
  if (resp.statusCode >= 300) {
    throw 'POST $table → ${resp.statusCode}: ${resp.body}';
  }
}

Future<void> _cleanup(String restaurantToken) async {
  for (final id in _createdOrders) {
    await http.delete(
      Uri.parse('$baseUrl/rest/v1/online_orders?id=eq.$id'),
      headers: _headers(restaurantToken),
    );
  }
  for (final id in _createdSync) {
    await http.delete(
      Uri.parse('$baseUrl/rest/v1/sync_changes?id=eq.$id'),
      headers: _headers(restaurantToken),
    );
  }
  await http.delete(
    Uri.parse('$baseUrl/rest/v1/published_menu?id=eq.smoke-menu'),
    headers: _headers(restaurantToken),
  );
  print(
    '\n  (cleaned up ${_createdOrders.length} order(s), '
    '${_createdSync.length} sync row(s), 1 menu)',
  );
}

Future<void> _bestEffortCleanupNote() async {
  if (_createdOrders.isNotEmpty || _createdSync.isNotEmpty) {
    stderr.writeln(
      '  note: test rows may remain (orders: $_createdOrders, sync: $_createdSync) '
      '— delete from the dashboard if needed.',
    );
  }
}

Future<void> check(String name, Future<void> Function() body) async {
  try {
    await body();
    _passed++;
    print('  ✓ $name');
  } catch (e) {
    _failed++;
    print('  ✗ $name\n      $e');
  }
}

String _nowIso() => DateTime.now().toUtc().toIso8601String();

final _rng = Random.secure();
String _uuid() {
  final b = List<int>.generate(16, (_) => _rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final s = b.asMap().keys.map(h).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}'
      '-${s.substring(16, 20)}-${s.substring(20)}';
}
