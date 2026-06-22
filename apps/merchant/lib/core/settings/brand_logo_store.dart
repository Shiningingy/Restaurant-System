import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores the shop's brand logo as a single app-owned file, **content-addressed**
/// (`<sha256><ext>`) so cloud sync can name the matching Storage object the same
/// way and any device can tell by hash whether it already has the logo. The shop
/// has at most one logo, so importing/downloading a new one clears the old file.
class BrandLogoStore {
  static const _folder = 'brand';

  final Directory? _baseOverride;

  BrandLogoStore({Directory? baseDir}) : _baseOverride = baseDir;

  Future<Directory> _dir() async {
    final base = _baseOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [sourcePath] in under its content hash and returns the stored path.
  Future<String> import(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    return writeBytes(
      sha256.convert(bytes).toString(),
      p.extension(sourcePath).toLowerCase(),
      bytes,
    );
  }

  /// Writes [bytes] for a known [sha]/[ext] (used by sync pull) and returns the
  /// path. Clears any previous logo first (only one is ever kept).
  Future<String> writeBytes(String sha, String ext, List<int> bytes) async {
    await clear();
    final dest = p.join((await _dir()).path, '$sha$ext');
    await File(dest).writeAsBytes(bytes);
    return dest;
  }

  Future<String> pathFor(String sha, String ext) async =>
      p.join((await _dir()).path, '$sha$ext');

  /// Whether the logo with this content hash is already cached.
  Future<bool> hasSha(String sha) async {
    final dir = await _dir();
    if (!await dir.exists()) return false;
    return dir
        .listSync()
        .whereType<File>()
        .any((f) => p.basenameWithoutExtension(f.path) == sha);
  }

  Future<List<int>> bytesOf(String path) => File(path).readAsBytes();

  /// Parses a cached logo path back into its (sha, ext), or null.
  ({String sha, String ext})? refOf(String path) {
    final sha = p.basenameWithoutExtension(path);
    final ext = p.extension(path).toLowerCase();
    if (sha.isEmpty || ext.isEmpty) return null;
    return (sha: sha, ext: ext);
  }

  /// Removes the stored logo (if any).
  Future<void> clear() async {
    final dir = await _dir();
    if (!await dir.exists()) return;
    for (final f in dir.listSync().whereType<File>()) {
      await f.delete();
    }
  }
}
