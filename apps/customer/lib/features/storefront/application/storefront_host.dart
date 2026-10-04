import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_extension_api/restaurant_extension_api.dart';
import 'package:restaurant_extensions/restaurant_extensions.dart';

import '../../orders/application/providers.dart';
import '../../orders/data/order_history.dart';
import '../presentation/status_screen.dart';
import 'providers.dart';

/// The extensions installed in this build (none in the open-source build; see
/// packages/extension_api).
final customerExtensionsProvider = Provider<List<CustomerExtension>>(
  (ref) => customerExtensions(),
);

/// How extensions act on the connected restaurant.
final storefrontHostProvider = Provider<StorefrontHost>(
  CustomerStorefrontHost.new,
);

/// The customer app's [StorefrontHost]. Placing an order follows checkout's
/// pay-at-pickup path: submit, then record it in this device's history.
class CustomerStorefrontHost implements StorefrontHost {
  CustomerStorefrontHost(this._ref);

  final Ref _ref;

  @override
  Future<domain.PublishedMenu?> loadMenu() => _ref.read(menuProvider.future);

  @override
  Future<String> placePreorder(domain.PreorderSubmission order) async {
    final storefront = _ref.read(storefrontProvider);
    if (storefront == null) {
      throw StateError('Not connected to a restaurant.');
    }
    final orderId = await storefront.submitPreorder(
      order,
      customerUid: _ref.read(storefrontConfigProvider).customerUid,
    );
    final active = _ref.read(walletProvider).active;
    if (active != null) {
      await _ref
          .read(orderHistoryProvider.notifier)
          .add(
            PlacedOrder(
              orderId: orderId,
              storefrontId: active.id,
              restaurantLabel: active.label,
              totalCents: order.total.cents,
              placedAt: DateTime.now(),
              status: domain.OnlineOrderStatus.submitted,
            ),
          );
    }
    return orderId;
  }

  @override
  void openOrderStatus(
    BuildContext context,
    String orderId,
    domain.Money total,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatusScreen(orderId: orderId, total: total),
      ),
    );
  }
}
