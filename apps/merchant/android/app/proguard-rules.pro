# google_mlkit_text_recognition bundles a single script model (Chinese, which
# also reads Latin). The plugin's initialize() statically references the option
# classes for the other scripts (Devanagari/Japanese/Korean) we don't ship, so
# R8 aborts the release build on the missing classes. We never call those code
# paths — suppress the warnings rather than pulling in unused language models.
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
