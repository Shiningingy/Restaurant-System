import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'database.dart';

/// One on-disk backup snapshot of the merchant database.
class DbBackup {
  final File file;
  final DateTime at;
  final int bytes;

  /// Why it was taken — e.g. "manual", "sync", "restore", "forcepush".
  final String reason;

  const DbBackup({
    required this.file,
    required this.at,
    required this.bytes,
    required this.reason,
  });
}

/// Local, on-device backup ring for the encrypted merchant database.
///
/// Supabase's free tier has no server-side backup, and cloud sync is
/// last-write-wins, so a misclicked "Sync now" — or the automatic sync on
/// launch, which pulls first — can overwrite good data. This keeps the newest
/// [keep] snapshots of the whole database next to it (taken before every
/// push/pull and on demand) and can roll back to any of them.
///
/// Snapshots use `VACUUM INTO`, which writes a transactionally consistent copy
/// even while Drift holds the database open, and — on the SQLite3MultipleCiphers
/// build — carries the encryption key into the copy, so a snapshot is as
/// unreadable off-device as the live file.
class DbBackupService {
  static const _prefix = 'pos-backup_';
  static const _ext = '.sqlite';
  static const _dirName = 'pos_backups';

  /// Suffix of the staged-restore file. A restore can't overwrite the live
  /// database while Drift holds it open (a Windows sharing violation), so
  /// [restore] only stages the chosen snapshot here; [applyPendingRestore]
  /// swaps it in at next launch, before the database is opened.
  static const restorePendingSuffix = '.restore-pending';

  static final _stamp = DateFormat('yyyyMMdd-HHmmss-SSS');

  final String dbKey;
  final int keep;
  final Future<Directory> Function() _docsDir;
  final DateTime Function() _clock;

  DbBackupService({
    required this.dbKey,
    this.keep = 3,
    Future<Directory> Function()? docsDir,
    DateTime Function()? clock,
  }) : _docsDir = docsDir ?? getApplicationDocumentsDirectory,
       _clock = clock ?? DateTime.now;

  Future<File> _liveFile() async =>
      File(p.join((await _docsDir()).path, AppDatabase.dbFileName));

  Future<Directory> _backupDir() async {
    final dir = Directory(p.join((await _docsDir()).path, _dirName));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Writes a consistent, encrypted snapshot of the live database, then prunes
  /// the ring to the newest [keep]. [reason] is kept in the filename. Returns
  /// the snapshot file, or null if there's nothing to back up yet (a fresh
  /// install with no database file).
  Future<File?> snapshot({required String reason}) async {
    final live = await _liveFile();
    if (!live.existsSync()) return null;
    final dir = await _backupDir();
    final safeReason = reason.replaceAll(RegExp('[^a-zA-Z0-9]'), '');
    final dest = File(
      p.join(dir.path, '$_prefix${_stamp.format(_clock())}_$safeReason$_ext'),
    );
    // VACUUM INTO refuses to overwrite; clear a same-millisecond collision.
    if (dest.existsSync()) dest.deleteSync();

    final db = sqlite.sqlite3.open(live.path);
    try {
      db.execute("PRAGMA key = '${_escape(dbKey)}';");
      db.execute("VACUUM INTO '${_escape(dest.path)}';");
    } finally {
      db.close();
    }
    await _prune();
    return dest;
  }

  /// The available snapshots, newest first.
  Future<List<DbBackup>> list() async {
    final dir = await _backupDir();
    final out = <DbBackup>[];
    for (final e in dir.listSync()) {
      if (e is! File) continue;
      final name = p.basename(e.path);
      if (!name.startsWith(_prefix) || !name.endsWith(_ext)) continue;
      final stat = e.statSync();
      out.add(
        DbBackup(
          file: e,
          at: stat.modified,
          bytes: stat.size,
          reason: _reasonOf(name),
        ),
      );
    }
    // The filename stamp is zero-padded, so lexicographic desc == newest first.
    out.sort(
      (a, b) => p.basename(b.file.path).compareTo(p.basename(a.file.path)),
    );
    return out;
  }

  /// Stages [backup] to be swapped in at next launch (see
  /// [restorePendingSuffix]). Verifies it opens with the current key first, so
  /// a corrupt or foreign file is rejected before it can replace live data.
  Future<void> restore(File backup) async {
    if (!backup.existsSync()) {
      throw StateError('Backup no longer exists: ${backup.path}');
    }
    // A valid snapshot reads its schema once the key is set.
    final probe = sqlite.sqlite3.open(backup.path);
    try {
      probe.execute("PRAGMA key = '${_escape(dbKey)}';");
      probe.select('PRAGMA schema_version;');
    } finally {
      probe.close();
    }
    final live = await _liveFile();
    backup.copySync('${live.path}$restorePendingSuffix');
  }

  /// At launch, before the database is opened: if a restore was staged, replace
  /// the live database with it (keeping a one-off `.prerestore.bak`) and clear
  /// any stale WAL sidecars so SQLite can't replay the old journal onto the new
  /// file. Safe to call unconditionally; a no-op when nothing is staged.
  static void applyPendingRestore(File liveFile) {
    final pending = File('${liveFile.path}$restorePendingSuffix');
    if (!pending.existsSync()) return;
    if (liveFile.existsSync()) {
      liveFile.copySync('${liveFile.path}.prerestore.bak');
    }
    pending.copySync(liveFile.path);
    for (final sidecar in const ['-wal', '-shm']) {
      final f = File('${liveFile.path}$sidecar');
      if (f.existsSync()) f.deleteSync();
    }
    pending.deleteSync();
  }

  Future<void> _prune() async {
    final all = await list();
    for (final b in all.skip(keep)) {
      if (b.file.existsSync()) b.file.deleteSync();
    }
  }

  String _reasonOf(String filename) {
    final core = filename.substring(
      _prefix.length,
      filename.length - _ext.length,
    );
    final us = core.lastIndexOf('_');
    return us == -1 ? '' : core.substring(us + 1);
  }

  static String _escape(String s) => s.replaceAll("'", "''");
}
