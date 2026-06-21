import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../data/payment_repository.dart';
import '../drivers/manual_entry_terminal.dart';

/// What the UI needs to know after a payment attempt.
enum PaymentFlowStatus { approved, declined, cancelled, failed }

class PaymentFlowResult {
  final PaymentFlowStatus status;

  /// True when this payment settled the remaining balance and the order
  /// is now closed.
  final bool orderClosed;

  /// Failure detail for [PaymentFlowStatus.failed].
  final String? message;

  const PaymentFlowResult(
    this.status, {
    this.orderClosed = false,
    this.message,
  });
}

/// Takes payments toward an order — cash directly, card via the
/// configured [domain.PaymentTerminal] — records every outcome, and
/// closes the order once the balance reaches zero. UI code never talks
/// to terminal drivers directly.
class PaymentService {
  final PaymentRepository payments;

  /// Built per charge so settings changes apply without a restart.
  /// The prompt is forwarded to [ManualEntryTerminal]; a semi-integrated
  /// terminal (Moneris Go, pending API access) ignores it.
  final (domain.PaymentTerminal, domain.PaymentMethod) Function(
    ManualChargePrompt prompt,
  )
  buildTerminal;

  PaymentService({required this.payments, required this.buildTerminal});

  Future<PaymentFlowResult> takeCash({
    required String orderId,
    required domain.Money amount,
    domain.Money tip = domain.Money.zero,
    List<String> settleLineIds = const [],
  }) async {
    final closed = await payments.recordApproved(
      orderId: orderId,
      method: domain.PaymentMethod.cash,
      amount: amount,
      tip: tip,
      settleLineIds: settleLineIds,
    );
    return PaymentFlowResult(PaymentFlowStatus.approved, orderClosed: closed);
  }

  Future<PaymentFlowResult> takeCard({
    required String orderId,
    required domain.Money amount,
    required ManualChargePrompt prompt,
    List<String> settleLineIds = const [],
  }) async {
    final (terminal, method) = buildTerminal(prompt);
    final result = await terminal.charge(amount: amount, orderId: orderId);
    switch (result) {
      case domain.Err(:final error):
        return PaymentFlowResult(
          PaymentFlowStatus.failed,
          message: error.message,
        );
      case domain.Ok(:final value):
        switch (value.status) {
          case domain.ChargeOutcome.cancelled:
            return const PaymentFlowResult(PaymentFlowStatus.cancelled);
          case domain.ChargeOutcome.declined:
            await payments.recordDeclined(
              orderId: orderId,
              method: method,
              amount: value.amount,
              terminalRef: value.terminalRef,
            );
            return const PaymentFlowResult(PaymentFlowStatus.declined);
          case domain.ChargeOutcome.approved:
            final closed = await payments.recordApproved(
              orderId: orderId,
              method: method,
              amount: value.amount,
              tip: value.tip,
              terminalRef: value.terminalRef,
              settleLineIds: settleLineIds,
            );
            return PaymentFlowResult(
              PaymentFlowStatus.approved,
              orderClosed: closed,
            );
        }
    }
  }
}
