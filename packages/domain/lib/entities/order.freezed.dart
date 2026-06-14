// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Order {
  String get id;
  OrderType get type;
  OrderStatus get status;
  DateTime get createdAt;

  /// Tax rate in basis points (1300 = 13%), snapshotted at creation so a
  /// settings change never rewrites an existing order.
  int get taxRateBp;
  String? get tableId;
  DateTime? get closedAt;
  Money get subtotal;
  Money get tax;
  Money get total;
  String? get note;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OrderCopyWith<Order> get copyWith =>
      _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Order &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.taxRateBp, taxRateBp) ||
                other.taxRateBp == taxRateBp) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.closedAt, closedAt) ||
                other.closedAt == closedAt) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.tax, tax) || other.tax == tax) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.note, note) || other.note == note));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, type, status, createdAt,
      taxRateBp, tableId, closedAt, subtotal, tax, total, note);

  @override
  String toString() {
    return 'Order(id: $id, type: $type, status: $status, createdAt: $createdAt, taxRateBp: $taxRateBp, tableId: $tableId, closedAt: $closedAt, subtotal: $subtotal, tax: $tax, total: $total, note: $note)';
  }
}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res> {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) =
      _$OrderCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      OrderType type,
      OrderStatus status,
      DateTime createdAt,
      int taxRateBp,
      String? tableId,
      DateTime? closedAt,
      Money subtotal,
      Money tax,
      Money total,
      String? note});
}

/// @nodoc
class _$OrderCopyWithImpl<$Res> implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? status = null,
    Object? createdAt = null,
    Object? taxRateBp = null,
    Object? tableId = freezed,
    Object? closedAt = freezed,
    Object? subtotal = null,
    Object? tax = null,
    Object? total = null,
    Object? note = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as OrderType,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      taxRateBp: null == taxRateBp
          ? _self.taxRateBp
          : taxRateBp // ignore: cast_nullable_to_non_nullable
              as int,
      tableId: freezed == tableId
          ? _self.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as String?,
      closedAt: freezed == closedAt
          ? _self.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      subtotal: null == subtotal
          ? _self.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as Money,
      tax: null == tax
          ? _self.tax
          : tax // ignore: cast_nullable_to_non_nullable
              as Money,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as Money,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Order value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Order() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Order value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Order():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Order value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Order() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            OrderType type,
            OrderStatus status,
            DateTime createdAt,
            int taxRateBp,
            String? tableId,
            DateTime? closedAt,
            Money subtotal,
            Money tax,
            Money total,
            String? note)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Order() when $default != null:
        return $default(
            _that.id,
            _that.type,
            _that.status,
            _that.createdAt,
            _that.taxRateBp,
            _that.tableId,
            _that.closedAt,
            _that.subtotal,
            _that.tax,
            _that.total,
            _that.note);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            OrderType type,
            OrderStatus status,
            DateTime createdAt,
            int taxRateBp,
            String? tableId,
            DateTime? closedAt,
            Money subtotal,
            Money tax,
            Money total,
            String? note)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Order():
        return $default(
            _that.id,
            _that.type,
            _that.status,
            _that.createdAt,
            _that.taxRateBp,
            _that.tableId,
            _that.closedAt,
            _that.subtotal,
            _that.tax,
            _that.total,
            _that.note);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            OrderType type,
            OrderStatus status,
            DateTime createdAt,
            int taxRateBp,
            String? tableId,
            DateTime? closedAt,
            Money subtotal,
            Money tax,
            Money total,
            String? note)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Order() when $default != null:
        return $default(
            _that.id,
            _that.type,
            _that.status,
            _that.createdAt,
            _that.taxRateBp,
            _that.tableId,
            _that.closedAt,
            _that.subtotal,
            _that.tax,
            _that.total,
            _that.note);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Order implements Order {
  const _Order(
      {required this.id,
      required this.type,
      required this.status,
      required this.createdAt,
      required this.taxRateBp,
      this.tableId,
      this.closedAt,
      this.subtotal = Money.zero,
      this.tax = Money.zero,
      this.total = Money.zero,
      this.note});

  @override
  final String id;
  @override
  final OrderType type;
  @override
  final OrderStatus status;
  @override
  final DateTime createdAt;

  /// Tax rate in basis points (1300 = 13%), snapshotted at creation so a
  /// settings change never rewrites an existing order.
  @override
  final int taxRateBp;
  @override
  final String? tableId;
  @override
  final DateTime? closedAt;
  @override
  @JsonKey()
  final Money subtotal;
  @override
  @JsonKey()
  final Money tax;
  @override
  @JsonKey()
  final Money total;
  @override
  final String? note;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OrderCopyWith<_Order> get copyWith =>
      __$OrderCopyWithImpl<_Order>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Order &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.taxRateBp, taxRateBp) ||
                other.taxRateBp == taxRateBp) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.closedAt, closedAt) ||
                other.closedAt == closedAt) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.tax, tax) || other.tax == tax) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.note, note) || other.note == note));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, type, status, createdAt,
      taxRateBp, tableId, closedAt, subtotal, tax, total, note);

  @override
  String toString() {
    return 'Order(id: $id, type: $type, status: $status, createdAt: $createdAt, taxRateBp: $taxRateBp, tableId: $tableId, closedAt: $closedAt, subtotal: $subtotal, tax: $tax, total: $total, note: $note)';
  }
}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) =
      __$OrderCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      OrderType type,
      OrderStatus status,
      DateTime createdAt,
      int taxRateBp,
      String? tableId,
      DateTime? closedAt,
      Money subtotal,
      Money tax,
      Money total,
      String? note});
}

/// @nodoc
class __$OrderCopyWithImpl<$Res> implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? status = null,
    Object? createdAt = null,
    Object? taxRateBp = null,
    Object? tableId = freezed,
    Object? closedAt = freezed,
    Object? subtotal = null,
    Object? tax = null,
    Object? total = null,
    Object? note = freezed,
  }) {
    return _then(_Order(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as OrderType,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      taxRateBp: null == taxRateBp
          ? _self.taxRateBp
          : taxRateBp // ignore: cast_nullable_to_non_nullable
              as int,
      tableId: freezed == tableId
          ? _self.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as String?,
      closedAt: freezed == closedAt
          ? _self.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      subtotal: null == subtotal
          ? _self.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as Money,
      tax: null == tax
          ? _self.tax
          : tax // ignore: cast_nullable_to_non_nullable
              as Money,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as Money,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$OrderLine {
  String get id;
  String get orderId;
  String get menuItemId;
  String get nameSnapshot;
  Money get priceSnapshot;
  int get qty;
  Money get lineTotal;
  OrderLineStatus get status;

  /// Item code + second name line, snapshotted at sale time so a later menu
  /// edit never rewrites order history (mirrors [nameSnapshot]).
  String? get codeSnapshot;
  String? get nameSecondarySnapshot;
  String? get note;

  /// Filled by the repository from the line-modifier rows.
  List<OrderLineModifier> get modifiers;

  /// Create a copy of OrderLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OrderLineCopyWith<OrderLine> get copyWith =>
      _$OrderLineCopyWithImpl<OrderLine>(this as OrderLine, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is OrderLine &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.menuItemId, menuItemId) ||
                other.menuItemId == menuItemId) &&
            (identical(other.nameSnapshot, nameSnapshot) ||
                other.nameSnapshot == nameSnapshot) &&
            (identical(other.priceSnapshot, priceSnapshot) ||
                other.priceSnapshot == priceSnapshot) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.lineTotal, lineTotal) ||
                other.lineTotal == lineTotal) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.codeSnapshot, codeSnapshot) ||
                other.codeSnapshot == codeSnapshot) &&
            (identical(other.nameSecondarySnapshot, nameSecondarySnapshot) ||
                other.nameSecondarySnapshot == nameSecondarySnapshot) &&
            (identical(other.note, note) || other.note == note) &&
            const DeepCollectionEquality().equals(other.modifiers, modifiers));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      orderId,
      menuItemId,
      nameSnapshot,
      priceSnapshot,
      qty,
      lineTotal,
      status,
      codeSnapshot,
      nameSecondarySnapshot,
      note,
      const DeepCollectionEquality().hash(modifiers));

  @override
  String toString() {
    return 'OrderLine(id: $id, orderId: $orderId, menuItemId: $menuItemId, nameSnapshot: $nameSnapshot, priceSnapshot: $priceSnapshot, qty: $qty, lineTotal: $lineTotal, status: $status, codeSnapshot: $codeSnapshot, nameSecondarySnapshot: $nameSecondarySnapshot, note: $note, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $OrderLineCopyWith<$Res> {
  factory $OrderLineCopyWith(OrderLine value, $Res Function(OrderLine) _then) =
      _$OrderLineCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String orderId,
      String menuItemId,
      String nameSnapshot,
      Money priceSnapshot,
      int qty,
      Money lineTotal,
      OrderLineStatus status,
      String? codeSnapshot,
      String? nameSecondarySnapshot,
      String? note,
      List<OrderLineModifier> modifiers});
}

/// @nodoc
class _$OrderLineCopyWithImpl<$Res> implements $OrderLineCopyWith<$Res> {
  _$OrderLineCopyWithImpl(this._self, this._then);

  final OrderLine _self;
  final $Res Function(OrderLine) _then;

  /// Create a copy of OrderLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? menuItemId = null,
    Object? nameSnapshot = null,
    Object? priceSnapshot = null,
    Object? qty = null,
    Object? lineTotal = null,
    Object? status = null,
    Object? codeSnapshot = freezed,
    Object? nameSecondarySnapshot = freezed,
    Object? note = freezed,
    Object? modifiers = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _self.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      menuItemId: null == menuItemId
          ? _self.menuItemId
          : menuItemId // ignore: cast_nullable_to_non_nullable
              as String,
      nameSnapshot: null == nameSnapshot
          ? _self.nameSnapshot
          : nameSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      priceSnapshot: null == priceSnapshot
          ? _self.priceSnapshot
          : priceSnapshot // ignore: cast_nullable_to_non_nullable
              as Money,
      qty: null == qty
          ? _self.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as int,
      lineTotal: null == lineTotal
          ? _self.lineTotal
          : lineTotal // ignore: cast_nullable_to_non_nullable
              as Money,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderLineStatus,
      codeSnapshot: freezed == codeSnapshot
          ? _self.codeSnapshot
          : codeSnapshot // ignore: cast_nullable_to_non_nullable
              as String?,
      nameSecondarySnapshot: freezed == nameSecondarySnapshot
          ? _self.nameSecondarySnapshot
          : nameSecondarySnapshot // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      modifiers: null == modifiers
          ? _self.modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<OrderLineModifier>,
    ));
  }
}

/// Adds pattern-matching-related methods to [OrderLine].
extension OrderLinePatterns on OrderLine {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_OrderLine value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OrderLine() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_OrderLine value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrderLine():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_OrderLine value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrderLine() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String orderId,
            String menuItemId,
            String nameSnapshot,
            Money priceSnapshot,
            int qty,
            Money lineTotal,
            OrderLineStatus status,
            String? codeSnapshot,
            String? nameSecondarySnapshot,
            String? note,
            List<OrderLineModifier> modifiers)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OrderLine() when $default != null:
        return $default(
            _that.id,
            _that.orderId,
            _that.menuItemId,
            _that.nameSnapshot,
            _that.priceSnapshot,
            _that.qty,
            _that.lineTotal,
            _that.status,
            _that.codeSnapshot,
            _that.nameSecondarySnapshot,
            _that.note,
            _that.modifiers);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String orderId,
            String menuItemId,
            String nameSnapshot,
            Money priceSnapshot,
            int qty,
            Money lineTotal,
            OrderLineStatus status,
            String? codeSnapshot,
            String? nameSecondarySnapshot,
            String? note,
            List<OrderLineModifier> modifiers)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrderLine():
        return $default(
            _that.id,
            _that.orderId,
            _that.menuItemId,
            _that.nameSnapshot,
            _that.priceSnapshot,
            _that.qty,
            _that.lineTotal,
            _that.status,
            _that.codeSnapshot,
            _that.nameSecondarySnapshot,
            _that.note,
            _that.modifiers);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String orderId,
            String menuItemId,
            String nameSnapshot,
            Money priceSnapshot,
            int qty,
            Money lineTotal,
            OrderLineStatus status,
            String? codeSnapshot,
            String? nameSecondarySnapshot,
            String? note,
            List<OrderLineModifier> modifiers)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrderLine() when $default != null:
        return $default(
            _that.id,
            _that.orderId,
            _that.menuItemId,
            _that.nameSnapshot,
            _that.priceSnapshot,
            _that.qty,
            _that.lineTotal,
            _that.status,
            _that.codeSnapshot,
            _that.nameSecondarySnapshot,
            _that.note,
            _that.modifiers);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _OrderLine implements OrderLine {
  const _OrderLine(
      {required this.id,
      required this.orderId,
      required this.menuItemId,
      required this.nameSnapshot,
      required this.priceSnapshot,
      required this.qty,
      required this.lineTotal,
      this.status = OrderLineStatus.active,
      this.codeSnapshot,
      this.nameSecondarySnapshot,
      this.note,
      final List<OrderLineModifier> modifiers = const []})
      : _modifiers = modifiers;

  @override
  final String id;
  @override
  final String orderId;
  @override
  final String menuItemId;
  @override
  final String nameSnapshot;
  @override
  final Money priceSnapshot;
  @override
  final int qty;
  @override
  final Money lineTotal;
  @override
  @JsonKey()
  final OrderLineStatus status;

  /// Item code + second name line, snapshotted at sale time so a later menu
  /// edit never rewrites order history (mirrors [nameSnapshot]).
  @override
  final String? codeSnapshot;
  @override
  final String? nameSecondarySnapshot;
  @override
  final String? note;

  /// Filled by the repository from the line-modifier rows.
  final List<OrderLineModifier> _modifiers;

  /// Filled by the repository from the line-modifier rows.
  @override
  @JsonKey()
  List<OrderLineModifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  /// Create a copy of OrderLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OrderLineCopyWith<_OrderLine> get copyWith =>
      __$OrderLineCopyWithImpl<_OrderLine>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OrderLine &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.menuItemId, menuItemId) ||
                other.menuItemId == menuItemId) &&
            (identical(other.nameSnapshot, nameSnapshot) ||
                other.nameSnapshot == nameSnapshot) &&
            (identical(other.priceSnapshot, priceSnapshot) ||
                other.priceSnapshot == priceSnapshot) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.lineTotal, lineTotal) ||
                other.lineTotal == lineTotal) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.codeSnapshot, codeSnapshot) ||
                other.codeSnapshot == codeSnapshot) &&
            (identical(other.nameSecondarySnapshot, nameSecondarySnapshot) ||
                other.nameSecondarySnapshot == nameSecondarySnapshot) &&
            (identical(other.note, note) || other.note == note) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      orderId,
      menuItemId,
      nameSnapshot,
      priceSnapshot,
      qty,
      lineTotal,
      status,
      codeSnapshot,
      nameSecondarySnapshot,
      note,
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString() {
    return 'OrderLine(id: $id, orderId: $orderId, menuItemId: $menuItemId, nameSnapshot: $nameSnapshot, priceSnapshot: $priceSnapshot, qty: $qty, lineTotal: $lineTotal, status: $status, codeSnapshot: $codeSnapshot, nameSecondarySnapshot: $nameSecondarySnapshot, note: $note, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class _$OrderLineCopyWith<$Res>
    implements $OrderLineCopyWith<$Res> {
  factory _$OrderLineCopyWith(
          _OrderLine value, $Res Function(_OrderLine) _then) =
      __$OrderLineCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String orderId,
      String menuItemId,
      String nameSnapshot,
      Money priceSnapshot,
      int qty,
      Money lineTotal,
      OrderLineStatus status,
      String? codeSnapshot,
      String? nameSecondarySnapshot,
      String? note,
      List<OrderLineModifier> modifiers});
}

/// @nodoc
class __$OrderLineCopyWithImpl<$Res> implements _$OrderLineCopyWith<$Res> {
  __$OrderLineCopyWithImpl(this._self, this._then);

  final _OrderLine _self;
  final $Res Function(_OrderLine) _then;

  /// Create a copy of OrderLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? menuItemId = null,
    Object? nameSnapshot = null,
    Object? priceSnapshot = null,
    Object? qty = null,
    Object? lineTotal = null,
    Object? status = null,
    Object? codeSnapshot = freezed,
    Object? nameSecondarySnapshot = freezed,
    Object? note = freezed,
    Object? modifiers = null,
  }) {
    return _then(_OrderLine(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _self.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      menuItemId: null == menuItemId
          ? _self.menuItemId
          : menuItemId // ignore: cast_nullable_to_non_nullable
              as String,
      nameSnapshot: null == nameSnapshot
          ? _self.nameSnapshot
          : nameSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      priceSnapshot: null == priceSnapshot
          ? _self.priceSnapshot
          : priceSnapshot // ignore: cast_nullable_to_non_nullable
              as Money,
      qty: null == qty
          ? _self.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as int,
      lineTotal: null == lineTotal
          ? _self.lineTotal
          : lineTotal // ignore: cast_nullable_to_non_nullable
              as Money,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderLineStatus,
      codeSnapshot: freezed == codeSnapshot
          ? _self.codeSnapshot
          : codeSnapshot // ignore: cast_nullable_to_non_nullable
              as String?,
      nameSecondarySnapshot: freezed == nameSecondarySnapshot
          ? _self.nameSecondarySnapshot
          : nameSecondarySnapshot // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<OrderLineModifier>,
    ));
  }
}

/// @nodoc
mixin _$OrderLineModifier {
  String get id;
  String get lineId;
  String get nameSnapshot;
  Money get priceDeltaSnapshot;

  /// Create a copy of OrderLineModifier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OrderLineModifierCopyWith<OrderLineModifier> get copyWith =>
      _$OrderLineModifierCopyWithImpl<OrderLineModifier>(
          this as OrderLineModifier, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is OrderLineModifier &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lineId, lineId) || other.lineId == lineId) &&
            (identical(other.nameSnapshot, nameSnapshot) ||
                other.nameSnapshot == nameSnapshot) &&
            (identical(other.priceDeltaSnapshot, priceDeltaSnapshot) ||
                other.priceDeltaSnapshot == priceDeltaSnapshot));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, lineId, nameSnapshot, priceDeltaSnapshot);

  @override
  String toString() {
    return 'OrderLineModifier(id: $id, lineId: $lineId, nameSnapshot: $nameSnapshot, priceDeltaSnapshot: $priceDeltaSnapshot)';
  }
}

/// @nodoc
abstract mixin class $OrderLineModifierCopyWith<$Res> {
  factory $OrderLineModifierCopyWith(
          OrderLineModifier value, $Res Function(OrderLineModifier) _then) =
      _$OrderLineModifierCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String lineId,
      String nameSnapshot,
      Money priceDeltaSnapshot});
}

/// @nodoc
class _$OrderLineModifierCopyWithImpl<$Res>
    implements $OrderLineModifierCopyWith<$Res> {
  _$OrderLineModifierCopyWithImpl(this._self, this._then);

  final OrderLineModifier _self;
  final $Res Function(OrderLineModifier) _then;

  /// Create a copy of OrderLineModifier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lineId = null,
    Object? nameSnapshot = null,
    Object? priceDeltaSnapshot = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lineId: null == lineId
          ? _self.lineId
          : lineId // ignore: cast_nullable_to_non_nullable
              as String,
      nameSnapshot: null == nameSnapshot
          ? _self.nameSnapshot
          : nameSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      priceDeltaSnapshot: null == priceDeltaSnapshot
          ? _self.priceDeltaSnapshot
          : priceDeltaSnapshot // ignore: cast_nullable_to_non_nullable
              as Money,
    ));
  }
}

/// Adds pattern-matching-related methods to [OrderLineModifier].
extension OrderLineModifierPatterns on OrderLineModifier {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_OrderLineModifier value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OrderLineModifier() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_OrderLineModifier value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrderLineModifier():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_OrderLineModifier value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrderLineModifier() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String id, String lineId, String nameSnapshot,
            Money priceDeltaSnapshot)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OrderLineModifier() when $default != null:
        return $default(_that.id, _that.lineId, _that.nameSnapshot,
            _that.priceDeltaSnapshot);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String id, String lineId, String nameSnapshot,
            Money priceDeltaSnapshot)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrderLineModifier():
        return $default(_that.id, _that.lineId, _that.nameSnapshot,
            _that.priceDeltaSnapshot);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String id, String lineId, String nameSnapshot,
            Money priceDeltaSnapshot)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrderLineModifier() when $default != null:
        return $default(_that.id, _that.lineId, _that.nameSnapshot,
            _that.priceDeltaSnapshot);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _OrderLineModifier implements OrderLineModifier {
  const _OrderLineModifier(
      {required this.id,
      required this.lineId,
      required this.nameSnapshot,
      required this.priceDeltaSnapshot});

  @override
  final String id;
  @override
  final String lineId;
  @override
  final String nameSnapshot;
  @override
  final Money priceDeltaSnapshot;

  /// Create a copy of OrderLineModifier
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OrderLineModifierCopyWith<_OrderLineModifier> get copyWith =>
      __$OrderLineModifierCopyWithImpl<_OrderLineModifier>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OrderLineModifier &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lineId, lineId) || other.lineId == lineId) &&
            (identical(other.nameSnapshot, nameSnapshot) ||
                other.nameSnapshot == nameSnapshot) &&
            (identical(other.priceDeltaSnapshot, priceDeltaSnapshot) ||
                other.priceDeltaSnapshot == priceDeltaSnapshot));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, lineId, nameSnapshot, priceDeltaSnapshot);

  @override
  String toString() {
    return 'OrderLineModifier(id: $id, lineId: $lineId, nameSnapshot: $nameSnapshot, priceDeltaSnapshot: $priceDeltaSnapshot)';
  }
}

/// @nodoc
abstract mixin class _$OrderLineModifierCopyWith<$Res>
    implements $OrderLineModifierCopyWith<$Res> {
  factory _$OrderLineModifierCopyWith(
          _OrderLineModifier value, $Res Function(_OrderLineModifier) _then) =
      __$OrderLineModifierCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String lineId,
      String nameSnapshot,
      Money priceDeltaSnapshot});
}

/// @nodoc
class __$OrderLineModifierCopyWithImpl<$Res>
    implements _$OrderLineModifierCopyWith<$Res> {
  __$OrderLineModifierCopyWithImpl(this._self, this._then);

  final _OrderLineModifier _self;
  final $Res Function(_OrderLineModifier) _then;

  /// Create a copy of OrderLineModifier
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? lineId = null,
    Object? nameSnapshot = null,
    Object? priceDeltaSnapshot = null,
  }) {
    return _then(_OrderLineModifier(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lineId: null == lineId
          ? _self.lineId
          : lineId // ignore: cast_nullable_to_non_nullable
              as String,
      nameSnapshot: null == nameSnapshot
          ? _self.nameSnapshot
          : nameSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      priceDeltaSnapshot: null == priceDeltaSnapshot
          ? _self.priceDeltaSnapshot
          : priceDeltaSnapshot // ignore: cast_nullable_to_non_nullable
              as Money,
    ));
  }
}

// dart format on
