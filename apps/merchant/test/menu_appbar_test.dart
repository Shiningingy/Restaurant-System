import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_ui/restaurant_ui.dart';

/// The Menu screen's app bar lost its title + actions after a tonal Publish
/// button was added. This reproduces the toolbar under the real POS theme (whose
/// FilledButton min-height is the suspect) at the shop window size and asserts
/// the title and every action render without a layout exception.
void main() {
  Widget bar(Widget publish) => MaterialApp(
    theme: buildPosTheme(),
    home: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Menu'),
          actions: [
            publish,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Import from photo'),
              ),
            ),
            PopupMenuButton<String>(
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'sample', child: Text('Load sample')),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Items'),
              Tab(text: 'Groups'),
            ],
          ),
        ),
        body: const SizedBox(),
      ),
    ),
  );

  testWidgets('menu app bar renders title + actions under the POS theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      bar(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Publish'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Import from photo'), findsOneWidget);
  });
}
