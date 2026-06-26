import 'package:customer/features/storefront/presentation/item_sheet.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

/// Reproduces the "Add button missing" report: open the item dialog under the
/// real POS theme (whose FilledButton min-size + pill shape is what made the
/// original Spacer layout fragile) and assert the Add button is laid out, fully
/// on-screen, and nothing overflows.
void main() {
  Widget host(domain.PublishedItem item, {String? imageUrl}) => MaterialApp(
    theme: buildPosTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showItemSheet(context, item, imageUrl: imageUrl),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  testWidgets('item dialog shows the Add button (no photo, no options)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    const item = domain.PublishedItem(
      id: 'i1',
      name: 'Tossed Rice Noodle',
      price: domain.Money(1199),
    );
    await tester.pumpWidget(host(item));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The Add button shows the formatted line total.
    expect(find.textContaining('Add'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    // It must be fully on-screen (the bug was it being clipped off the right).
    final rect = tester.getRect(find.byType(FilledButton));
    expect(rect.width, greaterThan(0));
    expect(rect.right, lessThanOrEqualTo(1280));
    expect(rect.left, greaterThanOrEqualTo(0));
    // Tapping it returns a cart line (pops the dialog).
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('item dialog shows the Add button (with a photo + options)', (
    tester,
  ) async {
    const item = domain.PublishedItem(
      id: 'i2',
      name: 'Salmon poke',
      price: domain.Money(1399),
      modifierGroups: [
        domain.PublishedModifierGroup(
          id: 'g1',
          name: 'Size',
          minSelect: 1,
          maxSelect: 1,
          modifiers: [
            domain.PublishedModifier(
              id: 'm1',
              name: 'Regular',
              priceDelta: domain.Money(0),
            ),
            domain.PublishedModifier(
              id: 'm2',
              name: 'Large',
              priceDelta: domain.Money(200),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(host(item, imageUrl: 'https://example.com/x.jpg'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.textContaining('Add'), findsOneWidget);
  });
}
