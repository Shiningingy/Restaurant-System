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

/// A reusable, named layout of regions the merchant defines once and sweeps over
/// each item in a menu photo. Stored locally (shared_preferences), not synced.
class CaptureTemplate {
  final String id;
  final String name;
  final List<CaptureRegion> regions;

  const CaptureTemplate({
    required this.id,
    required this.name,
    required this.regions,
  });

  CaptureTemplate copyWith({String? name, List<CaptureRegion>? regions}) =>
      CaptureTemplate(
        id: id,
        name: name ?? this.name,
        regions: regions ?? this.regions,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'regions': regions.map((r) => r.toJson()).toList(),
  };

  factory CaptureTemplate.fromJson(Map<String, dynamic> json) =>
      CaptureTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        regions: (json['regions'] as List<dynamic>)
            .map((r) => CaptureRegion.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}
