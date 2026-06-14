import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/menu_capture/data/capture_template_store.dart';
import 'package:merchant/features/menu_capture/domain/capture_template.dart';
import 'package:merchant/features/menu_capture/domain/geometry.dart';
import 'package:shared_preferences/shared_preferences.dart';

CaptureTemplate _sample(String id, String name) => CaptureTemplate(
  id: id,
  name: name,
  regions: [
    CaptureRegion(
      id: '$id-name',
      field: CaptureField.name,
      label: 'Name',
      rect: const RegionRect(left: 0, top: 0, width: 1, height: 0.5),
    ),
    CaptureRegion(
      id: '$id-price',
      field: CaptureField.price,
      label: 'Price',
      rect: const RegionRect(left: 0, top: 0.5, width: 0.5, height: 0.5),
    ),
  ],
);

void main() {
  test('CaptureTemplate JSON round-trips, preserving regions and fields', () {
    final t = _sample('t1', 'Standard');
    final back = CaptureTemplate.fromJson(t.toJson());

    expect(back.id, 't1');
    expect(back.name, 'Standard');
    expect(back.regions, hasLength(2));
    expect(back.regions[0].field, CaptureField.name);
    expect(back.regions[1].field, CaptureField.price);
    expect(back.regions[1].rect.width, 0.5);
    expect(back.regions[1].label, 'Price');
  });

  group('CaptureTemplateStore', () {
    late CaptureTemplateStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = CaptureTemplateStore(await SharedPreferences.getInstance());
    });

    test('starts empty', () {
      expect(store.list(), isEmpty);
    });

    test('save inserts, then updates in place by id', () async {
      await store.save(_sample('a', 'First'));
      await store.save(_sample('b', 'Second'));
      expect(store.list(), hasLength(2));

      await store.save(_sample('a', 'First renamed'));
      final all = store.list();
      expect(all, hasLength(2)); // updated, not duplicated
      expect(all.firstWhere((t) => t.id == 'a').name, 'First renamed');
    });

    test('delete removes by id and persists', () async {
      await store.save(_sample('a', 'First'));
      await store.save(_sample('b', 'Second'));
      await store.delete('a');

      final reloaded = CaptureTemplateStore(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.list().map((t) => t.id), ['b']);
    });
  });
}
