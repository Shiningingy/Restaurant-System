// Plain-Dart geometry for the photo-capture feature. Deliberately free of
// `dart:ui` so the capture engine and templates are trivially unit-testable.

/// A rectangle in image-pixel space: absolute coordinates within a photo.
class PixelBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const PixelBox(this.left, this.top, this.right, this.bottom);

  /// Builds a box from a left/top origin plus a width/height.
  factory PixelBox.ltwh(double left, double top, double width, double height) =>
      PixelBox(left, top, left + width, top + height);

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  /// Whether a point falls inside the box (left/top inclusive, right/bottom
  /// exclusive) — used to test a text token's centre against a region.
  bool contains(double x, double y) =>
      x >= left && x < right && y >= top && y < bottom;
}

/// A rectangle expressed in fractions (0..1) of a parent "big block", so a
/// template re-applies wherever the block is placed on a photo.
class RegionRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const RegionRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Maps this normalized rect into image-pixel space for a given placement of
  /// the big block.
  PixelBox toPixels(PixelBox block) => PixelBox.ltwh(
    block.left + left * block.width,
    block.top + top * block.height,
    width * block.width,
    height * block.height,
  );

  Map<String, dynamic> toJson() => {
    'l': left,
    't': top,
    'w': width,
    'h': height,
  };

  factory RegionRect.fromJson(Map<String, dynamic> json) => RegionRect(
    left: (json['l'] as num).toDouble(),
    top: (json['t'] as num).toDouble(),
    width: (json['w'] as num).toDouble(),
    height: (json['h'] as num).toDouble(),
  );
}
