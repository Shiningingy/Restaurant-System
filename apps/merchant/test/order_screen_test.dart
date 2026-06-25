import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/app.dart';
import 'package:merchant/core/providers.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/orders/presentation/order_screen.dart';
import 'package:merchant/l10n/app_localizations.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_until.dart';
import 'helpers/test_db.dart';

void main() {
  testWidgets('order screen shows Send to kitchen and Pay actions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'helpSeen': true});
    final prefs = await SharedPreferences.getInstance();
    final db = createTestDb();
    addTearDown(db.close);
    final orderId = await OrderRepository(
      db,
    ).createOrder(type: domain.OrderType.takeout, taxRateBp: 1300);

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OrderScreen(orderId: orderId),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Takeout order'), findsOneWidget);
    expect(find.text('Send to kitchen'), findsOneWidget);
    expect(find.textContaining('Pay'), findsOneWidget);

    // The action buttons must actually be laid out inside the viewport,
    // not just present in the tree.
    final sendRect = tester.getRect(find.text('Send to kitchen'));
    final payRect = tester.getRect(find.textContaining('Pay'));
    expect(sendRect.bottom, lessThanOrEqualTo(800));
    expect(payRect.bottom, lessThanOrEqualTo(800));
    expect(sendRect.top, greaterThan(0));

    // Drift stream-cleanup timer teardown (see app_test.dart).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('full app: tapping an order card reaches the action buttons', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'helpSeen': true});
    final prefs = await SharedPreferences.getInstance();
    final db = createTestDb();
    addTearDown(db.close);
    await OrderRepository(
      db,
    ).createOrder(type: domain.OrderType.takeout, taxRateBp: 1300);

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.5; // non-integer DPR coverage
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
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(r'$0.00')); // the order card's total
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Takeout order'), findsOneWidget);
    expect(find.text('Send to kitchen'), findsOneWidget);
    final sendRect = tester.getRect(find.text('Send to kitchen'));
    final viewHeight = 900 / 1.5;
    expect(
      sendRect.bottom,
      lessThanOrEqualTo(viewHeight),
      reason: 'Send button must be inside the viewport',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('payment sheet: partial cash, then the rest closes the order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'helpSeen': true});
    final prefs = await SharedPreferences.getInstance();
    final db = createTestDb();
    addTearDown(db.close);
    final orders = OrderRepository(db);
    final orderId = await orders.createOrder(
      type: domain.OrderType.takeout,
      taxRateBp: 1300,
    );
    // $10.00 burger at 13% tax -> total $11.30.
    await orders.addLine(
      orderId: orderId,
      item: const domain.MenuItem(
        id: 'm1',
        categoryId: 'c1',
        name: 'Burger',
        price: domain.Money(1000),
      ),
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
    // Open the order and start a payment.
    await pumpUntilFound(tester, find.text(r'$11.30'));
    await tester.tap(find.text(r'$11.30'));
    await pumpUntilFound(tester, find.text(r'Pay $11.30'));
    await tester.tap(find.text(r'Pay $11.30'));
    await pumpUntilFound(tester, find.text(r'Collect $11.30'));

    // Pay $5.00 of it in cash - the order must stay open.
    await tester.enterText(find.byType(TextField).first, '5.00');
    await tester.pump();
    await tester.tap(find.text('Cash'));
    await pumpUntilFound(tester, find.text('Balance due'));
    expect(find.text(r'Pay $6.30'), findsOneWidget);

    // Let the "partial payment" snackbar leave the Pay button's way:
    // fire its 4s timer, then pump its exit animation to completion.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsNothing);

    // Pay the remaining balance - the order closes and we return to
    // the orders board — where the paid order now sits in Pending until
    // finished.
    await tester.tap(find.text(r'Pay $6.30'));
    await pumpUntilFound(tester, find.text(r'Collect $6.30'));
    await tester.tap(find.text('Cash'));
    await pumpUntilFound(tester, find.text('Mark finished'));
    expect(find.text('Send to kitchen'), findsNothing);

    // Finishing it clears the board.
    await tester.tap(find.text('Mark finished'));
    await pumpUntilFound(
      tester,
      find.text('No open orders — start a dine-in or takeout order.'),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
