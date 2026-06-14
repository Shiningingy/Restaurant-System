import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/geometry.dart';

/// Reads the intrinsic pixel size of an image file (for aspect-correct display
/// and for converting normalized boxes to OCR pixel space).
Future<Size> imageSizeOf(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final size = Size(image.width.toDouble(), image.height.toDouble());
  image.dispose();
  return size;
}

/// A sub-region drawn inside the big block, shown as a labelled coloured box.
class CanvasRegion {
  final String id;
  final RegionRect rect; // normalized to the big block
  final Color color;
  final String label;

  const CanvasRegion({
    required this.id,
    required this.rect,
    required this.color,
    required this.label,
  });
}

enum _Drag { none, moveBlock, resizeBlock, moveRegion, resizeRegion }

/// Displays a photo with a draggable/resizable "big block" and a set of
/// sub-regions positioned relative to that block. Editing is opt-in per layer:
/// pass `onBlockChanged` to make the block movable, `onRegionChanged` to make
/// the sub-regions editable. Used by both the template editor (regions editable)
/// and the capture sweep (block movable, regions are read-only guides).
class PhotoBoxCanvas extends StatefulWidget {
  final String imagePath;
  final Size imageSize;
  final RegionRect block;
  final ValueChanged<RegionRect>? onBlockChanged;
  final List<CanvasRegion> regions;
  final String? selectedRegionId;
  final ValueChanged<String>? onSelectRegion;
  final void Function(String id, RegionRect rect)? onRegionChanged;

  const PhotoBoxCanvas({
    super.key,
    required this.imagePath,
    required this.imageSize,
    required this.block,
    this.onBlockChanged,
    this.regions = const [],
    this.selectedRegionId,
    this.onSelectRegion,
    this.onRegionChanged,
  });

  @override
  State<PhotoBoxCanvas> createState() => _PhotoBoxCanvasState();
}

class _PhotoBoxCanvasState extends State<PhotoBoxCanvas> {
  static const _handle = 24.0;

  _Drag _drag = _Drag.none;
  String? _dragRegionId;
  RegionRect _startRect = const RegionRect(
    left: 0,
    top: 0,
    width: 0,
    height: 0,
  );
  Offset _startPointer = Offset.zero;

  /// The image's displayed rectangle (BoxFit.contain, centred) in widget space.
  Rect _displayRect(Size area) {
    final imageAspect = widget.imageSize.width / widget.imageSize.height;
    final areaAspect = area.width / area.height;
    double w, h;
    if (areaAspect > imageAspect) {
      h = area.height;
      w = h * imageAspect;
    } else {
      w = area.width;
      h = w / imageAspect;
    }
    return Rect.fromLTWH((area.width - w) / 2, (area.height - h) / 2, w, h);
  }

  Rect _blockRect(Rect dr) => Rect.fromLTWH(
    dr.left + widget.block.left * dr.width,
    dr.top + widget.block.top * dr.height,
    widget.block.width * dr.width,
    widget.block.height * dr.height,
  );

  Rect _regionRect(Rect blockRect, RegionRect r) => Rect.fromLTWH(
    blockRect.left + r.left * blockRect.width,
    blockRect.top + r.top * blockRect.height,
    r.width * blockRect.width,
    r.height * blockRect.height,
  );

  bool _inHandle(Rect box, Offset p) => Rect.fromLTWH(
    box.right - _handle,
    box.bottom - _handle,
    _handle,
    _handle,
  ).contains(p);

  void _onPanStart(Offset p, Rect dr) {
    final blockRect = _blockRect(dr);

    // Sub-regions take priority (topmost first) when editable.
    if (widget.onRegionChanged != null) {
      for (final region in widget.regions.reversed) {
        final rr = _regionRect(blockRect, region.rect);
        if (_inHandle(rr, p)) {
          _begin(_Drag.resizeRegion, region.rect, p, region.id);
          widget.onSelectRegion?.call(region.id);
          return;
        }
        if (rr.contains(p)) {
          _begin(_Drag.moveRegion, region.rect, p, region.id);
          widget.onSelectRegion?.call(region.id);
          return;
        }
      }
    }

    if (widget.onBlockChanged != null) {
      if (_inHandle(blockRect, p)) {
        _begin(_Drag.resizeBlock, widget.block, p, null);
        return;
      }
      if (blockRect.contains(p)) {
        _begin(_Drag.moveBlock, widget.block, p, null);
        return;
      }
    }
    _drag = _Drag.none;
  }

  void _begin(_Drag kind, RegionRect rect, Offset p, String? regionId) {
    _drag = kind;
    _startRect = rect;
    _startPointer = p;
    _dragRegionId = regionId;
  }

  void _onPanUpdate(Offset p, Rect dr) {
    switch (_drag) {
      case _Drag.none:
        return;
      case _Drag.moveBlock:
        final dx = (p.dx - _startPointer.dx) / dr.width;
        final dy = (p.dy - _startPointer.dy) / dr.height;
        widget.onBlockChanged!(
          RegionRect(
            left: (_startRect.left + dx).clamp(0.0, 1 - _startRect.width),
            top: (_startRect.top + dy).clamp(0.0, 1 - _startRect.height),
            width: _startRect.width,
            height: _startRect.height,
          ),
        );
      case _Drag.resizeBlock:
        widget.onBlockChanged!(
          RegionRect(
            left: _startRect.left,
            top: _startRect.top,
            width: ((p.dx - dr.left) / dr.width - _startRect.left).clamp(
              0.05,
              1 - _startRect.left,
            ),
            height: ((p.dy - dr.top) / dr.height - _startRect.top).clamp(
              0.05,
              1 - _startRect.top,
            ),
          ),
        );
      case _Drag.moveRegion:
        final blockRect = _blockRect(dr);
        final dx = (p.dx - _startPointer.dx) / blockRect.width;
        final dy = (p.dy - _startPointer.dy) / blockRect.height;
        widget.onRegionChanged!(
          _dragRegionId!,
          RegionRect(
            left: (_startRect.left + dx).clamp(0.0, 1 - _startRect.width),
            top: (_startRect.top + dy).clamp(0.0, 1 - _startRect.height),
            width: _startRect.width,
            height: _startRect.height,
          ),
        );
      case _Drag.resizeRegion:
        final blockRect = _blockRect(dr);
        widget.onRegionChanged!(
          _dragRegionId!,
          RegionRect(
            left: _startRect.left,
            top: _startRect.top,
            width: ((p.dx - blockRect.left) / blockRect.width - _startRect.left)
                .clamp(0.05, 1 - _startRect.left),
            height: ((p.dy - blockRect.top) / blockRect.height - _startRect.top)
                .clamp(0.05, 1 - _startRect.top),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dr = _displayRect(constraints.biggest);
        final blockRect = _blockRect(dr);
        final blockEditable = widget.onBlockChanged != null;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _onPanStart(d.localPosition, dr),
          onPanUpdate: (d) => _onPanUpdate(d.localPosition, dr),
          onPanEnd: (_) => _drag = _Drag.none,
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: dr,
                child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
              ),
              // The big block.
              Positioned.fromRect(
                rect: blockRect,
                child: _BoxFrame(
                  color: Colors.lightBlueAccent,
                  thick: true,
                  showHandle: blockEditable,
                ),
              ),
              // Sub-regions.
              for (final region in widget.regions)
                Positioned.fromRect(
                  rect: _regionRect(blockRect, region.rect),
                  child: _BoxFrame(
                    color: region.color,
                    label: region.label,
                    selected: region.id == widget.selectedRegionId,
                    showHandle: widget.onRegionChanged != null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BoxFrame extends StatelessWidget {
  final Color color;
  final String? label;
  final bool thick;
  final bool selected;
  final bool showHandle;

  const _BoxFrame({
    required this.color,
    this.label,
    this.thick = false,
    this.selected = false,
    this.showHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: selected ? 3 : (thick ? 3 : 2)),
        color: selected ? color.withValues(alpha: 0.12) : null,
      ),
      child: Stack(
        children: [
          if (label != null && label!.isNotEmpty)
            Positioned(
              left: 0,
              top: 0,
              child: ColoredBox(
                color: color,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Text(
                    label!,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
          if (showHandle)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
