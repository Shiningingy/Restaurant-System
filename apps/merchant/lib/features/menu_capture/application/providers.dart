import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/capture_template_store.dart';
import '../data/windows_text_recognizer.dart';
import '../domain/capture_template.dart';
import '../domain/text_recognizer.dart';
import 'capture_engine.dart';

final captureEngineProvider = Provider<CaptureEngine>(
  (ref) => const CaptureEngine(),
);

/// The platform OCR engine. Windows desktop uses Windows.Media.Ocr today; the
/// ML Kit mobile engine is a follow-up. Overridden with a fake in tests.
final textRecognizerProvider = Provider<TextRecognizer>((ref) {
  if (Platform.isWindows) return WindowsTextRecognizer();
  throw UnsupportedError(
    'On-device OCR is currently wired for Windows only; the mobile (ML Kit) '
    'engine is a follow-up.',
  );
});

final captureTemplateStoreProvider = Provider<CaptureTemplateStore>(
  (ref) => CaptureTemplateStore(ref.watch(sharedPreferencesProvider)),
);

/// The merchant's saved capture templates.
class CaptureTemplatesNotifier extends Notifier<List<CaptureTemplate>> {
  @override
  List<CaptureTemplate> build() =>
      ref.watch(captureTemplateStoreProvider).list();

  Future<void> save(CaptureTemplate template) async {
    state = await ref.read(captureTemplateStoreProvider).save(template);
  }

  Future<void> delete(String id) async {
    state = await ref.read(captureTemplateStoreProvider).delete(id);
  }
}

final captureTemplatesProvider =
    NotifierProvider<CaptureTemplatesNotifier, List<CaptureTemplate>>(
      CaptureTemplatesNotifier.new,
    );
