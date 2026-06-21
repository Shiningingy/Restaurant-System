/// Builds [TicketDoc]s for the two Phase 2 documents: the kitchen ticket
/// (what to cook — big type, no prices) and the customer receipt.
///
/// Templates read only snapshotted order data, so a reprint after a menu
/// edit reproduces the original document exactly.
library;

import 'package:intl/intl.dart';

import '../entities/order.dart';
import '../entities/payment.dart';
import 'payment_math.dart';
import 'ticket.dart';

/// Restaurant identity printed on customer receipts; configured in the
/// merchant app's settings.
class ReceiptConfig {
  final String businessName;

  /// Address / phone lines under the name.
  final List<String> headerLines;

  /// Closing line, e.g. "Thank you!".
  final String footer;

  const ReceiptConfig({
    required this.businessName,
    this.headerLines = const [],
    this.footer = '',
  });
}

/// Short human-readable order reference for tickets ("#3F2A").
String orderRef(String orderId) =>
    '#${orderId.replaceAll('-', '').substring(0, 4).toUpperCase()}';

String _orderTypeLabel(Order order, String? tableLabel) => switch (order.type) {
      OrderType.dineIn =>
        tableLabel == null ? 'DINE-IN' : 'DINE-IN  TABLE $tableLabel',
      OrderType.takeout => 'TAKEOUT',
      OrderType.online => 'ONLINE',
    };

/// Human label for a payment method, shared by receipts and the POS UI.
String paymentMethodLabel(PaymentMethod method) => switch (method) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.terminal => 'Card',
      PaymentMethod.manual => 'Card (keyed)',
    };

/// Leading "A01  " label for a line when the item carried a code, else ''.
String _codePrefix(OrderLine line) {
  final code = line.codeSnapshot;
  return code == null || code.isEmpty ? '' : '$code  ';
}

final _timeFormat = DateFormat('HH:mm');
final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

TicketDoc buildKitchenTicket({
  required Order order,
  required List<OrderLine> lines,
  String? tableLabel,
  DateTime? printedAt,
  bool showSecondName = true,
}) {
  final active =
      lines.where((l) => l.status == OrderLineStatus.active).toList();
  final ops = <TicketOp>[
    TicketText(_orderTypeLabel(order, tableLabel), style: TicketStyle.title),
    TicketText(
      '${orderRef(order.id)}  ${_timeFormat.format(printedAt ?? order.createdAt)}',
      style: TicketStyle.centered,
    ),
    const TicketDivider(),
    for (final line in active) ...[
      TicketText(
        '${line.qty} x ${_codePrefix(line)}${line.nameSnapshot}',
        style: TicketStyle.big,
      ),
      if (showSecondName &&
          line.nameSecondarySnapshot != null &&
          line.nameSecondarySnapshot!.isNotEmpty)
        TicketText('     ${line.nameSecondarySnapshot}',
            style: TicketStyle.big),
      for (final m in line.modifiers)
        TicketText('   + ${m.nameSnapshot}', style: TicketStyle.big),
      if (line.note != null && line.note!.isNotEmpty)
        TicketText('   * ${line.note}', style: TicketStyle.big),
    ],
    if (order.note != null && order.note!.isNotEmpty) ...[
      const TicketDivider(),
      TicketText('NOTE: ${order.note}', style: TicketStyle.big),
    ],
    const TicketFeed(3),
    const TicketCut(),
  ];
  return TicketDoc(ops);
}

TicketDoc buildCustomerReceipt({
  required Order order,
  required List<OrderLine> lines,
  required ReceiptConfig config,
  List<Payment> payments = const [],
  String? tableLabel,
  bool showSecondName = false,
  bool openDrawer = false,
}) {
  final active =
      lines.where((l) => l.status == OrderLineStatus.active).toList();
  final settled = settledPayments(payments).toList();
  final balance = balanceDue(total: order.total, payments: payments);
  final taxLabel = 'Tax (${(order.taxRateBp / 100).toStringAsFixed(2)}%)';
  final ops = <TicketOp>[
    TicketText(config.businessName, style: TicketStyle.title),
    for (final line in config.headerLines)
      TicketText(line, style: TicketStyle.centered),
    const TicketFeed(),
    TicketText(_orderTypeLabel(order, tableLabel),
        style: TicketStyle.emphasized),
    TicketText(
      '${orderRef(order.id)}  ${_dateTimeFormat.format(order.closedAt ?? order.createdAt)}',
    ),
    const TicketDivider(),
    for (final line in active) ...[
      TicketRow(
        '${line.qty} x ${_codePrefix(line)}${line.nameSnapshot}',
        line.lineTotal.format(),
      ),
      if (showSecondName &&
          line.nameSecondarySnapshot != null &&
          line.nameSecondarySnapshot!.isNotEmpty)
        TicketText('     ${line.nameSecondarySnapshot}'),
      for (final m in line.modifiers)
        TicketRow(
          '   ${m.nameSnapshot}',
          m.priceDeltaSnapshot.isZero
              ? ''
              : '+${m.priceDeltaSnapshot.format()}',
        ),
    ],
    const TicketDivider(),
    TicketRow('Subtotal', order.subtotal.format()),
    if (!order.discount.isZero)
      TicketRow('Discount', '-${order.discount.format()}'),
    if (!order.serviceFee.isZero)
      TicketRow(
        'Service fee (${(order.serviceFeeBp / 100).toStringAsFixed(2)}%)',
        order.serviceFee.format(),
      ),
    TicketRow(taxLabel, order.tax.format()),
    TicketRow('TOTAL', order.total.format(), style: TicketStyle.emphasized),
    if (settled.isNotEmpty) ...[
      const TicketFeed(),
      for (final payment in settled) ...[
        TicketRow(paymentMethodLabel(payment.method), payment.amount.format()),
        if (!payment.tip.isZero) TicketRow('   Tip', payment.tip.format()),
      ],
      if (!balance.isZero)
        TicketRow('BALANCE DUE', balance.format(),
            style: TicketStyle.emphasized),
    ],
    if (config.footer.isNotEmpty) ...[
      const TicketFeed(),
      TicketText(config.footer, style: TicketStyle.centered),
    ],
    const TicketFeed(3),
    const TicketCut(),
    if (openDrawer) const TicketKickDrawer(),
  ];
  return TicketDoc(ops);
}
