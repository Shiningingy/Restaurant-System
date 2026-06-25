import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/db_backup.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// The local backup ring: consistent snapshots, a 3-deep ring, and a
/// launch-time restore swap. Uses real on-disk sqlite files (encrypted when the
/// SQLite3MultipleCiphers build is present; plaintext otherwise — the mechanics
/// are the same either way).
void main() {
  late Directory tmp;
  const key = 'test-key-123';
  late String livePath;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('dbbackup');
    livePath = p.join(tmp.path, 'restaurant_pos.sqlite');
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  // Writes a one-row "marker" table to an encrypted db at [path].
  void writeDb(String path, String label) {
    final db = sqlite.sqlite3.open(path);
    db.execute("PRAGMA key = '$key';");
    db.execute('CREATE TABLE IF NOT EXISTS marker(label TEXT);');
    db.execute('DELETE FROM marker;');
    db.execute("INSERT INTO marker(label) VALUES('$label');");
    db.close();
  }

  String readLabel(String path) {
    final db = sqlite.sqlite3.open(path);
    db.execute("PRAGMA key = '$key';");
    final rows = db.select('SELECT label FROM marker;');
    final v = rows.first['label'] as String;
    db.close();
    return v;
  }

  DbBackupService service({DateTime Function()? clock}) =>
      DbBackupService(dbKey: key, docsDir: () async => tmp, clock: clock);

  test('snapshot writes a readable, content-matching copy', () async {
    writeDb(livePath, 'truth');
    final svc = service();
    final snap = await svc.snapshot(reason: 'manual');
    expect(snap, isNotNull);
    expect(snap!.existsSync(), isTrue);
    expect(readLabel(snap.path), 'truth');
    final list = await svc.list();
    expect(list, hasLength(1));
    expect(list.single.reason, 'manual');
  });

  test('snapshot is null on a fresh install (no database yet)', () async {
    expect(await service().snapshot(reason: 'manual'), isNull);
  });

  test('the ring keeps only the newest 3', () async {
    writeDb(livePath, 'truth');
    var t = DateTime.utc(2026, 6, 25, 10);
    final svc = service(
      clock: () {
        t = t.add(const Duration(seconds: 1));
        return t;
      },
    );
    for (var i = 0; i < 5; i++) {
      await svc.snapshot(reason: 'sync');
    }
    expect(await svc.list(), hasLength(3));
  });

  test('restore stages the backup; applyPendingRestore swaps it in, keeps a '
      'safety copy and clears stale WAL', () async {
    writeDb(livePath, 'current');
    // A stale WAL sidecar that must be removed when the file is swapped.
    File('$livePath-wal').writeAsBytesSync(const [1, 2, 3]);

    final svc = service();
    final older = File(p.join(tmp.path, 'older.sqlite'));
    writeDb(older.path, 'older');
    await svc.restore(older);

    final pending = File('$livePath${DbBackupService.restorePendingSuffix}');
    expect(pending.existsSync(), isTrue, reason: 'restore only stages');
    expect(
      readLabel(livePath),
      'current',
      reason: 'live untouched until launch',
    );

    // Simulate the next launch.
    DbBackupService.applyPendingRestore(File(livePath));
    expect(pending.existsSync(), isFalse);
    expect(File('$livePath.prerestore.bak').existsSync(), isTrue);
    expect(File('$livePath-wal').existsSync(), isFalse);
    expect(readLabel(livePath), 'older');
  });

  test('restore rejects a file that does not open as a database', () async {
    final bogus = File(p.join(tmp.path, 'bogus.sqlite'));
    bogus.writeAsBytesSync(List.filled(128, 7));
    await expectLater(service().restore(bogus), throwsA(anything));
  });

  test('applyPendingRestore is a no-op when nothing is staged', () {
    writeDb(livePath, 'current');
    DbBackupService.applyPendingRestore(File(livePath));
    expect(readLabel(livePath), 'current');
    expect(File('$livePath.prerestore.bak').existsSync(), isFalse);
  });
}
