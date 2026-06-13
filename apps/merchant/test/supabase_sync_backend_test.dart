import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/sync/data/sync_settings.dart';
import 'package:merchant/features/sync/drivers/supabase_sync_backend.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/sync_harness.dart';

/// A minimal in-process emulation of the restaurant's Supabase
/// (PostgREST) `sync_changes` table — enough to exercise the REAL
/// [SupabaseSyncBackend] over HTTP: upsert-by-id on POST, and the
/// `occurred_at=gt.` / `device_id=neq.` / `order=` query operators on
/// GET. Checks `apikey` so the auth path is real too.
class FakePostgrest {
  final String apiKey;
  final List<Map<String, dynamic>> rows = [];
  late final HttpServer _server;

  FakePostgrest({this.apiKey = 'test-anon-key'});

  String get baseUrl => 'http://127.0.0.1:${_server.port}';
  int get requestCount => _requestCount;
  int _requestCount = 0;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest req) async {
    _requestCount++;
    final res = req.response;

    // Auth: PostgREST requires the apikey header.
    if (req.headers.value('apikey') != apiKey) {
      res.statusCode = HttpStatus.unauthorized;
      await res.close();
      return;
    }
    if (!req.uri.path.endsWith('/sync_changes')) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }

    if (req.method == 'POST') {
      // Upsert-by-id (Prefer: resolution=merge-duplicates).
      final body = (jsonDecode(await utf8.decoder.bind(req).join()) as List)
          .cast<Map<String, dynamic>>();
      for (final row in body) {
        rows.removeWhere((r) => r['id'] == row['id']);
        rows.add(row);
      }
      res.statusCode = HttpStatus.created;
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode(body));
      await res.close();
      return;
    }

    if (req.method == 'GET') {
      final q = req.uri.queryParameters;
      var result = List<Map<String, dynamic>>.from(rows);

      final occurred = q['occurred_at']; // e.g. "gt.2026-01-01T..."
      if (occurred != null && occurred.startsWith('gt.')) {
        final since = DateTime.parse(occurred.substring(3));
        result = result
            .where(
              (r) => DateTime.parse(r['occurred_at'] as String).isAfter(since),
            )
            .toList();
      }
      final device = q['device_id']; // e.g. "neq.<id>"
      if (device != null && device.startsWith('neq.')) {
        final id = device.substring(4);
        result = result.where((r) => r['device_id'] != id).toList();
      }
      if (q['order'] == 'occurred_at.asc') {
        result.sort(
          (a, b) => DateTime.parse(
            a['occurred_at'] as String,
          ).compareTo(DateTime.parse(b['occurred_at'] as String)),
        );
      }
      final limit = int.tryParse(q['limit'] ?? '');
      if (limit != null && result.length > limit) {
        result = result.sublist(0, limit);
      }

      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode(result));
      await res.close();
      return;
    }

    res.statusCode = HttpStatus.methodNotAllowed;
    await res.close();
  }
}

void main() {
  late FakePostgrest server;

  setUp(() async {
    server = FakePostgrest();
    await server.start();
  });

  tearDown(() => server.stop());

  SupabaseSyncBackend backendFor(String deviceId) => SupabaseSyncBackend(
    url: server.baseUrl,
    anonKey: server.apiKey,
    deviceId: deviceId,
  );

  group('SupabaseSyncBackend over HTTP', () {
    test('healthCheck maps status codes', () async {
      expect(await backendFor('A').healthCheck(), SyncHealth.ok);

      final badKey = SupabaseSyncBackend(
        url: server.baseUrl,
        anonKey: 'wrong',
        deviceId: 'A',
      );
      expect(await badKey.healthCheck(), SyncHealth.authFailed);

      final dead = SupabaseSyncBackend(
        url: 'http://127.0.0.1:1', // nothing listening
        anonKey: 'k',
        deviceId: 'A',
      );
      expect(await dead.healthCheck(), SyncHealth.unreachable);
    });

    test('push then pull round-trips a change with the wire format '
        'intact, filtering out the puller\'s own device', () async {
      final a = backendFor('A');
      final b = backendFor('B');
      final at = DateTime.utc(2026, 6, 1, 12, 30, 45, 123, 456);

      await a.push([
        SyncLogEntry(
          id: 'c1',
          entity: 'category',
          entityId: 'cat1',
          op: SyncOp.update,
          payloadJson: '{"id":"cat1","name":"Mains"}',
          createdAt: at,
        ),
      ]);

      // B sees A's change; A does not see its own.
      final forB = await b.pull(since: SyncSettings.epoch);
      expect(forB, hasLength(1));
      expect(forB.single.entity, 'category');
      expect(forB.single.op, SyncOp.update);
      expect(jsonDecode(forB.single.payloadJson)['name'], 'Mains');
      // Microsecond precision survives the JSON/timestamptz round-trip.
      expect(forB.single.occurredAt.toUtc(), at);

      expect(await a.pull(since: SyncSettings.epoch), isEmpty);
    });

    test('pull respects the occurred_at cursor', () async {
      final a = backendFor('A');
      final t1 = DateTime.utc(2026, 1, 1);
      final t2 = DateTime.utc(2026, 1, 2);
      await a.push([
        SyncLogEntry(
          id: 'c1',
          entity: 'category',
          entityId: 'x',
          op: SyncOp.update,
          payloadJson: '{}',
          createdAt: t1,
        ),
        SyncLogEntry(
          id: 'c2',
          entity: 'category',
          entityId: 'y',
          op: SyncOp.update,
          payloadJson: '{}',
          createdAt: t2,
        ),
      ]);
      final after = await backendFor('B').pull(since: t1);
      expect(after.map((c) => c.entityId), ['y']);
    });

    test('push is an idempotent upsert by id', () async {
      final a = backendFor('A');
      entry(String name) => SyncLogEntry(
        id: 'c1',
        entity: 'category',
        entityId: 'cat1',
        op: SyncOp.update,
        payloadJson: '{"name":"$name"}',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await a.push([entry('First')]);
      await a.push([entry('Second')]); // same id, re-pushed
      final rows = await backendFor('B').pull(since: SyncSettings.epoch);
      expect(rows, hasLength(1));
      expect(jsonDecode(rows.single.payloadJson)['name'], 'Second');
    });

    test('delete ops carry a null payload over the wire', () async {
      await backendFor('A').push([
        SyncLogEntry(
          id: 'd1',
          entity: 'modifier',
          entityId: 'm1',
          op: SyncOp.delete,
          payloadJson: '',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ]);
      final rows = await backendFor('B').pull(since: SyncSettings.epoch);
      expect(rows.single.op, SyncOp.delete);
      expect(rows.single.payloadJson, '');
    });
  });

  test('a wiped tablet restores its data over real HTTP '
      '(Phase 5 exit criterion, against an emulated Supabase)', () async {
    final clock = TickingClock();
    final a = await makeDevice(clock, 'A', buildBackend: () => backendFor('A'));
    addTearDown(a.db.close);
    final seed = await seedBusiness(a);

    final pushed = await a.sync.syncNow();
    expect(pushed.ok, isTrue, reason: pushed.error);
    expect(pushed.pushed, greaterThan(0));
    expect(server.rows, isNotEmpty); // it really went over the wire

    final b = await makeDevice(clock, 'B', buildBackend: () => backendFor('B'));
    addTearDown(b.db.close);
    final restore = await b.sync.restoreFromCloud();
    expect(restore.ok, isTrue, reason: restore.error);
    expect(restore.pulled, greaterThan(0));

    await expectDevicesMatch(a, b, seed);
  });
}
