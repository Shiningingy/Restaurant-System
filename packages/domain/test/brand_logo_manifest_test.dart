import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

void main() {
  group('BrandLogoManifest', () {
    test('content-addressed file name', () {
      const m = BrandLogoManifest(sha: 'abc', ext: '.png');
      expect(m.hasLogo, isTrue);
      expect(m.fileName, 'abc.png');
    });

    test('none means no logo', () {
      expect(BrandLogoManifest.none.hasLogo, isFalse);
    });

    test('encode -> tryParse round-trips a logo', () {
      const m = BrandLogoManifest(sha: 'deadbeef', ext: '.jpg');
      final parsed = BrandLogoManifest.tryParse(m.encode());
      expect(parsed!.sha, 'deadbeef');
      expect(parsed.ext, '.jpg');
    });

    test('encode -> tryParse round-trips a cleared logo', () {
      final parsed = BrandLogoManifest.tryParse(BrandLogoManifest.none.encode());
      expect(parsed, isNotNull);
      expect(parsed!.hasLogo, isFalse);
    });

    test('tryParse rejects a newer version', () {
      expect(
        BrandLogoManifest.tryParse('{"version":99}'.codeUnits),
        isNull,
      );
    });

    test('tryParse rejects malformed JSON', () {
      expect(BrandLogoManifest.tryParse('nope'.codeUnits), isNull);
    });
  });
}
