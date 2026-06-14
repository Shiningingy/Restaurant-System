import 'geometry.dart';

/// One recognized piece of text (an OCR element/word) with its position in the
/// source photo.
class TextToken {
  final String text;
  final PixelBox box;

  const TextToken(this.text, this.box);
}

/// The full OCR result for one photo: a flat list of positioned tokens plus the
/// source image size (so callers can reason in the same pixel space).
class RecognizedText {
  final List<TextToken> tokens;
  final double imageWidth;
  final double imageHeight;

  const RecognizedText({
    required this.tokens,
    required this.imageWidth,
    required this.imageHeight,
  });
}

/// Thrown by a platform engine when it cannot find a usable OCR language (e.g.
/// the Chinese OCR language pack is not installed on Windows). The UI shows a
/// recovery message instead of silently producing English-only results.
class OcrLanguageUnavailable implements Exception {
  final String message;
  const OcrLanguageUnavailable(this.message);
  @override
  String toString() => 'OcrLanguageUnavailable: $message';
}

/// Port over the platform OCR engine. The capture flow depends only on this;
/// real implementations (Windows.Media.Ocr, ML Kit) live in `data/` and are the
/// only files that import a native plugin. Swappable for a fake in tests.
abstract class TextRecognizer {
  Future<RecognizedText> recognize(String imagePath);
}
