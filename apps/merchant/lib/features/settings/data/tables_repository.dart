import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import '../../sync/data/sync_codec.dart';
import '../../sync/data/sync_journal.dart';

class TablesRepository {
  final AppDatabase db;
  final SyncJournal journal;

  TablesRepository(this.db, {SyncJournal? journal})
    : journal = journal ?? SyncJournal(db);

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

  Future<String?> labelFor(String tableId) async {
    final row = await (db.select(
      db.diningTables,
    )..where((t) => t.id.equals(tableId))).getSingleOrNull();
    return row?.label;
  }

  Future<void> upsertTable(domain.DiningTable table) {
    return db.transaction(() async {
      await db
          .into(db.diningTables)
          .insertOnConflictUpdate(
            DiningTablesCompanion.insert(
              id: table.id,
              label: table.label,
              isActive: Value(table.isActive),
            ),
          );
      await journal.recordUpsert(SyncEntities.diningTable, table.id);
    });
  }
}
