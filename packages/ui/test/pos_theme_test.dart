import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_ui/restaurant_ui.dart';

void main() {
  group('buildPosTheme', () {
    test('attaches the PosStatusColors extension (light + dark)', () {
      expect(buildPosTheme().extension<PosStatusColors>(), PosStatusColors.light);
      expect(
        buildPosTheme(brightness: Brightness.dark).extension<PosStatusColors>(),
        PosStatusColors.dark,
      );
    });

    test('keeps the deepOrange-derived terracotta primary (refine-not-reskin)', () {
      // M3 fromSeed(deepOrange) lands the primary on terracotta #8F4C38, NOT
      // the vivid seed. This is the recognizable brand — guard it.
      expect(buildPosTheme().colorScheme.primary, const Color(0xFF8F4C38));
    });

    test('enforces the POS touch-target floor', () {
      final theme = buildPosTheme();
      // Pay-class FilledButton: 52 min height (kiosk bumps to 64).
      final filled = theme.filledButtonTheme.style!
          .minimumSize!
          .resolve({})!;
      expect(filled.height, 52);
      // Send/Split-class OutlinedButton: 48 min height.
      final outlined = theme.outlinedButtonTheme.style!
          .minimumSize!
          .resolve({})!;
      expect(outlined.height, 48);
    });

    test('kiosk variant scales type up and Pay button to 64', () {
      final kiosk = buildPosTheme(kiosk: true);
      final filled = kiosk.filledButtonTheme.style!.minimumSize!.resolve({})!;
      expect(filled.height, 64);
    });
  });

  test('moneyTextStyle requests tabular figures', () {
    final style = moneyTextStyle(const TextStyle(fontSize: 20));
    expect(style.fontSize, 20);
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  test('PosStatusColors lerp is stable at the endpoints', () {
    expect(PosStatusColors.light.lerp(PosStatusColors.dark, 0).success,
        PosStatusColors.light.success);
    expect(PosStatusColors.light.lerp(PosStatusColors.dark, 1).success,
        PosStatusColors.dark.success);
  });
}
