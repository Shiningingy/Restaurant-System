import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;

import '../domain/geometry.dart';
import '../domain/text_recognizer.dart';

/// OCR on Android/iOS via Google ML Kit. Uses the **Chinese** recognizer, which
/// also reads Latin text, so a bilingual menu line (牛肉面 / Beef Noodle) is
/// captured in one pass. The only file that imports the ML Kit plugin.
class MlkitTextRecognizer implements TextRecognizer {
  @override
  Future<RecognizedText> recognize(String imagePath) async {
    final recognizer = mlkit.TextRecognizer(
      script: mlkit.TextRecognitionScript.chinese,
    );
    try {
      final result = await recognizer.processImage(
        mlkit.InputImage.fromFilePath(imagePath),
      );
      final tokens = <TextToken>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            final text = element.text.trim();
            if (text.isEmpty) continue;
            final r = element.boundingBox;
            tokens.add(
              TextToken(text, PixelBox.ltwh(r.left, r.top, r.width, r.height)),
            );
          }
        }
      }
      // imageWidth/height are informational here — the capture engine works in
      // the photo's own pixel space (same as these boxes), seeded from the
      // file's decoded size on the capture screen.
      return RecognizedText(tokens: tokens, imageWidth: 0, imageHeight: 0);
    } finally {
      await recognizer.close();
    }
  }
}
