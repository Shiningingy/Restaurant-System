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
    MenuItemAttributes,
    MenuItemImages,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Tests pass `NativeDatabase.memory()`; production uses [AppDatabase.open].
  AppDatabase(super.e);

  AppDatabase.open() : super(driftDatabase(name: 'restaurant_pos'));

  @override
  int get schemaVersion => 7;

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
    },
  );
}
