import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

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
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Tests pass `NativeDatabase.memory()`; production uses [AppDatabase.open].
  AppDatabase(super.e);

  AppDatabase.open() : super(driftDatabase(name: 'restaurant_pos'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(printJobs); // v2: print queue
      if (from < 3) await m.createTable(syncLog); // v3: cloud-sync journal
      if (from < 4) await m.createTable(staff); // v4: staff roster / roles
    },
  );
}
