import 'package:flutter/services.dart';

import '../domain/geometry.dart';
import '../domain/text_recognizer.dart';

/// OCR on Windows desktop via the built-in (free, offline) `Windows.Media.Ocr`
/// engine, reached through a custom C++/WinRT method channel implemented in the
/// Windows runner (`windows/runner/ocr_channel.cpp`).
///
/// The native side picks the first installed recognizer language matching our
/// preference list — Chinese first (it also reads Latin, so bilingual menus need
/// one pass), English as a fallback — and returns word-level boxes. If no usable
/// OCR language pack is installed it reports `no_language`, surfaced here as
/// [OcrLanguageUnavailable] so the UI can tell the merchant how to fix it.
class WindowsTextRecognizer implements TextRecognizer {
  WindowsTextRecognizer({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('menu_capture/windows_ocr');

  /// Preferred OCR languages, best first (BCP-47). Chinese models also read
  /// Latin script, so they handle bilingual menus in a single pass.
  static const _languagePreference = ['zh-Hans', 'zh-Hant', 'zh', 'en'];

  final MethodChannel _channel;

  @override
  Future<RecognizedText> recognize(String imagePath) async {
    final Map<Object?, Object?> result;
    try {
      result =
          await _channel.invokeMethod<Map<Object?, Object?>>('recognize', {
            'path': imagePath,
            'languages': _languagePreference,
          }) ??
          const {};
    } on PlatformException catch (e) {
      if (e.code == 'no_language') {
        throw OcrLanguageUnavailable(
          e.message ??
              'No OCR language pack is installed. Add Chinese or English under '
                  'Windows Settings → Time & language → Language.',
        );
      }
      rethrow;
    }

    final rawTokens = (result['tokens'] as List<Object?>? ?? const []);
    final tokens = <TextToken>[];
    for (final raw in rawTokens) {
      final t = (raw as Map<Object?, Object?>);
      final text = (t['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) continue;
      tokens.add(
        TextToken(
          text,
          PixelBox.ltwh(
            _d(t['left']),
            _d(t['top']),
            _d(t['width']),
            _d(t['height']),
          ),
        ),
      );
    }

    return RecognizedText(
      tokens: tokens,
      imageWidth: _d(result['imageWidth']),
      imageHeight: _d(result['imageHeight']),
    );
  }

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
}
