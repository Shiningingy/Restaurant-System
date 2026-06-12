import 'package:freezed_annotation/freezed_annotation.dart';

import '../src/money.dart';

part 'order.freezed.dart';

enum OrderType { dineIn, takeout, online }

/// `sent` (to kitchen) becomes meaningful in Phase 2 (printing).
enum OrderStatus { open, sent, paid, voided }

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
    String? tableId,
    DateTime? closedAt,
    @Default(Money.zero) Money subtotal,
    @Default(Money.zero) Money tax,
    @Default(Money.zero) Money total,
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
