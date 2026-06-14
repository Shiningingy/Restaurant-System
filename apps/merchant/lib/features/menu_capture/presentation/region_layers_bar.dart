import 'package:flutter/material.dart';

import '../domain/capture_template.dart';
import 'field_display.dart';

/// A horizontal, scrollable strip of region "layers" — tap one to make it the
/// active (selectable/movable) region. Shared by the template editor and the
/// capture sweep so selection behaves identically in both. Wrap in `Expanded`.
class RegionChips extends StatelessWidget {
  final List<CaptureRegion> regions;
  final Map<String, Color> colors;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const RegionChips({
    super.key,
    required this.regions,
    required this.colors,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final r in regions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                avatar: CircleAvatar(backgroundColor: colors[r.id], radius: 8),
                label: Text(
                  r.label.isEmpty
                      ? captureFieldLabel(context, r.field)
                      : r.label,
                ),
                selected: r.id == selectedId,
                onSelected: (_) => onSelect(r.id),
              ),
            ),
        ],
      ),
    );
  }
}
