import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/app.dart';
import 'package:merchant/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_db.dart';

void main() {
  testWidgets('app shell boots to the empty orders screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = createTestDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MerchantApp(),
      ),
    );
    // Let the order/table streams emit their first (empty) values.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Open Orders'), findsOneWidget);
    expect(find.textContaining('No open orders'), findsOneWidget);

    // Tear the tree down ourselves so drift's stream-cleanup timer fires
    // before the framework checks for pending timers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
