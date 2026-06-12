import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/app.dart';
import 'package:merchant/core/providers.dart';
import 'package:merchant/features/orders/data/order_repository.dart';
import 'package:merchant/features/orders/presentation/order_screen.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_db.dart';

void main() {
  testWidgets('order screen shows Send to kitchen and Pay actions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
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
        child: MaterialApp(home: OrderScreen(orderId: orderId)),
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
    SharedPreferences.setMockInitialValues({});
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
}
