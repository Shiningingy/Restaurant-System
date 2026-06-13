import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Real [domain.SyncBackend] over the restaurant's own Supabase project.
///
/// This is the ONLY place that knows the Supabase wire format (the
/// hardware/cloud-abstraction rule, docs/ARCHITECTURE.md). It talks to a
/// single PostgREST table, `sync_changes`.
///
/// `sync_changes` is the restaurant's **private** feed: the table's RLS
/// must deny the customer-facing key entirely and allow only the
/// authenticated restaurant. The exact table DDL and RLS policies live in
/// docs/CLOUD_SECURITY.md (applied to the restaurant's project before any
/// live rollout — a blocking gate in docs/ROADMAP.md). Do NOT ship an
/// `using (true)` policy.
///
/// The feed is append-only and upsert-by-id, so re-pushing the same
/// change is idempotent. Pull skips this device's own rows by
/// [deviceId]; conflicts resolve last-write-wins by `occurred_at`.
class SupabaseSyncBackend implements domain.SyncBackend {
  final Uri baseUrl;
  final String anonKey;
  final String deviceId;
  final http.Client _client;
  final Duration timeout;

  SupabaseSyncBackend({
    required String url,
    required this.anonKey,
    required this.deviceId,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
       _client = client ?? http.Client();

  static const _table = 'sync_changes';

  Map<String, String> get _headers => {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  Uri _rest([Map<String, dynamic>? query]) => baseUrl
      .resolve('rest/v1/$_table')
      .replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));

  @override
  Future<void> push(List<domain.SyncLogEntry> changes) async {
    if (changes.isEmpty) return;
    final rows = [
      for (final c in changes)
        {
          'id': c.id,
          'entity': c.entity,
          'entity_id': c.entityId,
          'op': c.op.name,
          'payload': c.payloadJson.isEmpty ? null : jsonDecode(c.payloadJson),
          'occurred_at': c.createdAt.toUtc().toIso8601String(),
          'device_id': deviceId,
        },
    ];
    final resp = await _client
        .post(
          _rest(),
          headers: {..._headers, 'Prefer': 'resolution=merge-duplicates'},
          body: jsonEncode(rows),
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('push failed (${resp.statusCode})');
    }
  }

  @override
  Future<List<domain.RemoteChange>> pull({required DateTime since}) async {
    final resp = await _client
        .get(
          _rest({
            'select': 'entity,entity_id,op,payload,occurred_at',
            'occurred_at': 'gt.${since.toUtc().toIso8601String()}',
            'device_id': 'neq.$deviceId',
            'order': 'occurred_at.asc',
          }),
          headers: _headers,
        )
        .timeout(timeout);
    if (resp.statusCode >= 300) {
      throw domain.SyncException('pull failed (${resp.statusCode})');
    }
    final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
    return [
      for (final r in list)
        domain.RemoteChange(
          entity: r['entity'] as String,
          entityId: r['entity_id'] as String,
          op: domain.SyncOp.values.byName(r['op'] as String),
          payloadJson: r['payload'] == null ? '' : jsonEncode(r['payload']),
          occurredAt: DateTime.parse(r['occurred_at'] as String),
        ),
    ];
  }

  @override
  Future<domain.SyncHealth> healthCheck() async {
    try {
      final resp = await _client
          .get(_rest({'select': 'id', 'limit': '1'}), headers: _headers)
          .timeout(timeout);
      if (resp.statusCode == 200) return domain.SyncHealth.ok;
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        return domain.SyncHealth.authFailed;
      }
      return domain.SyncHealth.unreachable;
    } on Object {
      return domain.SyncHealth.unreachable;
    }
  }
}
