import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../orders/data/order_repository.dart';
import '../../payments/data/payment_repository.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/settings/tables_repository.dart';
import '../data/print_job_repository.dart';

/// Renders tickets, queues them, and drains the queue against the
/// configured printer with automatic retries. Everything printable goes
/// through here — UI code never touches drivers directly.
class PrintService {
  static const maxAttempts = 3;

  final PrintJobRepository jobs;
  final OrderRepository orders;
  final PaymentRepository payments;
  final TablesRepository tables;
  final SettingsRepository settings;

  /// Built per attempt so settings changes apply without a restart;
  /// returns null while no printer is configured.
  final domain.PrinterDriver? Function() buildDriver;

  /// Delay before retry [attempt]; injectable so tests run instantly.
  final Future<void> Function(int attempt) backoff;

  Future<void>? _draining;

  PrintService({
    required this.jobs,
    required this.orders,
    required this.payments,
    required this.tables,
    required this.settings,
    required this.buildDriver,
    this.backoff = _defaultBackoff,
  });

  static Future<void> _defaultBackoff(int attempt) =>
      Future.delayed(Duration(seconds: 2 * attempt));

  /// Re-queues jobs interrupted by an app kill, then drains.
  Future<void> start() async {
    await jobs.recoverInterrupted();
    kick();
  }

  Future<void> printKitchenTicket(String orderId) async {
    final doc = await _buildDoc(orderId, kitchen: true);
    await _enqueue(domain.PrintJobKind.kitchenTicket, doc, orderId);
  }

  Future<void> printCustomerReceipt(String orderId) async {
    final doc = await _buildDoc(orderId, kitchen: false);
    await _enqueue(domain.PrintJobKind.customerReceipt, doc, orderId);
  }

  /// Bypasses the queue for immediate feedback in Settings.
  Future<domain.Result<void, domain.PrintError>> printTestPage() async {
    final driver = buildDriver();
    if (driver == null) {
      return const domain.Err(
        domain.PrintError('No printer configured', isRetryable: false),
      );
    }
    final config = settings.receiptConfig;
    final doc = domain.TicketDoc([
      domain.TicketText(config.businessName, style: domain.TicketStyle.title),
      const domain.TicketText(
        'Printer test page',
        style: domain.TicketStyle.centered,
      ),
      const domain.TicketDivider(),
      domain.TicketText(
        'Paper width: ${driver.capabilities.paperWidthChars} chars',
      ),
      const domain.TicketFeed(3),
      const domain.TicketCut(),
    ]);
    return driver.printJob(
      domain.PrintJobData(
        id: domain.newId(),
        kind: domain.PrintJobKind.testPage,
        payload: _encode(doc),
      ),
    );
  }

  /// Retries a failed job and restarts the drain loop.
  Future<void> retryJob(String jobId) async {
    await jobs.retry(jobId);
    kick();
  }

  /// Starts draining the queue if not already running. Safe to call any
  /// time (enqueue, retry, settings change, app start).
  void kick() {
    _draining ??= _drain().whenComplete(() => _draining = null);
  }

  /// Completes when the current drain pass finishes (used by tests).
  Future<void> get idle => _draining ?? Future.value();

  // --- Internals ---

  Future<domain.TicketDoc> _buildDoc(
    String orderId, {
    required bool kitchen,
  }) async {
    final order = await orders.getOrder(orderId);
    if (order == null) {
      throw StateError('Order $orderId not found');
    }
    final lines = await orders.getLines(orderId);
    final tableLabel = order.tableId == null
        ? null
        : await tables.labelFor(order.tableId!);
    final nameDisplay = settings.nameDisplay;
    if (kitchen) {
      return domain.buildKitchenTicket(
        order: order,
        lines: lines,
        tableLabel: tableLabel,
        printedAt: DateTime.now(),
        showSecondName: nameDisplay.kitchenTicket,
      );
    }
    return domain.buildCustomerReceipt(
      order: order,
      lines: lines,
      config: settings.receiptConfig,
      payments: await payments.paymentsForOrder(orderId),
      tableLabel: tableLabel,
      showSecondName: nameDisplay.receipt,
    );
  }

  List<int> _encode(domain.TicketDoc doc) =>
      domain.EscPos.encode(doc, widthChars: settings.printer.paperWidthChars);

  Future<void> _enqueue(
    domain.PrintJobKind kind,
    domain.TicketDoc doc,
    String orderId,
  ) async {
    await jobs.enqueue(kind: kind, payload: _encode(doc), orderId: orderId);
    kick();
  }

  Future<void> _drain() async {
    while (true) {
      final job = await jobs.nextQueued();
      if (job == null) return;
      final driver = buildDriver();
      if (driver == null) {
        await jobs.markFailed(job.id, 'No printer configured');
        continue;
      }
      await jobs.markPrinting(job.id);
      final result = await driver.printJob(
        domain.PrintJobData(
          id: job.id,
          kind: job.kind,
          payload: job.payload,
          orderId: job.orderId,
        ),
      );
      switch (result) {
        case domain.Ok():
          await jobs.markDone(job.id);
        case domain.Err(:final error):
          final attempt = job.attempts + 1;
          if (!error.isRetryable || attempt >= maxAttempts) {
            await jobs.markFailed(job.id, error.message);
          } else {
            await jobs.recordAttempt(job.id, error.message);
            await backoff(attempt);
          }
      }
    }
  }
}
