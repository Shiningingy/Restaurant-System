import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../../../core/sync/providers.dart';
import '../data/payment_repository.dart';
import '../drivers/manual_entry_terminal.dart';
import 'payment_service.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(
    ref.watch(databaseProvider),
    journal: ref.watch(syncJournalProvider),
  ),
);

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(
    payments: ref.watch(paymentRepositoryProvider),
    // Manual entry is the only terminal mode until the Moneris Go
    // Cloud API spec is available (see docs/ROADMAP.md Phase 3).
    buildTerminal: (prompt) =>
        (ManualEntryTerminal(prompt: prompt), domain.PaymentMethod.manual),
  );
});

/// All payment attempts on an order, oldest first.
final orderPaymentsProvider =
    StreamProvider.family<List<domain.Payment>, String>(
      (ref, orderId) =>
          ref.watch(paymentRepositoryProvider).watchPayments(orderId),
    );
