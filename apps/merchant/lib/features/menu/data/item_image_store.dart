import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A content-addressed item photo: its bytes hash to [sha] and it was stored
/// with extension [ext] (incl. the dot). The bucket object + the cache file are
/// both named `<sha><ext>`, so any device can tell from the hash alone whether
/// it already has the bytes — which is what makes cross-device sync work.
class StoredImage {
  final String sha;
  final String ext;
  final String path;

  const StoredImage({required this.sha, required this.ext, required this.path});

  String get fileName => '$sha$ext';
}

/// Copies item images into an app-owned folder, **content-addressed** by SHA-256
/// (like the promo cache). The DB row keeps the resulting path + the (sha, ext)
/// so the bytes can travel through the `menu-photos` bucket and be recreated on
/// another device.
class ItemImageStore {
  static const _folder = 'menu_images';

  /// Override for tests; defaults to the app documents directory.
  final Directory? _baseOverride;

  ItemImageStore({Directory? baseDir}) : _baseOverride = baseDir;

  Future<Directory> _dir() async {
    final base = _baseOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [sourcePath] into the cache under its content hash and returns the
  /// stored ref. Re-importing identical bytes reuses the existing file.
  Future<StoredImage> import(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final sha = sha256.convert(bytes).toString();
    final ext = p.extension(sourcePath).toLowerCase();
    final path = await _write(sha, ext, bytes);
    return StoredImage(sha: sha, ext: ext, path: path);
  }

  /// Writes downloaded [bytes] for `(sha, ext)` into the cache and returns the
  /// path — used when pulling a photo this device synced but doesn't have yet.
  Future<String> writeBytes(String sha, String ext, List<int> bytes) =>
      _write(sha, ext, bytes);

  Future<String> _write(String sha, String ext, List<int> bytes) async {
    final dir = await _dir();
    final dest = p.join(dir.path, '$sha$ext');
    final file = File(dest);
    if (!await file.exists()) await file.writeAsBytes(bytes);
    return dest;
  }

  /// The cache path for `(sha, ext)` whether or not the file exists yet.
  Future<String> pathFor(String sha, String ext) async =>
      p.join((await _dir()).path, '$sha$ext');

  /// True when this device already has the bytes for [sha] cached.
  Future<bool> hasSha(String sha) async {
    final dir = await _dir();
    if (!await dir.exists()) return false;
    return dir.listSync().whereType<File>().any(
      (f) => p.basenameWithoutExtension(f.path) == sha,
    );
  }

  /// The bytes of a stored file (for upload), or null if it's gone.
  Future<List<int>?> bytesOf(String path) async {
    final f = File(path);
    return await f.exists() ? f.readAsBytes() : null;
  }

  /// Deletes a cache file — only call when no row still references its hash.
  Future<void> delete(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
