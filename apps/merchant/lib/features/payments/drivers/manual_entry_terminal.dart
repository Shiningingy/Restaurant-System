import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Asks the staff member what happened at the standalone terminal.
/// Returns null when they cancel without charging.
typedef ManualChargePrompt =
    Future<domain.PaymentResult?> Function(domain.Money amount);

/// The zero-vendor-dependency [domain.PaymentTerminal]: staff key the
/// amount on a standalone card terminal, read the outcome (and any tip)
/// off its screen, and record it in the app. The "vendor SDK" is the
/// human — this driver just delegates to a prompt the presentation
/// layer injects.
class ManualEntryTerminal implements domain.PaymentTerminal {
  final ManualChargePrompt prompt;

  ManualEntryTerminal({required this.prompt});

  @override
  Future<domain.Result<domain.PaymentResult, domain.PaymentError>> charge({
    required domain.Money amount,
    required String orderId,
  }) async {
    final result = await prompt(amount);
    if (result == null) {
      return domain.Ok(
        domain.PaymentResult(
          status: domain.ChargeOutcome.cancelled,
          amount: amount,
        ),
      );
    }
    return domain.Ok(result);
  }

  @override
  Future<domain.Result<domain.PaymentResult, domain.PaymentError>> refund({
    required String paymentId,
    required domain.Money amount,
  }) async {
    // Manual-mode refunds happen on the standalone terminal itself;
    // in-app refund recording arrives with order history (Phase 4).
    return const domain.Err(
      domain.PaymentError(
        'Refund directly on the terminal.',
        isRetryable: false,
      ),
    );
  }

  @override
  Future<domain.TerminalStatus> status() async => domain.TerminalStatus.ready;
}
