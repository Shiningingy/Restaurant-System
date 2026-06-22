import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores the shop's brand logo as a single app-owned file (so its path stays
/// valid after the source moves). Picking a new logo replaces the old one.
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

  /// Copies [sourcePath] into the app folder as the single logo and returns the
  /// stored absolute path. Clears any previous logo first.
  Future<String> import(String sourcePath) async {
    await clear();
    final dir = await _dir();
    final dest = p.join(dir.path, 'logo${p.extension(sourcePath).toLowerCase()}');
    await File(sourcePath).copy(dest);
    return dest;
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
