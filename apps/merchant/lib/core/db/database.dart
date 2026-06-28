import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'db_backup.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    MenuItems,
    ModifierGroups,
    Modifiers,
    MenuItemModifierGroups,
    DiningTables,
    Orders,
    OrderLines,
    OrderLineModifiers,
    Payments,
    PrintJobs,
    SyncLog,
    Staff,
    MenuItemAttributes,
    MenuItemImages,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Tests pass `NativeDatabase.memory()`; production uses [AppDatabase.open].
  AppDatabase(super.e);

  /// Opens the on-disk database encrypted at rest with [dbKey] (SQLCipher via
  /// the SQLite3MultipleCiphers build — see the `sqlite3mc` hook in the root
  /// pubspec). [dbKey] comes from OS-encrypted secure storage and never leaves
  /// the device, so the file is unreadable if copied to another machine/user.
  AppDatabase.open(String dbKey) : super(_connect(dbKey));

  /// The on-disk database filename, in the app documents directory. Shared with
  /// [DbBackupService] so the backup ring backs up the right file.
  static const dbFileName = 'restaurant_pos.sqlite';

  static LazyDatabase _connect(String dbKey) => LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, dbFileName));
    // Before opening, swap in a backup the user staged for restore (it can't
    // overwrite the live file while we hold it open — so it waits for launch).
    DbBackupService.applyPendingRestore(file);
    await _migratePlaintextIfNeeded(file, dbKey);
    return NativeDatabase.createInBackground(
      file,
      setup: (raw) {
        assert(
          _hasCipher(raw),
          'SQLite was built without encryption — check the sqlite3mc hook.',
        );
        raw.execute("PRAGMA key = '${_escapeKey(dbKey)}';");
      },
    );
  });

  static String _escapeKey(String key) => key.replaceAll("'", "''");

  static bool _hasCipher(sqlite.Database db) =>
      db.select('PRAGMA cipher_version;').isNotEmpty;

  /// One-time upgrade path: if an older **unencrypted** database file is found,
  /// encrypt it in place via `PRAGMA rekey`. A backup is kept until the rekey
  /// succeeds so a crash mid-migration can never lose data. A fresh install has
  /// no file and skips straight to creating an encrypted one.
  static Future<void> _migratePlaintextIfNeeded(File file, String dbKey) async {
    if (!file.existsSync()) return;

    // A plaintext DB reads its header with no key; an already-encrypted one
    // throws until `PRAGMA key` is set — that's how we tell them apart.
    final probe = sqlite.sqlite3.open(file.path);
    bool plaintext;
    try {
      probe.select('PRAGMA schema_version;');
      plaintext = true;
    } catch (_) {
      plaintext = false;
    } finally {
      probe.close();
    }
    if (!plaintext) return;

    final backup = File('${file.path}.premigration.bak');
    file.copySync(backup.path);
    try {
      final db = sqlite.sqlite3.open(file.path);
      try {
        db.execute("PRAGMA rekey = '${_escapeKey(dbKey)}';");
      } finally {
        db.close();
      }
      backup.deleteSync(); // success — drop the plaintext copy
    } catch (_) {
      // Restore the original and surface the error; never leave data behind.
      backup.copySync(file.path);
      backup.deleteSync();
      rethrow;
    }
  }

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(printJobs); // v2: print queue
      if (from < 3) await m.createTable(syncLog); // v3: cloud-sync journal
      if (from < 4) await m.createTable(staff); // v4: staff roster / roles
      if (from < 5) {
        // v5: extensible menu items — custom fields, images, code + 2nd name.
        await m.createTable(menuItemAttributes);
        await m.createTable(menuItemImages);
        await m.addColumn(menuItems, menuItems.code);
        await m.addColumn(menuItems, menuItems.nameSecondary);
        await m.addColumn(orderLines, orderLines.codeSnapshot);
        await m.addColumn(orderLines, orderLines.nameSecondarySnapshot);
      }
      if (from < 6) {
        // v6: optional menu-item description.
        await m.addColumn(menuItems, menuItems.description);
      }
      if (from < 7) {
        // v7: order-level discount + service fee.
        await m.addColumn(orders, orders.serviceFeeBp);
        await m.addColumn(orders, orders.discount);
        await m.addColumn(orders, orders.serviceFee);
      }
      if (from < 8) {
        // v8: per-line settlement marker for split-by-item bills.
        await m.addColumn(orderLines, orderLines.settledByPaymentId);
      }
      if (from < 9) {
        // v9: paid orders stay on the board until "finished". Add paidAt (the
        // financial timestamp) and migrate already-closed `paid` orders to the
        // new `done` state — so existing history stays in history and old
        // orders don't resurface on the board.
        await m.addColumn(orders, orders.paidAt);
        await m.database.customStatement(
          "UPDATE orders SET status = 'done', paid_at = closed_at "
          "WHERE status = 'paid'",
        );
      }
      if (from < 10) {
        // v10: cross-device item-photo sync. The content hash + extension let
        // the bytes travel through the `menu-photos` bucket while the row rides
        // the normal feed; legacy rows backfill their sha from the local file.
        await m.addColumn(menuItemImages, menuItemImages.sha);
        await m.addColumn(menuItemImages, menuItemImages.ext);
      }
      if (from < 11) {
        // v11: comped (on-the-house) order lines. Defaults false on every
        // existing line — nothing is retroactively comped.
        await m.addColumn(orderLines, orderLines.comped);
      }
    },
  );
}
