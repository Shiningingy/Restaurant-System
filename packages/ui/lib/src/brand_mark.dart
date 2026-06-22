import 'dart:io';

import 'package:flutter/material.dart';

/// The shop's brand mark — a logo the owner sets in Settings, shown wherever
/// the app brands itself (nav rail, customer display, kiosk).
///
/// Brand-neutral by default: when no logo is configured (or the file is
/// missing) it falls back to the generic `restaurant` Material glyph — the
/// design system's stand-in for an absent per-shop logo, tinted with
/// [fallbackColor]. So a multi-shop build needs no code change: each shop just
/// picks its own logo.
class BrandMark extends StatelessWidget {
  /// Absolute path to the configured logo image, or null/empty for none.
  final String? logoPath;
  final double size;

  /// Colour of the generic-glyph fallback (ignored when a logo loads).
  final Color? fallbackColor;

  const BrandMark({
    super.key,
    required this.logoPath,
    this.size = 40,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final path = logoPath;
    if (path != null && path.isNotEmpty) {
      return Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, _, _) => _glyph(context),
      );
    }
    return _glyph(context);
  }

  Widget _glyph(BuildContext context) => Icon(
    Icons.restaurant,
    size: size * 0.72,
    color: fallbackColor ?? Theme.of(context).colorScheme.onSurface,
  );
}
