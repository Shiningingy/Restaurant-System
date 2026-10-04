/// The extensions installed in this build: none.
///
/// To install extensions, point the `restaurant_extensions` package at another
/// implementation from a root `pubspec_overrides.yaml` (git-ignored), e.g.
///
/// ```yaml
/// dependency_overrides:
///   restaurant_extensions:
///     path: ../my-extensions/packages/extensions
/// ```
///
/// That package must expose the same `merchantExtensions()` function.
library;

import 'package:restaurant_extension_api/restaurant_extension_api.dart';

List<MerchantExtension> merchantExtensions() => const [];
