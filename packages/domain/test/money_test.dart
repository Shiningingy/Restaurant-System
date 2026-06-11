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
