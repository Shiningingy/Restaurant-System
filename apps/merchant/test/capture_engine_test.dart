import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/menu_capture/application/capture_engine.dart';
import 'package:merchant/features/menu_capture/domain/capture_template.dart';
import 'package:merchant/features/menu_capture/domain/geometry.dart';
import 'package:merchant/features/menu_capture/domain/text_recognizer.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

/// A token sized 20x10 centred on (x, y) — keeps the geometry readable.
TextToken _tok(String text, double x, double y) =>
    TextToken(text, PixelBox.ltwh(x - 10, y - 5, 20, 10));

void main() {
  const engine = CaptureEngine();

  // A template whose big block is a unit square split into four stacked rows:
  // code (top), name, second name, price (bottom). The image region sits to the
  // right of the name row.
  final template = CaptureTemplate(
    id: 't1',
    name: 'Standard',
    regions: [
      CaptureRegion(
        id: 'r-code',
        field: CaptureField.code,
        label: 'Code',
        rect: const RegionRect(left: 0, top: 0.0, width: 0.6, height: 0.25),
      ),
      CaptureRegion(
        id: 'r-name',
        field: CaptureField.name,
        label: 'Name',
        rect: const RegionRect(left: 0, top: 0.25, width: 0.6, height: 0.25),
      ),
      CaptureRegion(
        id: 'r-name2',
        field: CaptureField.nameSecondary,
        label: 'Second name',
        rect: const RegionRect(left: 0, top: 0.5, width: 0.6, height: 0.25),
      ),
      CaptureRegion(
        id: 'r-price',
        field: CaptureField.price,
        label: 'Price',
        rect: const RegionRect(left: 0, top: 0.75, width: 0.6, height: 0.25),
      ),
      CaptureRegion(
        id: 'r-img',
        field: CaptureField.image,
        label: 'Photo',
        rect: const RegionRect(left: 0.6, top: 0, width: 0.4, height: 1),
      ),
    ],
  );

  test('maps tokens by region into a draft, parsing a \$-prefixed price', () {
    // Big block over a 100x100 item starting at (0,0).
    final block = PixelBox.ltwh(0, 0, 100, 100);
    // Rows centre at y = 12.5, 37.5, 62.5, 87.5 within the left 60px column.
    final ocr = RecognizedText(
      imageWidth: 100,
      imageHeight: 100,
      tokens: [
        _tok('A01', 20, 12),
        _tok('Beef', 15, 37),
        _tok('Noodle', 40, 37),
        _tok('牛肉面', 25, 62),
        _tok(r'$12.50', 25, 87),
      ],
    );

    final draft = engine.buildDraft(ocr, template, block);

    expect(draft.code, 'A01');
    expect(draft.name, 'Beef Noodle'); // two tokens joined in reading order
    expect(draft.nameSecondary, '牛肉面');
    expect(draft.price, const Money(1250));
    // The image region produced one crop box on the right of the block.
    expect(draft.imageBoxes, hasLength(1));
    expect(draft.imageBoxes.single.left, 60);
    expect(draft.attributes, isEmpty);
    expect(draft.isEmpty, isFalse);
  });

  test('the same template at a shifted placement extracts the next item', () {
    // Sweep the block down to the second item (y origin 100).
    final block = PixelBox.ltwh(0, 100, 100, 100);
    final ocr = RecognizedText(
      imageWidth: 100,
      imageHeight: 200,
      tokens: [
        _tok('A02', 20, 112),
        _tok('Rice', 15, 137),
        _tok('米饭', 25, 162),
        _tok('3', 25, 187),
        // A stray token far outside the block — must be ignored.
        _tok('IGNORE', 500, 500),
      ],
    );

    final draft = engine.buildDraft(ocr, template, block);

    expect(draft.code, 'A02');
    expect(draft.name, 'Rice');
    expect(draft.nameSecondary, '米饭');
    expect(draft.price, const Money(300)); // "3" -> $3.00
  });

  test('attribute regions become labelled custom fields', () {
    final attrTemplate = CaptureTemplate(
      id: 't2',
      name: 'With ingredients',
      regions: [
        CaptureRegion(
          id: 'r-name',
          field: CaptureField.name,
          label: 'Name',
          rect: const RegionRect(left: 0, top: 0, width: 1, height: 0.5),
        ),
        CaptureRegion(
          id: 'r-attr',
          field: CaptureField.attribute,
          label: 'Ingredients',
          rect: const RegionRect(left: 0, top: 0.5, width: 1, height: 0.5),
        ),
      ],
    );
    final block = PixelBox.ltwh(0, 0, 100, 100);
    final ocr = RecognizedText(
      imageWidth: 100,
      imageHeight: 100,
      tokens: [
        _tok('Soup', 20, 25),
        _tok('Tomato,', 20, 75),
        _tok('basil', 45, 75),
      ],
    );

    final draft = engine.buildDraft(ocr, attrTemplate, block);

    expect(draft.name, 'Soup');
    expect(draft.attributes, hasLength(1));
    expect(draft.attributes.single.label, 'Ingredients');
    expect(draft.attributes.single.value, 'Tomato, basil');
  });

  test('a placement on empty space yields an empty draft', () {
    final block = PixelBox.ltwh(0, 0, 100, 100);
    const ocr = RecognizedText(imageWidth: 100, imageHeight: 100, tokens: []);
    final draft = engine.buildDraft(ocr, template, block);
    // Only the image region (no text) fires; text fields stay null.
    expect(draft.code, isNull);
    expect(draft.name, isNull);
    expect(draft.price, isNull);
  });
}
