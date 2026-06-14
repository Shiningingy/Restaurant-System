import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../domain/capture_template.dart';

/// Consistent colour per capture-field type, so a region reads the same in the
/// template editor and the capture sweep.
Color captureFieldColor(CaptureField field) => switch (field) {
  CaptureField.code => Colors.orange,
  CaptureField.name => Colors.blue,
  CaptureField.nameSecondary => Colors.teal,
  CaptureField.price => Colors.green,
  CaptureField.attribute => Colors.purple,
  CaptureField.image => Colors.pink,
};

/// Distinct colours for the (otherwise all-purple) custom-field regions, so
/// several `attribute` boxes are told apart at a glance.
const _attributePalette = [
  Colors.purple,
  Colors.brown,
  Colors.indigo,
  Colors.cyan,
  Colors.deepOrange,
  Colors.blueGrey,
];

/// Assigns a display colour to every region: fixed by field type, except
/// `attribute` regions which each draw the next colour from [_attributePalette]
/// by their order among attribute regions.
Map<String, Color> captureRegionColors(List<CaptureRegion> regions) {
  final colors = <String, Color>{};
  var attrIndex = 0;
  for (final r in regions) {
    if (r.field == CaptureField.attribute) {
      colors[r.id] = _attributePalette[attrIndex % _attributePalette.length];
      attrIndex++;
    } else {
      colors[r.id] = captureFieldColor(r.field);
    }
  }
  return colors;
}

/// Localized display name for a capture-field type.
String captureFieldLabel(BuildContext context, CaptureField field) =>
    switch (field) {
      CaptureField.code => context.l10n.captureFieldCode,
      CaptureField.name => context.l10n.captureFieldName,
      CaptureField.nameSecondary => context.l10n.captureFieldNameSecondary,
      CaptureField.price => context.l10n.captureFieldPrice,
      CaptureField.attribute => context.l10n.captureFieldAttribute,
      CaptureField.image => context.l10n.captureFieldImage,
    };
