import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/core/settings/providers.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

void main() {
  group('CompPolicy.allowsWithoutApproval', () {
    test('an allowed item is always free, regardless of amount', () {
      const policy = CompPolicy(allowedItemIds: {'miso'});
      expect(
        policy.allowsWithoutApproval(
          itemId: 'miso',
          orderCompTotalAfter: const domain.Money(99999),
        ),
        isTrue,
      );
    });

    test('a non-listed item is allowed only within the amount cap', () {
      const policy = CompPolicy(amountCap: domain.Money(1000));
      // $8.00 of comps so far + this comp lands at $8.00 total -> within cap.
      expect(
        policy.allowsWithoutApproval(
          itemId: 'steak',
          orderCompTotalAfter: const domain.Money(800),
        ),
        isTrue,
      );
      // $12.00 total -> over the $10 cap, needs a manager.
      expect(
        policy.allowsWithoutApproval(
          itemId: 'steak',
          orderCompTotalAfter: const domain.Money(1200),
        ),
        isFalse,
      );
    });

    test('a zero cap means only listed items are free without approval', () {
      const policy = CompPolicy(allowedItemIds: {'miso'});
      expect(
        policy.allowsWithoutApproval(
          itemId: 'steak',
          orderCompTotalAfter: const domain.Money(1),
        ),
        isFalse,
      );
    });

    test('the default policy approves nothing (manager comps only)', () {
      const policy = CompPolicy();
      expect(
        policy.allowsWithoutApproval(
          itemId: 'anything',
          orderCompTotalAfter: domain.Money.zero,
        ),
        isFalse,
      );
    });
  });
}
