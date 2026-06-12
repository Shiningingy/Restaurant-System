import '../src/money.dart';
import '../src/result.dart';

/// Outcome of a single charge/refund attempt at the terminal.
/// (Distinct from the persisted [PaymentStatus] on the Payment entity.)
enum ChargeOutcome { approved, declined, cancelled }

class PaymentResult {
  final ChargeOutcome status;
  final Money amount;
  final Money tip;

  /// Vendor-side reference (e.g. Moneris transaction id) for refunds
  /// and reconciliation. Null for manual entry.
  final String? terminalRef;

  const PaymentResult({
    required this.status,
    required this.amount,
    this.tip = Money.zero,
    this.terminalRef,
  });
}

class PaymentError {
  final String message;
  final bool isRetryable;

  const PaymentError(this.message, {this.isRetryable = true});

  @override
  String toString() => 'PaymentError($message, retryable: $isRetryable)';
}

enum TerminalStatus { ready, busy, offline, notConfigured }

/// Vendor-agnostic abstraction over card payment terminals.
///
/// The point of sale pushes the amount to the terminal so staff never
/// re-key the price. Implementations live under
/// `apps/merchant/lib/features/payments/drivers/` — the ONLY place
/// vendor SDKs/APIs may be imported.
///
/// Planned implementations:
///  - ManualEntryTerminal (staff keys the amount on a standalone terminal
///    and records the outcome — zero vendor dependency, always available)
///  - MonerisGoTerminal   (Moneris Go semi-integrated cloud API)
///
/// Raw card data NEVER passes through this interface or any code in this
/// repository (see docs/PRINCIPLES.md).
abstract interface class PaymentTerminal {
  Future<Result<PaymentResult, PaymentError>> charge({
    required Money amount,
    required String orderId,
  });

  Future<Result<PaymentResult, PaymentError>> refund({
    required String paymentId,
    required Money amount,
  });

  Future<TerminalStatus> status();
}
