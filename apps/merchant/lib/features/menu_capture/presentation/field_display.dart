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
