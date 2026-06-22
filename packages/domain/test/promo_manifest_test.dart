import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

void main() {
  group('PromoImageRef', () {
    test('content-addressed storage key and file name', () {
      const ref = PromoImageRef(sha: 'abc123', ext: '.jpg');
      expect(ref.storageKey, 'promo/abc123.jpg');
      expect(ref.fileName, 'abc123.jpg');
    });

    test('value equality by sha + ext', () {
      expect(
        const PromoImageRef(sha: 'a', ext: '.png'),
        const PromoImageRef(sha: 'a', ext: '.png'),
      );
      expect(
        const PromoImageRef(sha: 'a', ext: '.png'),
        isNot(const PromoImageRef(sha: 'b', ext: '.png')),
      );
    });
  });

  group('PromoManifest', () {
    final manifest = PromoManifest([
      const PromoImageRef(sha: 'one', ext: '.jpg'),
      const PromoImageRef(sha: 'two', ext: '.png'),
    ]);

    test('encode -> tryParse round-trips, order preserved', () {
      final parsed = PromoManifest.tryParse(manifest.encode());
      expect(parsed, isNotNull);
      expect(parsed!.images, manifest.images);
    });

    test('encode -> tryParse round-trips the promo text lines', () {
      final withText = PromoManifest(
        manifest.images,
        lines: const ['Line one', 'Line two'],
      );
      final parsed = PromoManifest.tryParse(withText.encode());
      expect(parsed!.lines, ['Line one', 'Line two']);
    });

    test('a manifest written before text-sync (no lines key) parses empty', () {
      final bytes = '{"version":1,"images":[]}'.codeUnits;
      final parsed = PromoManifest.tryParse(bytes);
      expect(parsed, isNotNull);
      expect(parsed!.lines, isEmpty);
    });

    test('tryParse rejects a newer version', () {
      final bytes = '{"version":999,"images":[]}'.codeUnits;
      expect(PromoManifest.tryParse(bytes), isNull);
    });

    test('tryParse rejects malformed JSON', () {
      expect(PromoManifest.tryParse('not json'.codeUnits), isNull);
    });

    test('missingFrom returns only refs absent from the local cache', () {
      final missing = manifest.missingFrom({'one'});
      expect(missing, [const PromoImageRef(sha: 'two', ext: '.png')]);
    });

    test('missingFrom is empty when everything is cached', () {
      expect(manifest.missingFrom({'one', 'two'}), isEmpty);
    });
  });
}
