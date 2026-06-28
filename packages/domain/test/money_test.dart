import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('arithmetic stays in integer cents', () {
      expect(const Money(1050) + const Money(295), const Money(1345));
      expect(const Money(1050) - const Money(295), const Money(755));
      expect(const Money(350) * 3, const Money(1050));
    });

    test('percent rounds half-up deterministically', () {
      // 13% HST on $9.99 = 129.87c -> 130c
      expect(const Money(999).percent(13), const Money(130));
      // 13% on $10.00 = 130c exactly
      expect(const Money(1000).percent(13), const Money(130));
    });

    test('formats as Canadian currency', () {
      expect(const Money(1234).format(), r'$12.34');
      expect(const Money(5).format(), r'$0.05');
      expect(Money.zero.format(), r'$0.00');
    });

    test('tryParse accepts plain decimal amounts only', () {
      expect(Money.tryParse('12.34'), const Money(1234));
      expect(Money.tryParse('12.3'), const Money(1230));
      expect(Money.tryParse('12'), const Money(1200));
      expect(Money.tryParse('-5.00'), const Money(-500));
      expect(Money.tryParse('12.345'), isNull);
      expect(Money.tryParse('abc'), isNull);
      expect(Money.tryParse(''), isNull);
    });

    test('comparison operators', () {
      expect(const Money(100) < const Money(200), isTrue);
      expect(const Money(200) >= const Money(200), isTrue);
      expect(const Money(-1).isNegative, isTrue);
    });

    test('cash rounding to a 25-cent increment', () {
      // $14.01 -> down 14.00, up 14.25, nearest 14.00.
      expect(const Money(1401).roundedDownTo(25), const Money(1400));
      expect(const Money(1401).roundedUpTo(25), const Money(1425));
      expect(const Money(1401).roundedToNearest(25), const Money(1400));
      // $14.13 is past the midpoint -> nearest rounds up to 14.25.
      expect(const Money(1413).roundedToNearest(25), const Money(1425));
      // Already on the increment -> unchanged in every direction.
      expect(const Money(1425).roundedDownTo(25), const Money(1425));
      expect(const Money(1425).roundedUpTo(25), const Money(1425));
    });

    test('cash rounding to 5 and 10 cents', () {
      expect(const Money(1399).roundedDownTo(5), const Money(1395));
      expect(const Money(1399).roundedUpTo(5), const Money(1400));
      expect(const Money(1394).roundedToNearest(10), const Money(1390));
      expect(
          const Money(1395).roundedToNearest(10), const Money(1400)); // tie up
    });

    test('an increment of 0 or 1 leaves the amount unchanged', () {
      expect(const Money(1401).roundedDownTo(0), const Money(1401));
      expect(const Money(1401).roundedUpTo(1), const Money(1401));
      expect(const Money(1401).roundedToNearest(0), const Money(1401));
    });
  });

  group('Result', () {
    test('when dispatches to the right branch', () {
      const Result<int, String> ok = Ok(42);
      const Result<int, String> err = Err('boom');
      expect(ok.when(ok: (v) => v, err: (_) => -1), 42);
      expect(err.when(ok: (v) => v, err: (_) => -1), -1);
      expect(ok.valueOrNull, 42);
      expect(err.errorOrNull, 'boom');
    });
  });

  group('ids', () {
    test('newId generates unique UUIDs', () {
      final a = newId();
      final b = newId();
      expect(a, isNot(b));
      expect(a, matches(RegExp(r'^[0-9a-f-]{36}$')));
    });
  });
}
