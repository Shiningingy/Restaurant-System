import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../domain/geometry.dart';

/// Crops a region of a source photo into a standalone PNG in the temp dir,
/// returning its path. The caller then hands that path to `ItemImageRepository`
/// (which copies it into permanent app storage like any picked image), so this
/// stays a thin, swappable step. Decoding the whole photo is fine for a rare
/// setup-time action.
class ImageRegionCropper {
  const ImageRegionCropper();

  Future<String> cropToTempFile(String sourcePath, PixelBox box) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Could not decode the source image.');
    }

    // Clamp the region to the image bounds (the big block may overhang edges).
    final left = box.left.round().clamp(0, decoded.width - 1);
    final top = box.top.round().clamp(0, decoded.height - 1);
    final width = box.width.round().clamp(1, decoded.width - left);
    final height = box.height.round().clamp(1, decoded.height - top);

    final cropped = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: width,
      height: height,
    );

    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'crop_${domain.newId()}.png');
    await File(path).writeAsBytes(img.encodePng(cropped));
    return path;
  }
}
