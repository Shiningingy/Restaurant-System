import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/app.dart';
import 'package:merchant/core/providers.dart';
import 'package:merchant/features/admin/application/providers.dart';
import 'package:merchant/features/admin/data/staff_repository.dart';
import 'package:merchant/features/admin/domain/staff.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_db.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('empty roster → bootstrap full access (all tabs visible)', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final db = createTestDb();
    addTearDown(db.close);
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
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'server sees only open tabs; signing in an owner reveals the rest',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final db = createTestDb();
      addTearDown(db.close);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // A non-empty roster turns gating on; with no one signed in the baseline
      // is server.
      final id = domain.newId();
      final owner = Staff(
        id: id,
        name: 'Ann',
        role: StaffRole.owner,
        pinHash: StaffRepository.hashPin(id, '1111'),
      );
      await StaffRepository(db).upsert(owner);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MerchantApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Server baseline: restricted tabs hidden, open tabs present.
      expect(find.text('Menu'), findsNothing);
      expect(find.text('Reports'), findsNothing);
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Sign the owner in → restricted tabs appear.
      container.read(sessionProvider.notifier).setActive(owner);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
