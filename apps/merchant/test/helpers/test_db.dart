import 'package:drift/native.dart';
import 'package:merchant/core/db/database.dart';

/// In-memory database for tests. sqlite3 ships as a Dart native asset, so
/// this works in `flutter test` on every desktop platform with no setup.
AppDatabase createTestDb() => AppDatabase(NativeDatabase.memory());
