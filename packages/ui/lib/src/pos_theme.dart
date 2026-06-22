import 'package:flutter/material.dart';

import 'pos_status_colors.dart';

/// The shared visual foundation for every Restaurant System surface — the
/// merchant POS, the customer preorder app, and the customer display / kiosk.
///
/// It is *refine-not-reskin*: the colour scheme is still the stock M3 tonal
/// palette from the deepOrange seed (so nothing changes hue), and the only
/// codified additions are the ones the design handoff calls out —
///
///  - the POS accessibility touch-target floor (shop testing found the M3
///    minimums too small): Pay **64**, Send/Split **52**, rows & category **48**;
///  - tabular money figures (Roboto Mono) so prices and totals don't jitter;
///  - the M3 corner scale, made explicit (cards 12, sheets/dialogs 16, FAB 28);
///  - the [PosStatusColors] extension (order-state + brand-mark-navy tokens).
///
/// Pass [kiosk] for the customer-facing, arm's-length variant (~1.15× type and
/// roomier controls).
ThemeData buildPosTheme({
  Brightness brightness = Brightness.light,
  bool kiosk = false,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
    brightness: brightness,
  );
  final status = brightness == Brightness.dark
      ? PosStatusColors.dark
      : PosStatusColors.light;

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    extensions: [status],

    // ---- Touch-target floor (the POS accessibility override of M3) ----
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(_kControlLg),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_kRadiusFull)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(_kControlMd),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_kRadiusFull)),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 8),

    // ---- M3 corner scale, made explicit ----
    cardTheme: CardThemeData(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_kRadiusCard)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_kRadiusDialog)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_kRadiusSheet),
        ),
      ),
    ),
  );

  if (!kiosk) return base;

  // Kiosk: same palette, scaled up for arm's-length, forgiving touch.
  return base.copyWith(
    textTheme: _scaleTextTheme(base.textTheme, _kKioskScale),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(_kControlXl),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_kRadiusFull)),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 12,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    ),
  );
}

/// A [TextStyle] for money figures: tabular (Roboto Mono), so digits line up in
/// columns and a changing total doesn't shift the layout. Build from the base
/// style at the call site, e.g. `context.moneyStyle(textTheme.titleLarge)`.
TextStyle moneyTextStyle(TextStyle? base) =>
    (base ?? const TextStyle()).copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Roboto Mono'],
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// Scales every text style's [TextStyle.fontSize] by [factor].
///
/// Like `TextTheme.apply(fontSizeFactor:)` but null-safe: a style with no
/// explicit `fontSize` is left untouched instead of asserting. (Headless unit
/// tests can hand back a colour-only text theme whose sizes are null; the real
/// app's typography always has them — so this only matters for robustness.)
TextTheme _scaleTextTheme(TextTheme t, double factor) {
  TextStyle? s(TextStyle? x) =>
      x?.fontSize == null ? x : x!.copyWith(fontSize: x.fontSize! * factor);
  return t.copyWith(
    displayLarge: s(t.displayLarge),
    displayMedium: s(t.displayMedium),
    displaySmall: s(t.displaySmall),
    headlineLarge: s(t.headlineLarge),
    headlineMedium: s(t.headlineMedium),
    headlineSmall: s(t.headlineSmall),
    titleLarge: s(t.titleLarge),
    titleMedium: s(t.titleMedium),
    titleSmall: s(t.titleSmall),
    bodyLarge: s(t.bodyLarge),
    bodyMedium: s(t.bodyMedium),
    bodySmall: s(t.bodySmall),
    labelLarge: s(t.labelLarge),
    labelMedium: s(t.labelMedium),
    labelSmall: s(t.labelSmall),
  );
}

// The big Pay button.
const double _kControlXl = 64;
// Send to kitchen / Split.
const double _kControlLg = 52;
// Category buttons, list rows — the absolute floor.
const double _kControlMd = 48;

const double _kRadiusCard = 12;
const double _kRadiusSheet = 16;
const double _kRadiusDialog = 28;
const double _kRadiusFull = 999;

const double _kKioskScale = 1.15;
