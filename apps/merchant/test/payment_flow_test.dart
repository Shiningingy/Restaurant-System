import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/db/database.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/payments/application/payment_service.dart';
import 'package:merchant/features/payments/data/payment_repository.dart';
import 'package:merchant/features/payments/drivers/manual_entry_terminal.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

import 'helpers/test_db.dart';

/// Scripted terminal for exercising every charge outcome.
class FakeTerminal implements PaymentTerminal {
  final Result<PaymentResult, PaymentError> Function(Money amount) script;

  FakeTerminal(this.script);

  @override
  Future<Result<PaymentResult, PaymentError>> charge({
    required Money amount,
    required String orderId,
  }) async => script(amount);

  @override
  Future<Result<PaymentResult, PaymentError>> refund({
    required String paymentId,
    required Money amount,
  }) async => const Err(PaymentError('unused'));

  @override
  Future<TerminalStatus> status() async => TerminalStatus.ready;
}

void main() {
  late AppDatabase db;
  late OrderRepository orders;
  late PaymentRepository payments;

  setUp(() async {
    db = createTestDb();
    orders = OrderRepository(db);
    payments = PaymentRepository(db);
  });

  tearDown(() => db.close());

  /// Open order with one $10.00 burger at 13% tax → total $11.30.
  Future<String> openOrder() async {
    final orderId = await orders.createOrder(
      type: OrderType.takeout,
      taxRateBp: 1300,
    );
    await menuBurger(db, orders, orderId);
    return orderId;
  }

  PaymentService serviceWith(PaymentTerminal terminal) => PaymentService(
    payments: payments,
    buildTerminal: (_) => (terminal, PaymentMethod.terminal),
  );

  /// The real wiring: the prompt given to takeCard reaches the driver.
  PaymentService manualService() => PaymentService(
    payments: payments,
    buildTerminal: (p) =>
        (ManualEntryTerminal(prompt: p), PaymentMethod.manual),
  );

  Future<Order> order(String id) async => (await orders.getOrder(id))!;

  test('split bill: two partial cash payments close the order at zero '
      'balance (Phase 3 partial payments)', () async {
    final orderId = await openOrder();
    final service = serviceWith(FakeTerminal((_) => fail('not used')));

    final first = await service.takeCash(
      orderId: orderId,
      amount: const Money(500),
    );
    expect(first.status, PaymentFlowStatus.approved);
    expect(first.orderClosed, isFalse);
    expect((await order(orderId)).status, isNot(OrderStatus.paid));

    final second = await service.takeCash(
      orderId: orderId,
      amount: const Money(630),
      tip: const Money(100),
    );
    expect(second.orderClosed, isTrue);

    final closed = await order(orderId);
    expect(closed.status, OrderStatus.paid);
    expect(closed.paidAt, isNotNull);

    final recorded = await payments.paymentsForOrder(orderId);
    expect(recorded, hasLength(2));
    expect(recorded.last.tip, const Money(100));
    expect(balanceDue(total: closed.total, payments: recorded), Money.zero);
  });

  test('declined card is recorded for audit but never settles', () async {
    final orderId = await openOrder();
    final service = serviceWith(
      FakeTerminal(
        (amount) =>
            Ok(PaymentResult(status: ChargeOutcome.declined, amount: amount)),
      ),
    );

    final result = await service.takeCard(
      orderId: orderId,
      amount: const Money(1130),
      prompt: (_) async => fail('integrated terminal ignores the prompt'),
    );

    expect(result.status, PaymentFlowStatus.declined);
    expect((await order(orderId)).status, isNot(OrderStatus.paid));
    final recorded = await payments.paymentsForOrder(orderId);
    expect(recorded.single.status, PaymentStatus.declined);
    expect(
      balanceDue(total: (await order(orderId)).total, payments: recorded),
      const Money(1130),
    );
  });

  test('approved card with tip from the terminal closes the order', () async {
    final orderId = await openOrder();
    final service = serviceWith(
      FakeTerminal(
        (amount) => Ok(
          PaymentResult(
            status: ChargeOutcome.approved,
            amount: amount,
            tip: const Money(170),
            terminalRef: 'TX-123',
          ),
        ),
      ),
    );

    final result = await service.takeCard(
      orderId: orderId,
      amount: const Money(1130),
      prompt: (_) async => fail('unused'),
    );

    expect(result.status, PaymentFlowStatus.approved);
    expect(result.orderClosed, isTrue);
    final recorded = await payments.paymentsForOrder(orderId);
    expect(recorded.single.tip, const Money(170));
    expect(recorded.single.terminalRef, 'TX-123');
    expect(recorded.single.method, PaymentMethod.terminal);
  });

  test('terminal error surfaces as failed and records nothing', () async {
    final orderId = await openOrder();
    final service = serviceWith(
      FakeTerminal((_) => const Err(PaymentError('terminal offline'))),
    );

    final result = await service.takeCard(
      orderId: orderId,
      amount: const Money(1130),
      prompt: (_) async => fail('unused'),
    );

    expect(result.status, PaymentFlowStatus.failed);
    expect(result.message, 'terminal offline');
    expect(await payments.paymentsForOrder(orderId), isEmpty);
  });

  test(
    'manual entry: staff-confirmed outcome flows through the port',
    () async {
      final orderId = await openOrder();
      Money? promptedAmount;
      final service = manualService();

      final result = await service.takeCard(
        orderId: orderId,
        amount: const Money(1130),
        prompt: (amount) async {
          promptedAmount = amount;
          return PaymentResult(
            status: ChargeOutcome.approved,
            amount: amount,
            tip: const Money(200),
          );
        },
      );

      expect(promptedAmount, const Money(1130));
      expect(result.status, PaymentFlowStatus.approved);
      expect(result.orderClosed, isTrue);
      final recorded = await payments.paymentsForOrder(orderId);
      expect(recorded.single.method, PaymentMethod.manual);
      expect(recorded.single.tip, const Money(200));
    },
  );

  test('manual entry: cancelling the prompt records nothing', () async {
    final orderId = await openOrder();
    final service = manualService();

    final result = await service.takeCard(
      orderId: orderId,
      amount: const Money(1130),
      prompt: (_) async => null,
    );

    expect(result.status, PaymentFlowStatus.cancelled);
    expect(await payments.paymentsForOrder(orderId), isEmpty);
    expect((await order(orderId)).status, isNot(OrderStatus.paid));
  });

  test('overpayment beyond the total still closes (banked as paid)', () async {
    final orderId = await openOrder();
    final service = serviceWith(FakeTerminal((_) => fail('not used')));

    final result = await service.takeCash(
      orderId: orderId,
      amount: const Money(2000),
    );
    expect(result.orderClosed, isTrue);
    expect((await order(orderId)).status, OrderStatus.paid);
  });
}

/// Adds a $10.00 burger line via a minimal menu fixture.
Future<void> menuBurger(
  AppDatabase db,
  OrderRepository orders,
  String orderId,
) async {
  final menu = MenuRepository(db);
  final cat = Category(id: newId(), name: 'Mains');
  await menu.upsertCategory(cat);
  final burger = MenuItem(
    id: newId(),
    categoryId: cat.id,
    name: 'Burger',
    price: const Money(1000),
  );
  await menu.upsertItem(burger);
  await orders.addLine(orderId: orderId, item: burger);
}
