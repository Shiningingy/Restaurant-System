#include "ocr_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <memory>
#include <string>
#include <vector>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Globalization.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Streams.h>

using namespace winrt;
using namespace winrt::Windows::Globalization;
using namespace winrt::Windows::Graphics::Imaging;
using namespace winrt::Windows::Media::Ocr;
using namespace winrt::Windows::Storage;
using namespace winrt::Windows::Storage::Streams;

namespace {

// Keeps the channel alive for the lifetime of the process.
std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_channel;

// Picks an OCR engine for the first supported language in `prefs`, falling back
// to the user-profile languages. Returns nullptr if none is available.
OcrEngine CreateEngine(const std::vector<std::string>& prefs) {
  for (const auto& code : prefs) {
    Language lang{winrt::to_hstring(code)};
    if (OcrEngine::IsLanguageSupported(lang)) {
      OcrEngine engine = OcrEngine::TryCreateFromLanguage(lang);
      if (engine) return engine;
    }
  }
  return OcrEngine::TryCreateFromUserProfileLanguages();
}

void HandleRecognize(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // --- parse arguments ---
  std::string path;
  std::vector<std::string> languages;
  if (auto it = args.find(flutter::EncodableValue("path")); it != args.end()) {
    path = std::get<std::string>(it->second);
  }
  if (auto it = args.find(flutter::EncodableValue("languages"));
      it != args.end()) {
    for (const auto& v : std::get<flutter::EncodableList>(it->second)) {
      languages.push_back(std::get<std::string>(v));
    }
  }
  if (path.empty()) {
    result->Error("bad_args", "Missing image path.");
    return;
  }

  try {
    OcrEngine engine = CreateEngine(languages);
    if (!engine) {
      result->Error("no_language",
                    "No OCR language pack is installed. Add Chinese or English "
                    "in Windows Settings.");
      return;
    }

    StorageFile file =
        StorageFile::GetFileFromPathAsync(winrt::to_hstring(path)).get();
    IRandomAccessStream stream = file.OpenAsync(FileAccessMode::Read).get();
    BitmapDecoder decoder = BitmapDecoder::CreateAsync(stream).get();

    const uint32_t pixelW = decoder.PixelWidth();
    const uint32_t pixelH = decoder.PixelHeight();
    const uint32_t maxDim = OcrEngine::MaxImageDimension();

    // Windows.Media.Ocr rejects images above MaxImageDimension; downscale and
    // map the resulting boxes back to original pixel space.
    double scale = 1.0;
    SoftwareBitmap bitmap{nullptr};
    if (pixelW > maxDim || pixelH > maxDim) {
      scale = static_cast<double>(maxDim) / std::max(pixelW, pixelH);
      BitmapTransform transform;
      transform.ScaledWidth(static_cast<uint32_t>(pixelW * scale));
      transform.ScaledHeight(static_cast<uint32_t>(pixelH * scale));
      bitmap =
          decoder
              .GetSoftwareBitmapAsync(
                  BitmapPixelFormat::Bgra8, BitmapAlphaMode::Premultiplied,
                  transform, ExifOrientationMode::IgnoreExifOrientation,
                  ColorManagementMode::DoNotColorManage)
              .get();
    } else {
      bitmap = decoder.GetSoftwareBitmapAsync().get();
    }

    OcrResult ocr = engine.RecognizeAsync(bitmap).get();

    flutter::EncodableList tokens;
    const double inv = 1.0 / scale;
    for (const auto& line : ocr.Lines()) {
      for (const auto& word : line.Words()) {
        auto rect = word.BoundingRect();
        flutter::EncodableMap token{
            {flutter::EncodableValue("text"),
             flutter::EncodableValue(winrt::to_string(word.Text()))},
            {flutter::EncodableValue("left"),
             flutter::EncodableValue(rect.X * inv)},
            {flutter::EncodableValue("top"),
             flutter::EncodableValue(rect.Y * inv)},
            {flutter::EncodableValue("width"),
             flutter::EncodableValue(rect.Width * inv)},
            {flutter::EncodableValue("height"),
             flutter::EncodableValue(rect.Height * inv)},
        };
        tokens.push_back(flutter::EncodableValue(std::move(token)));
      }
    }

    flutter::EncodableMap out{
        {flutter::EncodableValue("imageWidth"),
         flutter::EncodableValue(static_cast<double>(pixelW))},
        {flutter::EncodableValue("imageHeight"),
         flutter::EncodableValue(static_cast<double>(pixelH))},
        {flutter::EncodableValue("tokens"),
         flutter::EncodableValue(std::move(tokens))},
    };
    result->Success(flutter::EncodableValue(std::move(out)));
  } catch (const winrt::hresult_error& e) {
    result->Error("ocr_error", winrt::to_string(e.message()));
  }
}

}  // namespace

void RegisterOcrChannel(flutter::FlutterEngine* engine) {
  g_channel = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "menu_capture/windows_ocr",
      &flutter::StandardMethodCodec::GetInstance());

  g_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "recognize") {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (!args) {
            result->Error("bad_args", "Expected a map.");
            return;
          }
          HandleRecognize(*args, std::move(result));
        } else {
          result->NotImplemented();
        }
      });
}
