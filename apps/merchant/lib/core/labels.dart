import 'package:flutter/widgets.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import 'l10n_ext.dart';

/// Localized on-screen labels for domain enums. (Printed receipts use the
/// English labels in packages/domain/receipt_templates.dart — these are the
/// app-UI counterparts.)

extension OrderTypeL10n on domain.OrderType {
  String label(BuildContext context) => switch (this) {
    domain.OrderType.dineIn => context.l10n.orderDineIn,
    domain.OrderType.takeout => context.l10n.orderTakeout,
    domain.OrderType.online => context.l10n.orderOnline,
  };
}

String paymentMethodLabel(BuildContext context, domain.PaymentMethod method) =>
    switch (method) {
      domain.PaymentMethod.cash => context.l10n.payCash,
      domain.PaymentMethod.terminal => context.l10n.payCard,
      domain.PaymentMethod.manual => context.l10n.payCardKeyed,
    };
