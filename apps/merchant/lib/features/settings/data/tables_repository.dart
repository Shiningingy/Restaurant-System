import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';

class TablesRepository {
  final AppDatabase db;

  TablesRepository(this.db);

  Stream<List<domain.DiningTable>> watchTables() {
    final q = db.select(db.diningTables)
      ..orderBy([(t) => OrderingTerm.asc(t.label)]);
    return q.watch().map(
      (rows) => rows
          .map(
            (r) => domain.DiningTable(
              id: r.id,
              label: r.label,
              isActive: r.isActive,
            ),
          )
          .toList(),
    );
  }

  Future<void> upsertTable(domain.DiningTable table) {
    return db
        .into(db.diningTables)
        .insertOnConflictUpdate(
          DiningTablesCompanion.insert(
            id: table.id,
            label: table.label,
            isActive: Value(table.isActive),
          ),
        );
  }
}
