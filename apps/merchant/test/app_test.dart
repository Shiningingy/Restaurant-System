import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/app.dart';

void main() {
  testWidgets(
    'app shell builds and shows formatted money from domain package',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MerchantApp()));
      expect(find.textContaining(r'$13.00'), findsOneWidget);
    },
  );
}
