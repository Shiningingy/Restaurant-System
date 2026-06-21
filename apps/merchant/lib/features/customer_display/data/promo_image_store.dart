import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Copies picked promo photos into a stable app-owned folder (so the paths
/// stay valid after the source files move) and cleans them up on removal.
/// Mirrors the menu image store; the display reads these files by path — both
/// windows are the same OS user on the same machine.
class PromoImageStore {
  static const _folder = 'promo_images';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [sourcePath] into the app folder under a fresh name and returns the
  /// stored absolute path.
  Future<String> import(String sourcePath) async {
    final dir = await _dir();
    final ext = p.extension(sourcePath);
    final dest = p.join(dir.path, '${domain.newId()}$ext');
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<void> delete(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
