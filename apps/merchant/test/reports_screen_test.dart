import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/app.dart';
import 'package:merchant/core/providers.dart';
import 'package:merchant/features/menu/data/menu_repository.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/payments/data/payment_repository.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_until.dart';
import 'helpers/test_db.dart';

void main() {
  testWidgets('reports tab shows the day summary, history and detail', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = createTestDb();
    addTearDown(db.close);

    // One burger order ($11.30 at 13%) paid cash with a $2 tip today.
    final menu = MenuRepository(db);
    final orders = OrderRepository(db);
    final cat = domain.Category(id: domain.newId(), name: 'Mains');
    await menu.upsertCategory(cat);
    final burger = domain.MenuItem(
      id: domain.newId(),
      categoryId: cat.id,
      name: 'Burger',
      price: const domain.Money(1000),
    );
    await menu.upsertItem(burger);
    final orderId = await orders.createOrder(
      type: domain.OrderType.takeout,
      taxRateBp: 1300,
    );
    await orders.addLine(orderId: orderId, item: burger);
    await PaymentRepository(db).recordApproved(
      orderId: orderId,
      method: domain.PaymentMethod.cash,
      amount: const domain.Money(1130),
      tip: const domain.Money(200),
    );

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MerchantApp(),
      ),
    );
    await pumpUntilFound(
      tester,
      find.text('No open orders — start a dine-in or takeout order.'),
    );

    await tester.tap(find.text('Reports'));
    await pumpUntilFound(tester, find.text('Gross sales'));

    expect(find.text(r'$11.30'), findsWidgets); // gross + history row
    expect(find.text('Cash'), findsOneWidget); // collected breakdown
    expect(find.text(r'$2.00'), findsOneWidget); // tips card
    expect(find.text('Burger'), findsOneWidget); // item sales

    // Open the order detail from history.
    await tester.tap(find.textContaining('Takeout #'));
    await pumpUntilFound(tester, find.text('1 x Burger'));
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Reprint receipt'), findsNothing); // no printer set up

    // Drift stream-cleanup timer teardown (see app_test.dart).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
