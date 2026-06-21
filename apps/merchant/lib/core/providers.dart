import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/database.dart';

/// The database encryption key, overridden in main() after it is read from
/// (or created in) OS-encrypted secure storage. Never overridden in tests —
/// they override [databaseProvider] with an in-memory db instead.
final dbKeyProvider = Provider<String>((ref) {
  throw UnimplementedError('dbKeyProvider must be overridden in main()');
});

/// Overridden with an in-memory database in tests.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open(ref.watch(dbKeyProvider));
  ref.onDispose(db.close);
  return db;
});

/// Overridden in main() after SharedPreferences.getInstance() resolves,
/// and with a mock in tests.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});
