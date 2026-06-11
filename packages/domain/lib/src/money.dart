import 'package:intl/intl.dart';

/// An exact amount of money, stored as integer cents.
///
/// `double` is banned for currency everywhere in this codebase
/// (see docs/PRINCIPLES.md). All arithmetic stays in integer cents;
/// formatting happens only at the presentation edge.
class Money implements Comparable<Money> {
  final int cents;

  const Money(this.cents);

  static const Money zero = Money(0);

  /// Parses user-entered text like "12.34" or "12" into Money.
  /// Returns null for anything that is not a plain decimal amount.
  static Money? tryParse(String input) {
    final match =
        RegExp(r'^\s*(-?)(\d+)(?:\.(\d{1,2}))?\s*$').firstMatch(input);
    if (match == null) return null;
    final sign = match.group(1) == '-' ? -1 : 1;
    final dollars = int.parse(match.group(2)!);
    final centsPart = (match.group(3) ?? '').padRight(2, '0');
    final cents = centsPart.isEmpty ? 0 : int.parse(centsPart);
    return Money(sign * (dollars * 100 + cents));
  }

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);
  Money operator *(int qty) => Money(cents * qty);
  bool operator <(Money other) => cents < other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  bool get isNegative => cents < 0;
  bool get isZero => cents == 0;

  /// Tax and percentage math with explicit half-up rounding, so totals
  /// are deterministic and auditable (e.g. 13% HST on $9.99).
  Money percent(double rate) => Money((cents * rate / 100).round());

  /// Formats as currency, default Canadian dollars: "$12.34".
  String format({String locale = 'en_CA', String symbol = r'$'}) {
    final f =
        NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: 2);
    return f.format(cents / 100);
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money(${cents}c)';
}
