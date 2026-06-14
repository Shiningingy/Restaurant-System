import 'package:restaurant_domain/restaurant_domain.dart';

import '../domain/capture_template.dart';
import '../domain/geometry.dart';
import '../domain/item_draft.dart';
import '../domain/text_recognizer.dart';

/// Pure mapping from OCR + a template placement to a draft menu item. This is
/// the heart of the capture feature and is fully unit-testable: OCR the whole
/// photo once, then call this for each placement of the big block as the user
/// sweeps it over the menu.
class CaptureEngine {
  const CaptureEngine();

  /// Builds one [ItemDraft] from the [ocr] tokens that fall inside each region
  /// of [template], when the big block is positioned at [block] (image pixels).
  ItemDraft buildDraft(
    RecognizedText ocr,
    CaptureTemplate template,
    PixelBox block,
  ) {
    final draft = ItemDraft();
    for (final region in template.regions) {
      final box = region.rect.toPixels(block);

      if (region.field == CaptureField.image) {
        draft.imageBoxes.add(box);
        continue;
      }

      final text = _textInBox(ocr, box);
      if (text.isEmpty) continue;

      switch (region.field) {
        case CaptureField.code:
          draft.code = text;
        case CaptureField.name:
          draft.name = text;
        case CaptureField.nameSecondary:
          draft.nameSecondary = text;
        case CaptureField.price:
          draft.price = Money.tryParse(_cleanPrice(text));
        case CaptureField.attribute:
          draft.attributes.add(
            MenuItemAttribute(
              id: newId(),
              label: region.label,
              value: text,
              sortOrder: draft.attributes.length,
            ),
          );
        case CaptureField.image:
          break; // handled above
      }
    }
    return draft;
  }

  /// Collects the tokens whose centre falls inside [box], orders them in reading
  /// order (top→bottom, then left→right within a line), and joins them.
  String _textInBox(RecognizedText ocr, PixelBox box) {
    final tokens =
        ocr.tokens
            .where((t) => box.contains(t.box.centerX, t.box.centerY))
            .toList()
          ..sort(_readingOrder);
    return tokens.map((t) => t.text).join(' ').trim();
  }

  /// Strips currency symbols and stray characters so "$12.50" / "RMB 12" parse.
  String _cleanPrice(String text) => text.replaceAll(RegExp(r'[^\d.]'), '');

  /// Tokens close in vertical position are treated as one line and ordered
  /// left→right; otherwise top→bottom.
  static int _readingOrder(TextToken a, TextToken b) {
    final tolerance = (a.box.height + b.box.height) / 4;
    if ((a.box.centerY - b.box.centerY).abs() > tolerance) {
      return a.box.centerY.compareTo(b.box.centerY);
    }
    return a.box.centerX.compareTo(b.box.centerX);
  }
}
