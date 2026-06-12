import 'package:freezed_annotation/freezed_annotation.dart';

import '../src/money.dart';

part 'payment.freezed.dart';

enum PaymentMethod { cash, terminal, manual }

enum PaymentStatus { pending, approved, declined, reversed }

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String orderId,
    required PaymentMethod method,
    required Money amount,
    required PaymentStatus status,
    required DateTime createdAt,
    @Default(Money.zero) Money tip,

    /// Vendor-side reference (e.g. Moneris transaction id); null for
    /// cash/manual.
    String? terminalRef,
  }) = _Payment;
}
