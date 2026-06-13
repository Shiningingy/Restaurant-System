import 'package:flutter_test/flutter_test.dart';

/// Pumps (letting real async DB work complete) until [finder] matches,
/// failing after ~2.5s, then finishes route/dialog animations so the
/// target is tappable at its final position. Drift queries run on real
/// async, so fixed pump durations race against them.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50; i++) {
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  expect(finder, findsWidgets);
}
