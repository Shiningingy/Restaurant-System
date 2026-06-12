// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Payment {
  String get id;
  String get orderId;
  PaymentMethod get method;
  Money get amount;
  PaymentStatus get status;
  DateTime get createdAt;
  Money get tip;

  /// Vendor-side reference (e.g. Moneris transaction id); null for
  /// cash/manual.
  String? get terminalRef;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PaymentCopyWith<Payment> get copyWith =>
      _$PaymentCopyWithImpl<Payment>(this as Payment, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Payment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.tip, tip) || other.tip == tip) &&
            (identical(other.terminalRef, terminalRef) ||
                other.terminalRef == terminalRef));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, orderId, method, amount,
      status, createdAt, tip, terminalRef);

  @override
  String toString() {
    return 'Payment(id: $id, orderId: $orderId, method: $method, amount: $amount, status: $status, createdAt: $createdAt, tip: $tip, terminalRef: $terminalRef)';
  }
}

/// @nodoc
abstract mixin class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) _then) =
      _$PaymentCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String orderId,
      PaymentMethod method,
      Money amount,
      PaymentStatus status,
      DateTime createdAt,
      Money tip,
      String? terminalRef});
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res> implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._self, this._then);

  final Payment _self;
  final $Res Function(Payment) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? method = null,
    Object? amount = null,
    Object? status = null,
    Object? createdAt = null,
    Object? tip = null,
    Object? terminalRef = freezed,
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
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as PaymentMethod,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as Money,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as PaymentStatus,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tip: null == tip
          ? _self.tip
          : tip // ignore: cast_nullable_to_non_nullable
              as Money,
      terminalRef: freezed == terminalRef
          ? _self.terminalRef
          : terminalRef // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Payment].
extension PaymentPatterns on Payment {
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
    TResult Function(_Payment value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
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
    TResult Function(_Payment value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment():
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
    TResult? Function(_Payment value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
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
            PaymentMethod method,
            Money amount,
            PaymentStatus status,
            DateTime createdAt,
            Money tip,
            String? terminalRef)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
        return $default(_that.id, _that.orderId, _that.method, _that.amount,
            _that.status, _that.createdAt, _that.tip, _that.terminalRef);
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
            PaymentMethod method,
            Money amount,
            PaymentStatus status,
            DateTime createdAt,
            Money tip,
            String? terminalRef)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment():
        return $default(_that.id, _that.orderId, _that.method, _that.amount,
            _that.status, _that.createdAt, _that.tip, _that.terminalRef);
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
            PaymentMethod method,
            Money amount,
            PaymentStatus status,
            DateTime createdAt,
            Money tip,
            String? terminalRef)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
        return $default(_that.id, _that.orderId, _that.method, _that.amount,
            _that.status, _that.createdAt, _that.tip, _that.terminalRef);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Payment implements Payment {
  const _Payment(
      {required this.id,
      required this.orderId,
      required this.method,
      required this.amount,
      required this.status,
      required this.createdAt,
      this.tip = Money.zero,
      this.terminalRef});

  @override
  final String id;
  @override
  final String orderId;
  @override
  final PaymentMethod method;
  @override
  final Money amount;
  @override
  final PaymentStatus status;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final Money tip;

  /// Vendor-side reference (e.g. Moneris transaction id); null for
  /// cash/manual.
  @override
  final String? terminalRef;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PaymentCopyWith<_Payment> get copyWith =>
      __$PaymentCopyWithImpl<_Payment>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Payment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.tip, tip) || other.tip == tip) &&
            (identical(other.terminalRef, terminalRef) ||
                other.terminalRef == terminalRef));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, orderId, method, amount,
      status, createdAt, tip, terminalRef);

  @override
  String toString() {
    return 'Payment(id: $id, orderId: $orderId, method: $method, amount: $amount, status: $status, createdAt: $createdAt, tip: $tip, terminalRef: $terminalRef)';
  }
}

/// @nodoc
abstract mixin class _$PaymentCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$PaymentCopyWith(_Payment value, $Res Function(_Payment) _then) =
      __$PaymentCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String orderId,
      PaymentMethod method,
      Money amount,
      PaymentStatus status,
      DateTime createdAt,
      Money tip,
      String? terminalRef});
}

/// @nodoc
class __$PaymentCopyWithImpl<$Res> implements _$PaymentCopyWith<$Res> {
  __$PaymentCopyWithImpl(this._self, this._then);

  final _Payment _self;
  final $Res Function(_Payment) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? method = null,
    Object? amount = null,
    Object? status = null,
    Object? createdAt = null,
    Object? tip = null,
    Object? terminalRef = freezed,
  }) {
    return _then(_Payment(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _self.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as PaymentMethod,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as Money,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as PaymentStatus,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tip: null == tip
          ? _self.tip
          : tip // ignore: cast_nullable_to_non_nullable
              as Money,
      terminalRef: freezed == terminalRef
          ? _self.terminalRef
          : terminalRef // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
