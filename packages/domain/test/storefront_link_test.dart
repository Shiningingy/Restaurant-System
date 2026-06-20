import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

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

    test('omits an empty name and parses it back as null', () {
      const link = StorefrontLink(
        url: 'https://abc.supabase.co',
        anonKey: 'anon-123',
      );
      expect(link.encode(), isNot(contains('name')));
      expect(StorefrontLink.tryParse(link.encode())!.name, isNull);
    });

    test('rejects non-JSON, missing fields and unknown versions', () {
      expect(StorefrontLink.tryParse('not a qr'), isNull);
      expect(StorefrontLink.tryParse('{"v":1,"url":"https://x.co"}'), isNull);
      expect(StorefrontLink.tryParse('{"v":1,"key":"k"}'), isNull);
      expect(
        StorefrontLink.tryParse('{"v":2,"url":"https://x.co","key":"k"}'),
        isNull,
      );
    });
  });
}
