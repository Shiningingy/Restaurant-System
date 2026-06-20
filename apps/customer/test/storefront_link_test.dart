import 'package:customer/features/storefront/data/storefront_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorefrontLink', () {
    test('round-trips url, key and name', () {
      const link = StorefrontLink(
        url: 'https://abc.supabase.co',
        anonKey: 'anon-123',
        name: 'Noodle House',
      );
      final parsed = StorefrontLink.tryParse(link.encode());
      expect(parsed, isNotNull);
      expect(parsed!.url, 'https://abc.supabase.co');
      expect(parsed.anonKey, 'anon-123');
      expect(parsed.name, 'Noodle House');
    });

    test('omits an empty name from the payload and parses it back as null', () {
      const link = StorefrontLink(
        url: 'https://abc.supabase.co',
        anonKey: 'anon-123',
      );
      expect(link.encode(), isNot(contains('name')));
      expect(StorefrontLink.tryParse(link.encode())!.name, isNull);
    });

    test('tolerates surrounding whitespace', () {
      const link = StorefrontLink(url: 'https://x.co', anonKey: 'k');
      expect(StorefrontLink.tryParse('  ${link.encode()}\n'), isNotNull);
    });

    test('rejects non-JSON text', () {
      expect(StorefrontLink.tryParse('not a qr'), isNull);
      expect(StorefrontLink.tryParse('https://x.co'), isNull);
    });

    test('rejects a JSON object missing url or key', () {
      expect(StorefrontLink.tryParse('{"v":1,"url":"https://x.co"}'), isNull);
      expect(StorefrontLink.tryParse('{"v":1,"key":"k"}'), isNull);
      expect(StorefrontLink.tryParse('{"v":1,"url":"","key":"k"}'), isNull);
    });

    test('rejects an unknown version', () {
      expect(
        StorefrontLink.tryParse('{"v":2,"url":"https://x.co","key":"k"}'),
        isNull,
      );
    });
  });
}
