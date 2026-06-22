import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// A signed-in Supabase session.
class SupabaseSession {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final DateTime expiresAt;

  const SupabaseSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.expiresAt,
  });

  bool get isExpiring =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));
}

/// Minimal GoTrue client for the customer app. The customer signs in
/// **anonymously** (no account), which gives the device a stable
/// `auth.uid()` so RLS can scope a preorder to its owner — the customer
/// can read only their own order, never the restaurant's private data
/// (docs/CLOUD_SECURITY.md). The only place the customer app talks to
/// Supabase Auth.
class SupabaseAuth {
  final Uri baseUrl;
  final String anonKey;
  final http.Client _client;
  final Duration timeout;

  /// Called with every newly-minted session (sign-in and refresh). Supabase
  /// rotates the refresh token on each refresh, so the caller must persist the
  /// new one or the stored token goes stale and the next launch's refresh 400s.
  final void Function(SupabaseSession session)? onSession;

  SupabaseSession? _session;

  SupabaseAuth({
    required String url,
    required this.anonKey,
    http.Client? client,
    this.onSession,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
       _client = client ?? http.Client();

  SupabaseSession? get session => _session;
  String? get userId => _session?.userId;

  Uri _auth(String path, [Map<String, dynamic>? query]) => baseUrl
      .resolve('auth/v1/$path')
      .replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));

  Map<String, String> get _headers => {
    'apikey': anonKey,
    'Content-Type': 'application/json',
  };

  Future<SupabaseSession> signInAnonymously() async {
    final resp = await _client
        .post(_auth('signup'), headers: _headers, body: jsonEncode({}))
        .timeout(timeout);
    return _session = _parse(resp);
  }

  /// Signs in with the restaurant's email + password. Used only to authorize a
  /// staff action on the device (turning it into a kiosk) — the customer app
  /// otherwise runs anonymously, so the session isn't persisted. Throws on bad
  /// credentials (non-2xx).
  Future<SupabaseSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final resp = await _client
        .post(
          _auth('token', {'grant_type': 'password'}),
          headers: _headers,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(timeout);
    return _session = _parse(resp);
  }

  void restore(SupabaseSession session) => _session = session;

  Future<String?> accessToken() async {
    final current = _session;
    if (current == null) return null;
    if (current.isExpiring) {
      final refreshed = await _refresh(current.refreshToken);
      return refreshed.accessToken;
    }
    return current.accessToken;
  }

  Future<SupabaseSession> _refresh(String refreshToken) async {
    final resp = await _client
        .post(
          _auth('token', {'grant_type': 'refresh_token'}),
          headers: _headers,
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(timeout);
    return _session = _parse(resp);
  }

  SupabaseSession _parse(http.Response resp) {
    if (resp.statusCode >= 300) {
      throw domain.SyncException('auth failed (${resp.statusCode})');
    }
    final j = jsonDecode(resp.body) as Map<String, dynamic>;
    final user = j['user'] as Map<String, dynamic>;
    final session = SupabaseSession(
      accessToken: j['access_token'] as String,
      refreshToken: j['refresh_token'] as String,
      userId: user['id'] as String,
      expiresAt: DateTime.now().add(
        Duration(seconds: (j['expires_in'] as num).toInt()),
      ),
    );
    onSession?.call(session);
    return session;
  }
}
