import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

void main() {
  final order = Order(
    id: 'abcd1234-0000-0000-0000-000000000000',
    type: OrderType.dineIn,
    status: OrderStatus.paid,
    createdAt: DateTime(2026, 6, 12, 12, 30),
    closedAt: DateTime(2026, 6, 12, 13, 5),
    taxRateBp: 1300,
    subtotal: const Money(1900),
    tax: const Money(247),
    total: const Money(2147),
  );

  final lines = [
    const OrderLine(
      id: 'l1',
      orderId: 'o1',
      menuItemId: 'm1',
      nameSnapshot: 'Burger',
      priceSnapshot: Money(1000),
      qty: 1,
      lineTotal: Money(1200),
      modifiers: [
        OrderLineModifier(
          id: 'lm1',
          lineId: 'l1',
          nameSnapshot: 'Large',
          priceDeltaSnapshot: Money(200),
        ),
      ],
    ),
    const OrderLine(
      id: 'l2',
      orderId: 'o1',
      menuItemId: 'm2',
      nameSnapshot: 'Fries',
      priceSnapshot: Money(350),
      qty: 2,
      lineTotal: Money(700),
      note: 'extra crispy',
    ),
    const OrderLine(
      id: 'l3',
      orderId: 'o1',
      menuItemId: 'm3',
      nameSnapshot: 'Voided Pop',
      priceSnapshot: Money(250),
      qty: 1,
      lineTotal: Money(250),
      status: OrderLineStatus.voided,
    ),
  ];

  String render(TicketDoc doc) => EscPos.renderPlainText(doc, widthChars: 48);

  test('orderRef is short and stable', () {
    expect(orderRef(order.id), '#ABCD');
  });

  group('kitchen ticket', () {
    test('shows table, qty, modifiers and notes — never prices', () {
      final text = render(
        buildKitchenTicket(order: order, lines: lines, tableLabel: '5'),
      );
      expect(text, contains('DINE-IN  TABLE 5'));
      expect(text, contains('#ABCD'));
      expect(text, contains('1 x Burger'));
      expect(text, contains('+ Large'));
      expect(text, contains('2 x Fries'));
      expect(text, contains('* extra crispy'));
      expect(text, isNot(contains(r'$')));
    });

    test('skips voided lines', () {
      final text = render(buildKitchenTicket(order: order, lines: lines));
      expect(text, isNot(contains('Voided Pop')));
    });

    test('shows item code and a stacked second name line', () {
      const bilingual = OrderLine(
        id: 'lb',
        orderId: 'o1',
        menuItemId: 'mb',
        nameSnapshot: 'Beef Noodle',
        priceSnapshot: Money(1500),
        qty: 2,
        lineTotal: Money(3000),
        codeSnapshot: 'A01',
        nameSecondarySnapshot: '牛肉面',
      );
      final text = render(buildKitchenTicket(order: order, lines: [bilingual]));
      expect(text, contains('2 x A01  Beef Noodle'));
      expect(text, contains('牛肉面'));
    });

    test('hides the second name when showSecondName is false', () {
      const bilingual = OrderLine(
        id: 'lb',
        orderId: 'o1',
        menuItemId: 'mb',
        nameSnapshot: 'Beef Noodle',
        priceSnapshot: Money(1500),
        qty: 2,
        lineTotal: Money(3000),
        codeSnapshot: 'A01',
        nameSecondarySnapshot: '牛肉面',
      );
      final text = render(
        buildKitchenTicket(
          order: order,
          lines: [bilingual],
          showSecondName: false,
        ),
      );
      expect(text, contains('2 x A01  Beef Noodle'));
      expect(text, isNot(contains('牛肉面')));
    });
  });

  group('customer receipt', () {
    const config = ReceiptConfig(
      businessName: 'Test Diner',
      headerLines: ['123 Main St', '555-0123'],
      footer: 'Thank you!',
    );

    test('prefixes the item code but omits the second name line', () {
      const bilingual = OrderLine(
        id: 'lb',
        orderId: 'o1',
        menuItemId: 'mb',
        nameSnapshot: 'Beef Noodle',
        priceSnapshot: Money(1500),
        qty: 1,
        lineTotal: Money(1500),
        codeSnapshot: 'A01',
        nameSecondarySnapshot: '牛肉面',
      );
      final text = render(
        buildCustomerReceipt(order: order, lines: [bilingual], config: config),
      );
      expect(text, contains('A01  Beef Noodle'));
      expect(text, isNot(contains('牛肉面')));
    });

    test('shows the second name line when showSecondName is true', () {
      const bilingual = OrderLine(
        id: 'lb',
        orderId: 'o1',
        menuItemId: 'mb',
        nameSnapshot: 'Beef Noodle',
        priceSnapshot: Money(1500),
        qty: 1,
        lineTotal: Money(1500),
        codeSnapshot: 'A01',
        nameSecondarySnapshot: '牛肉面',
      );
      final text = render(
        buildCustomerReceipt(
          order: order,
          lines: [bilingual],
          config: config,
          showSecondName: true,
        ),
      );
      expect(text, contains('A01  Beef Noodle'));
      expect(text, contains('牛肉面'));
    });

    test('shows identity, lines with prices, totals, payment and footer', () {
      final text = render(
        buildCustomerReceipt(
          order: order,
          lines: lines,
          config: config,
          tableLabel: '5',
          payments: [
            Payment(
              id: 'p1',
              orderId: 'o1',
              method: PaymentMethod.cash,
              amount: const Money(2147),
              tip: const Money(300),
              status: PaymentStatus.approved,
              createdAt: DateTime(2026, 6, 12, 13, 5),
            ),
          ],
        ),
      );
      expect(text, contains('Test Diner'));
      expect(text, contains('123 Main St'));
      expect(text, contains('DINE-IN  TABLE 5'));
      expect(text, contains('2026-06-12 13:05'));
      expect(text, contains('1 x Burger'));
      expect(text, contains(r'$12.00'));
      expect(text, contains('Large'));
      expect(text, contains(r'+$2.00'));
      expect(text, contains('Subtotal'));
      expect(text, contains('Tax (13.00%)'));
      expect(text, contains(r'$2.47'));
      expect(text, contains('TOTAL'));
      expect(text, contains(r'$21.47'));
      expect(text, contains('Cash'));
      expect(text, contains('Tip'));
      expect(text, contains(r'$3.00'));
      expect(text, contains('Thank you!'));
      expect(text, isNot(contains('Voided Pop')));
    });

    test('omits zero modifier deltas and absent payment', () {
      final noDelta = [
        const OrderLine(
          id: 'l1',
          orderId: 'o1',
          menuItemId: 'm1',
          nameSnapshot: 'Burger',
          priceSnapshot: Money(1000),
          qty: 1,
          lineTotal: Money(1000),
          modifiers: [
            OrderLineModifier(
              id: 'lm1',
              lineId: 'l1',
              nameSnapshot: 'No onions',
              priceDeltaSnapshot: Money.zero,
            ),
          ],
        ),
      ];
      final text = render(
        buildCustomerReceipt(order: order, lines: noDelta, config: config),
      );
      expect(text, contains('No onions'));
      expect(text, isNot(contains(r'+$0.00')));
      expect(text, isNot(contains('Cash')));
    });

    test('split payments list each approved payment; declines excluded', () {
      final text = render(
        buildCustomerReceipt(
          order: order, // total $21.47
          lines: lines,
          config: config,
          payments: [
            Payment(
              id: 'p1',
              orderId: 'o1',
              method: PaymentMethod.manual,
              amount: const Money(2147),
              status: PaymentStatus.declined,
              createdAt: DateTime(2026, 6, 12, 13, 0),
            ),
            Payment(
              id: 'p2',
              orderId: 'o1',
              method: PaymentMethod.cash,
              amount: const Money(1000),
              status: PaymentStatus.approved,
              createdAt: DateTime(2026, 6, 12, 13, 1),
            ),
            Payment(
              id: 'p3',
              orderId: 'o1',
              method: PaymentMethod.manual,
              amount: const Money(1147),
              tip: const Money(200),
              status: PaymentStatus.approved,
              createdAt: DateTime(2026, 6, 12, 13, 2),
            ),
          ],
        ),
      );
      expect(text, contains('Cash'));
      expect(text, contains(r'$10.00'));
      expect(text, contains('Card (keyed)'));
      expect(text, contains(r'$11.47'));
      expect(text, contains('Tip'));
      expect(text, contains(r'$2.00'));
      // Fully settled: no balance line, and only one card row (the
      // declined attempt is audit data, not receipt data).
      expect(text, isNot(contains('BALANCE DUE')));
      expect('Card (keyed)'.allMatches(text), hasLength(1));
    });

    test('partial payment prints the remaining balance', () {
      final text = render(
        buildCustomerReceipt(
          order: order, // total $21.47
          lines: lines,
          config: config,
          payments: [
            Payment(
              id: 'p1',
              orderId: 'o1',
              method: PaymentMethod.cash,
              amount: const Money(1000),
              status: PaymentStatus.approved,
              createdAt: DateTime(2026, 6, 12, 13, 0),
            ),
          ],
        ),
      );
      expect(text, contains('BALANCE DUE'));
      expect(text, contains(r'$11.47'));
    });
  });
}
