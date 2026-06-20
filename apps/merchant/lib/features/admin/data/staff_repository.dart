import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../domain/staff.dart';

/// Local staff roster. PINs are stored as `sha256("$id:$pin")` (per-id salt so
/// identical PINs hash differently). Not part of the cloud-sync journal.
class StaffRepository {
  final AppDatabase db;

  StaffRepository(this.db);

  /// Hash a PIN for a given staff id. Public so the staff editor can build a
  /// row, and so tests can assert against it.
  static String hashPin(String id, String pin) =>
      sha256.convert(utf8.encode('$id:$pin')).toString();

  Staff _fromRow(StaffRow r) => Staff(
    id: r.id,
    name: r.name,
    role: StaffRole.values.byName(r.role),
    pinHash: r.pinHash,
  );

  Stream<List<Staff>> watchStaff() {
    final q = db.select(db.staff)..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<List<Staff>> all() async {
    final rows = await db.select(db.staff).get();
    return rows.map(_fromRow).toList();
  }

  Future<int> staffCount() async {
    final rows = await db.select(db.staff).get();
    return rows.length;
  }

  Future<int> ownerCount() async {
    final rows = await (db.select(
      db.staff,
    )..where((t) => t.role.equals(StaffRole.owner.name))).get();
    return rows.length;
  }

  Future<void> upsert(Staff staff) => db
      .into(db.staff)
      .insertOnConflictUpdate(
        StaffCompanion.insert(
          id: staff.id,
          name: staff.name,
          role: staff.role.name,
          pinHash: staff.pinHash,
        ),
      );

  Future<void> delete(String id) =>
      (db.delete(db.staff)..where((t) => t.id.equals(id))).go();

  /// The staff member whose PIN matches, or null. Iterates the roster because
  /// the hash is salted per-id; the roster is tiny so this is cheap.
  Future<Staff?> findByPin(String pin) async {
    for (final s in await all()) {
      if (s.pinHash == hashPin(s.id, pin)) return s;
    }
    return null;
  }

  /// The staff member whose **name and** PIN both match, or null. Requiring the
  /// name disambiguates two people who happen to share a PIN. Name match is
  /// case-insensitive and trims surrounding spaces.
  Future<Staff?> findByNameAndPin(String name, String pin) async {
    final target = name.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final s in await all()) {
      if (s.name.trim().toLowerCase() == target &&
          s.pinHash == hashPin(s.id, pin)) {
        return s;
      }
    }
    return null;
  }
}
