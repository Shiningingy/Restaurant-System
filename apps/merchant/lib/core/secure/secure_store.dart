import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// OS-encrypted storage for the few secrets that must never sit on disk in the
/// clear: the database encryption key and the cloud refresh token.
///
/// Backed by [FlutterSecureStorage] — Windows DPAPI (bound to the Windows user
/// account), Android Keystore / EncryptedSharedPreferences. A copied file or a
/// second OS user cannot read these.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _dbKeyKey = 'dbEncryptionKey';
  static const _refreshKey = 'syncRestaurantRefreshToken';

  /// Returns the database encryption key, generating and persisting a fresh
  /// 256-bit random key on first run. The key never leaves secure storage, so
  /// the encrypted database is unreadable if copied to another machine/user.
  Future<String> getOrCreateDbKey() async {
    final existing = await _storage.read(key: _dbKeyKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    final key = base64Url.encode(bytes);
    await _storage.write(key: _dbKeyKey, value: key);
    return key;
  }

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  Future<void> clearRefreshToken() => _storage.delete(key: _refreshKey);
}
