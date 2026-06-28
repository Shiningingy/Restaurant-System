import 'package:freezed_annotation/freezed_annotation.dart';

import '../src/money.dart';

part 'order.freezed.dart';

enum OrderType { dineIn, takeout, online }

/// Lifecycle: `open` → `sent` (to kitchen) → `paid` (fully paid, but still
/// being prepared — stays on the board) → `done` (finished/handed over, leaves
/// the board → history). `voided` is a cancelled order kept for the record.
enum OrderStatus { open, sent, paid, done, voided }

enum OrderLineStatus { active, voided }

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required OrderType type,
    required OrderStatus status,
    required DateTime createdAt,

    /// Tax rate in basis points (1300 = 13%), snapshotted at creation so a
    /// settings change never rewrites an existing order.
    required int taxRateBp,

    /// Service-fee rate in basis points, snapshotted at creation like
    /// [taxRateBp] so a settings change never rewrites an existing order.
    @Default(0) int serviceFeeBp,
    String? tableId,

    /// When the order was fully paid (the financial event). Set independently
    /// of [closedAt] so a paid order can sit on the board (being prepared) and
    /// still count as a sale on the day it was paid.
    DateTime? paidAt,

    /// When the order left the board — finished (`done`) or `voided`.
    DateTime? closedAt,
    @Default(Money.zero) Money subtotal,

    /// Discount applied to the order (off the subtotal, before tax).
    @Default(Money.zero) Money discount,

    /// Service fee charged on the discounted subtotal.
    @Default(Money.zero) Money serviceFee,
    @Default(Money.zero) Money tax,
    @Default(Money.zero) Money total,

    /// A tip the customer chose at the kiosk / online checkout, carried onto the
    /// local order so staff see it and the payment sheet pre-fills it at
    /// settlement. Not part of [total] (the tip rides on top of the payment).
    @Default(Money.zero) Money requestedTip,
    String? note,
  }) = _Order;
}

/// Name and price are snapshotted from the menu item at sale time —
/// menu edits never rewrite order history (see docs/ARCHITECTURE.md).
@freezed
abstract class OrderLine with _$OrderLine {
  const factory OrderLine({
    required String id,
    required String orderId,
    required String menuItemId,
    required String nameSnapshot,
    required Money priceSnapshot,
    required int qty,
    required Money lineTotal,
    @Default(OrderLineStatus.active) OrderLineStatus status,

    /// A comped (on-the-house) line: still active — the kitchen makes it and it
    /// prints on the receipt — but it costs the customer nothing. Its
    /// [lineTotal] is kept as the original price so the comp's worth is known
    /// (reports, the manager's comp cap); the totals math routes it out of the
    /// billable subtotal into [OrderTotals.comps] instead.
    @Default(false) bool comped,

    /// Set to the id of the payment that settled this line when the bill is
    /// split by item; null while the line is still unpaid. Purely a record of
    /// which split paid for it — the order still closes on the payment balance.
    String? settledByPaymentId,

    /// Item code + second name line, snapshotted at sale time so a later menu
    /// edit never rewrites order history (mirrors [nameSnapshot]).
    String? codeSnapshot,
    String? nameSecondarySnapshot,
    String? note,

    /// Filled by the repository from the line-modifier rows.
    @Default([]) List<OrderLineModifier> modifiers,
  }) = _OrderLine;
}

@freezed
abstract class OrderLineModifier with _$OrderLineModifier {
  const factory OrderLineModifier({
    required String id,
    required String lineId,
    required String nameSnapshot,
    required Money priceDeltaSnapshot,
  }) = _OrderLineModifier;
}
