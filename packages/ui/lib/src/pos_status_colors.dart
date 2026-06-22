import 'package:flutter/material.dart';

/// POS status + brand-mark colours that live *outside* the Material 3 scheme.
///
/// The app's [ColorScheme] is generated from the deepOrange seed and already
/// produces every brand/surface colour the design system calls for. Only these
/// extras are genuine additions:
///
///  - order-state status colours (success / warning / info) — used as
///    `pill background + on-colour` pairs, **always with an icon + text label**,
///    never colour alone (the POS runs on bright counters).
///  - the brand-mark navy — the Yee-Sushi-style *logo* colour, for logo lockups
///    and branded signage fields only. The POS chrome itself stays terracotta
///    (`colorScheme.primary`); never use navy for controls.
///
/// Values come straight from the design handoff (`tokens/colors.css`), with a
/// dark variant that mirrors the M3 tonal flip.
@immutable
class PosStatusColors extends ThemeExtension<PosStatusColors> {
  /// Ready / approved / paid.
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Preparing / waiting / proposed-time.
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// Online / informational.
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Logo-only navy (and its on-colour). Not a chrome colour.
  final Color brandMarkNavy;
  final Color onBrandMarkNavy;

  const PosStatusColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.brandMarkNavy,
    required this.onBrandMarkNavy,
  });

  static const light = PosStatusColors(
    success: Color(0xFF1F6E43),
    successContainer: Color(0xFFB7F1C6),
    onSuccessContainer: Color(0xFF00210F),
    warning: Color(0xFF8A5A00),
    warningContainer: Color(0xFFFFDEA8),
    onWarningContainer: Color(0xFF2B1700),
    info: Color(0xFF36618E),
    infoContainer: Color(0xFFD2E4FF),
    onInfoContainer: Color(0xFF001C38),
    brandMarkNavy: Color(0xFF0F145A),
    onBrandMarkNavy: Color(0xFFFFFFFF),
  );

  static const dark = PosStatusColors(
    success: Color(0xFF6FD99A),
    successContainer: Color(0xFF00522C),
    onSuccessContainer: Color(0xFFB7F1C6),
    warning: Color(0xFFFFB95C),
    warningContainer: Color(0xFF6A4200),
    onWarningContainer: Color(0xFFFFDEA8),
    info: Color(0xFFA1C9FD),
    infoContainer: Color(0xFF1B4975),
    onInfoContainer: Color(0xFFD2E4FF),
    // Navy stays a fixed logo colour across themes; its on-colour is white.
    brandMarkNavy: Color(0xFF0F145A),
    onBrandMarkNavy: Color(0xFFFFFFFF),
  );

  @override
  PosStatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? brandMarkNavy,
    Color? onBrandMarkNavy,
  }) {
    return PosStatusColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      brandMarkNavy: brandMarkNavy ?? this.brandMarkNavy,
      onBrandMarkNavy: onBrandMarkNavy ?? this.onBrandMarkNavy,
    );
  }

  @override
  PosStatusColors lerp(ThemeExtension<PosStatusColors>? other, double t) {
    if (other is! PosStatusColors) return this;
    return PosStatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      brandMarkNavy: Color.lerp(brandMarkNavy, other.brandMarkNavy, t)!,
      onBrandMarkNavy: Color.lerp(onBrandMarkNavy, other.onBrandMarkNavy, t)!,
    );
  }
}

/// Convenience accessor: `context.posStatus.success`. Falls back to the light
/// set if (somehow) the extension wasn't registered, so callers never null-crash.
extension PosStatusColorsX on BuildContext {
  PosStatusColors get posStatus =>
      Theme.of(this).extension<PosStatusColors>() ?? PosStatusColors.light;
}
