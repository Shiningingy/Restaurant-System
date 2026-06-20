import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

/// Cleans a pasted Supabase URL: trims it and prepends `https://` when no
/// scheme is given (otherwise `Uri.parse` yields no host and every request
/// throws "No host specified in URI"). Shared by merchant + customer entry.
String normalizeSupabaseUrl(String url) {
  final u = url.trim();
  if (u.isEmpty) return u;
  final lower = u.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return u;
  return 'https://$u';
}

/// The restaurant's own Supabase project — URL + anon (public) key.
/// Empty [url] means cloud sync is off; the POS is fully functional that
/// way forever (docs/PRINCIPLES.md — no required subscription).
class SupabaseConfig {
  final String? url;
  final String? anonKey;

  const SupabaseConfig({this.url, this.anonKey});

  bool get isConfigured =>
      url != null && url!.isNotEmpty && anonKey != null && anonKey!.isNotEmpty;
}

/// Cloud-sync configuration and bookkeeping, in shared_preferences.
class SyncSettings {
  static const _urlKey = 'syncSupabaseUrl';
  static const _anonKeyKey = 'syncSupabaseAnonKey';
  static const _deviceIdKey = 'syncDeviceId';
  static const _cursorKey = 'syncCursorIso';
  static const _lastAtKey = 'syncLastAtIso';
  static const _restaurantEmailKey = 'syncRestaurantEmail';
  static const _restaurantRefreshKey = 'syncRestaurantRefreshToken';

  /// The pull cursor's floor when nothing has synced yet — replays the
  /// whole remote feed (used by restore).
  static final epoch = DateTime.utc(1970);

  final SharedPreferences? _prefs;
  final Map<String, String> _mem;

  SyncSettings(SharedPreferences prefs) : _prefs = prefs, _mem = {};

  /// In-memory backing — for tests that need several independent devices
  /// (the global shared_preferences mock is a single shared store).
  SyncSettings.inMemory() : _prefs = null, _mem = {};

  String? _get(String key) => _prefs?.getString(key) ?? _mem[key];

  Future<void> _set(String key, String value) async {
    if (_prefs != null) {
      await _prefs.setString(key, value);
    } else {
      _mem[key] = value;
    }
  }

  Future<void> _remove(String key) async {
    if (_prefs != null) {
      await _prefs.remove(key);
    } else {
      _mem.remove(key);
    }
  }

  SupabaseConfig get config =>
      SupabaseConfig(url: _get(_urlKey), anonKey: _get(_anonKeyKey));

  Future<void> setConfig(SupabaseConfig config) async {
    final url = config.url;
    final key = config.anonKey;
    if (url == null || url.isEmpty) {
      await _remove(_urlKey);
    } else {
      await _set(_urlKey, normalizeSupabaseUrl(url));
    }
    if (key == null || key.isEmpty) {
      await _remove(_anonKeyKey);
    } else {
      await _set(_anonKeyKey, key.trim());
    }
  }

  /// Stable per-install id so a device can skip its own changes on pull.
  /// Generated and persisted on first read.
  String get deviceId {
    final existing = _get(_deviceIdKey);
    if (existing != null) return existing;
    final id = domain.newId();
    _set(_deviceIdKey, id);
    return id;
  }

  DateTime get cursor {
    final iso = _get(_cursorKey);
    return iso == null ? epoch : DateTime.parse(iso);
  }

  Future<void> setCursor(DateTime value) =>
      _set(_cursorKey, value.toIso8601String());

  Future<void> resetCursor() => _remove(_cursorKey);

  DateTime? get lastSyncedAt {
    final iso = _get(_lastAtKey);
    return iso == null ? null : DateTime.parse(iso);
  }

  Future<void> setLastSyncedAt(DateTime value) =>
      _set(_lastAtKey, value.toIso8601String());

  // --- Restaurant Supabase login (cloud features require it) ---

  String? get restaurantEmail => _get(_restaurantEmailKey);
  String? get restaurantRefreshToken => _get(_restaurantRefreshKey);
  bool get isSignedIn => restaurantRefreshToken != null;

  Future<void> saveRestaurantSession({
    required String email,
    required String refreshToken,
  }) async {
    await _set(_restaurantEmailKey, email);
    await _set(_restaurantRefreshKey, refreshToken);
  }

  Future<void> clearRestaurantSession() async {
    await _remove(_restaurantEmailKey);
    await _remove(_restaurantRefreshKey);
  }
}
