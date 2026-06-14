#ifndef RUNNER_OCR_CHANNEL_H_
#define RUNNER_OCR_CHANNEL_H_

#include <flutter/flutter_engine.h>

// Registers the "menu_capture/windows_ocr" method channel, backed by the
// built-in Windows.Media.Ocr engine. Call once after RegisterPlugins.
void RegisterOcrChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_OCR_CHANNEL_H_
