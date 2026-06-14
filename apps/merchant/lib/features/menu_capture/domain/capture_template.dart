import 'geometry.dart';

/// Which menu-item field a template region feeds. `attribute` uses the region's
/// `label` as the custom field name; `image` crops the region into a photo.
enum CaptureField { code, name, nameSecondary, price, attribute, image }

/// One labelled rectangle inside a capture template, positioned relative to the
/// big block (see [RegionRect]).
class CaptureRegion {
  final String id;
  final CaptureField field;

  /// For `attribute` regions this is the custom-field label; for others it is a
  /// human display name shown in the editor. May be empty.
  final String label;
  final RegionRect rect;

  const CaptureRegion({
    required this.id,
    required this.field,
    required this.label,
    required this.rect,
  });

  CaptureRegion copyWith({
    CaptureField? field,
    String? label,
    RegionRect? rect,
  }) => CaptureRegion(
    id: id,
    field: field ?? this.field,
    label: label ?? this.label,
    rect: rect ?? this.rect,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'field': field.name,
    'label': label,
    'rect': rect.toJson(),
  };

  factory CaptureRegion.fromJson(Map<String, dynamic> json) => CaptureRegion(
    id: json['id'] as String,
    field: CaptureField.values.byName(json['field'] as String),
    label: (json['label'] as String?) ?? '',
    rect: RegionRect.fromJson(json['rect'] as Map<String, dynamic>),
  );
}

/// The block a new template starts with, and the fallback for templates saved
/// before the block was persisted.
const kDefaultCaptureBlock = RegionRect(
  left: 0.1,
  top: 0.1,
  width: 0.5,
  height: 0.4,
);

/// A reusable, named layout of regions the merchant defines once and sweeps over
/// each item in a menu photo. Stored locally (shared_preferences), not synced.
///
/// [block] is the big-block placement the merchant framed an item with while
/// designing; it seeds the block in the editor and at capture so the regions
/// keep the same proportions in both.
class CaptureTemplate {
  final String id;
  final String name;
  final List<CaptureRegion> regions;
  final RegionRect block;

  const CaptureTemplate({
    required this.id,
    required this.name,
    required this.regions,
    this.block = kDefaultCaptureBlock,
  });

  CaptureTemplate copyWith({
    String? name,
    List<CaptureRegion>? regions,
    RegionRect? block,
  }) => CaptureTemplate(
    id: id,
    name: name ?? this.name,
    regions: regions ?? this.regions,
    block: block ?? this.block,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'regions': regions.map((r) => r.toJson()).toList(),
    'block': block.toJson(),
  };

  factory CaptureTemplate.fromJson(Map<String, dynamic> json) =>
      CaptureTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        regions: (json['regions'] as List<dynamic>)
            .map((r) => CaptureRegion.fromJson(r as Map<String, dynamic>))
            .toList(),
        block: json['block'] == null
            ? kDefaultCaptureBlock
            : RegionRect.fromJson(json['block'] as Map<String, dynamic>),
      );
}
