import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/payments/data/payment_repository.dart';
import 'package:merchant/features/printing/application/print_service.dart';
import 'package:merchant/features/printing/data/print_job_repository.dart';
import 'package:merchant/core/settings/settings_repository.dart';
import 'package:merchant/core/settings/tables_repository.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_db.dart';

/// Records payloads and plays back a scripted sequence of results
/// (empty script = always succeed).
class FakeDriver implements domain.PrinterDriver {
  final List<List<int>> printed = [];
  final List<domain.Result<void, domain.PrintError>> script;

  FakeDriver([List<domain.Result<void, domain.PrintError>>? script])
    : script = script ?? [];

  @override
  domain.PrinterCapabilities get capabilities =>
      const domain.PrinterCapabilities(
        paperWidthChars: 48,
        supportsCut: true,
        transport: domain.PrinterTransport.network,
      );

  @override
  Future<domain.Result<void, domain.PrintError>> printJob(
    domain.PrintJobData job,
  ) async {
    final result = script.isEmpty
        ? const domain.Ok<void, domain.PrintError>(null)
        : script.removeAt(0);
    if (result.isOk) printed.add(job.payload);
    return result;
  }

  @override
  Future<bool> testConnection() async => true;
}

const burger = domain.MenuItem(
  id: 'm1',
  categoryId: 'c1',
  name: 'Burger',
  price: domain.Money(1000),
);

void main() {
  late AppDatabase db;
  late OrderRepository orders;
  late PaymentRepository payments;
  late PrintJobRepository jobs;
  late SettingsRepository settings;

  setUp(() async {
    db = createTestDb();
    orders = OrderRepository(db);
    payments = PaymentRepository(db);
    jobs = PrintJobRepository(db);
    SharedPreferences.setMockInitialValues({});
    settings = SettingsRepository(await SharedPreferences.getInstance());
  });

  tearDown(() => db.close());

  PrintService makeService(domain.PrinterDriver? Function() buildDriver) =>
      PrintService(
        jobs: jobs,
        orders: orders,
        payments: payments,
        tables: TablesRepository(db),
        settings: settings,
        buildDriver: buildDriver,
        backoff: (_) async {}, // no delays in tests
      );

  Future<String> openOrderWithBurger() async {
    final orderId = await orders.createOrder(
      type: domain.OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.addLine(orderId: orderId, item: burger);
    return orderId;
  }

  Future<List<PrintJobRow>> allJobs() => db.select(db.printJobs).get();

  test('kitchen ticket renders the order and the job completes', () async {
    final driver = FakeDriver();
    final service = makeService(() => driver);
    final orderId = await openOrderWithBurger();

    await service.printKitchenTicket(orderId);
    await service.idle;

    final rows = await allJobs();
    expect(rows, hasLength(1));
    expect(rows.single.status, domain.PrintJobStatus.done);
    expect(rows.single.kind, domain.PrintJobKind.kitchenTicket);
    expect(rows.single.orderId, orderId);
    final text = ascii.decode(
      driver.printed.single.where((b) => b >= 0x20 && b < 0x7F).toList(),
    );
    expect(text, contains('1 x Burger'));
    expect(text, contains('TAKEOUT'));
  });

  test('customer receipt includes totals and the recorded payment', () async {
    final driver = FakeDriver();
    final service = makeService(() => driver);
    final orderId = await openOrderWithBurger();
    await payments.recordApproved(
      orderId: orderId,
      method: domain.PaymentMethod.cash,
      amount: const domain.Money(1130),
    );

    await service.printCustomerReceipt(orderId);
    await service.idle;

    final text = ascii.decode(
      driver.printed.single.where((b) => b >= 0x20 && b < 0x7F).toList(),
    );
    expect(text, contains('My Restaurant'));
    expect(text, contains(r'$10.00'));
    expect(text, contains('Tax (13.00%)'));
    expect(text, contains(r'$11.30'));
    expect(text, contains('Cash'));
  });

  test('transient failures retry up to maxAttempts then succeed', () async {
    final driver = FakeDriver([
      const domain.Err(domain.PrintError('offline')),
      const domain.Err(domain.PrintError('offline')),
      const domain.Ok(null),
    ]);
    final service = makeService(() => driver);
    final orderId = await openOrderWithBurger();

    await service.printKitchenTicket(orderId);
    await service.idle;

    final job = (await allJobs()).single;
    expect(job.status, domain.PrintJobStatus.done);
    expect(job.attempts, 2);
  });

  test(
    'persistent failure parks the job as failed; manual retry revives it',
    () async {
      final dead = FakeDriver([
        const domain.Err(domain.PrintError('offline')),
        const domain.Err(domain.PrintError('offline')),
        const domain.Err(domain.PrintError('offline')),
      ]);
      domain.PrinterDriver current = dead;
      final service = makeService(() => current);
      final orderId = await openOrderWithBurger();

      await service.printKitchenTicket(orderId);
      await service.idle;

      var job = (await allJobs()).single;
      expect(job.status, domain.PrintJobStatus.failed);
      expect(job.lastError, 'offline');

      current = FakeDriver(); // printer came back
      await service.retryJob(job.id);
      await service.idle;

      job = (await allJobs()).single;
      expect(job.status, domain.PrintJobStatus.done);
    },
  );

  test('non-retryable errors fail immediately', () async {
    final driver = FakeDriver([
      const domain.Err(domain.PrintError('bad payload', isRetryable: false)),
    ]);
    final service = makeService(() => driver);
    final orderId = await openOrderWithBurger();

    await service.printKitchenTicket(orderId);
    await service.idle;

    final job = (await allJobs()).single;
    expect(job.status, domain.PrintJobStatus.failed);
    expect(job.attempts, 0);
  });

  test('no configured printer fails the job with a clear message', () async {
    final service = makeService(() => null);
    final orderId = await openOrderWithBurger();

    await service.printKitchenTicket(orderId);
    await service.idle;

    final job = (await allJobs()).single;
    expect(job.status, domain.PrintJobStatus.failed);
    expect(job.lastError, 'No printer configured');
  });

  test('start() re-queues jobs interrupted mid-print', () async {
    final driver = FakeDriver();
    final service = makeService(() => driver);
    final id = await jobs.enqueue(
      kind: domain.PrintJobKind.testPage,
      payload: [0x1B, 0x40],
    );
    await jobs.markPrinting(id); // simulate a crash mid-print

    await service.start();
    await service.idle;

    expect((await allJobs()).single.status, domain.PrintJobStatus.done);
    expect(driver.printed, hasLength(1));
  });

  test('printTestPage bypasses the queue and reports the result', () async {
    final service = makeService(() => null);
    final result = await service.printTestPage();
    expect(result.isErr, isTrue);

    final driver = FakeDriver();
    final working = makeService(() => driver);
    expect((await working.printTestPage()).isOk, isTrue);
    expect(driver.printed, hasLength(1));
    expect(await allJobs(), isEmpty);
  });
}
