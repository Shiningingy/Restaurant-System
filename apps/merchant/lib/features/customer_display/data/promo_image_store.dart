import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Owns the app-local cache of promo photos shown on the customer display.
///
/// Files are **content-addressed**: each is stored as `<sha256><ext>`. That
/// makes imports idempotent (the same photo dedupes to one file) and lets cloud
/// promo-sync name the matching Storage object the same way, so any device can
/// tell whether it already has a photo by hash alone (see [domain.PromoManifest]).
/// The display reads these files by path — both windows are the same OS user on
/// the same machine.
class PromoImageStore {
  static const _folder = 'promo_images';

  /// Override for tests; defaults to the app documents directory.
  final Directory? _baseOverride;

  PromoImageStore({Directory? baseDir}) : _baseOverride = baseDir;

  Future<Directory> _dir() async {
    final base = _baseOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [sourcePath] into the cache under its content hash and returns the
  /// stored absolute path. Re-importing identical bytes returns the existing
  /// file (no duplicate).
  Future<String> import(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final ref = domain.PromoImageRef(
      sha: sha256.convert(bytes).toString(),
      ext: p.extension(sourcePath).toLowerCase(),
    );
    return _write(ref, bytes);
  }

  /// Writes downloaded [bytes] for [ref] into the cache and returns the path.
  /// Used by promo-sync when pulling a photo this device doesn't have yet.
  Future<String> writeRef(domain.PromoImageRef ref, List<int> bytes) =>
      _write(ref, bytes);

  Future<String> _write(domain.PromoImageRef ref, List<int> bytes) async {
    final dir = await _dir();
    final dest = p.join(dir.path, ref.fileName);
    final file = File(dest);
    if (!await file.exists()) await file.writeAsBytes(bytes);
    return dest;
  }

  /// The cache path for [ref] (whether or not it exists yet).
  Future<String> pathFor(domain.PromoImageRef ref) async =>
      p.join((await _dir()).path, ref.fileName);

  /// The set of content hashes currently cached on this device.
  Future<Set<String>> cachedShas() async {
    final dir = await _dir();
    if (!await dir.exists()) return {};
    return {
      for (final f in dir.listSync().whereType<File>())
        p.basenameWithoutExtension(f.path),
    };
  }

  /// The bytes of a stored promo file (for upload on publish).
  Future<List<int>> bytesOf(String path) => File(path).readAsBytes();

  /// Parses a cached file path back into its [domain.PromoImageRef] (the file
  /// name is `<sha><ext>`), or null if the name isn't content-addressed.
  domain.PromoImageRef? refOf(String path) {
    final sha = p.basenameWithoutExtension(path);
    final ext = p.extension(path).toLowerCase();
    if (sha.isEmpty || ext.isEmpty) return null;
    return domain.PromoImageRef(sha: sha, ext: ext);
  }

  Future<void> delete(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
