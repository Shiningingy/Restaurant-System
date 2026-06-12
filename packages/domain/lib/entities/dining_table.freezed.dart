// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dining_table.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiningTable {
  String get id;
  String get label;
  bool get isActive;

  /// Create a copy of DiningTable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DiningTableCopyWith<DiningTable> get copyWith =>
      _$DiningTableCopyWithImpl<DiningTable>(this as DiningTable, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DiningTable &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, label, isActive);

  @override
  String toString() {
    return 'DiningTable(id: $id, label: $label, isActive: $isActive)';
  }
}

/// @nodoc
abstract mixin class $DiningTableCopyWith<$Res> {
  factory $DiningTableCopyWith(
          DiningTable value, $Res Function(DiningTable) _then) =
      _$DiningTableCopyWithImpl;
  @useResult
  $Res call({String id, String label, bool isActive});
}

/// @nodoc
class _$DiningTableCopyWithImpl<$Res> implements $DiningTableCopyWith<$Res> {
  _$DiningTableCopyWithImpl(this._self, this._then);

  final DiningTable _self;
  final $Res Function(DiningTable) _then;

  /// Create a copy of DiningTable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? isActive = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [DiningTable].
extension DiningTablePatterns on DiningTable {
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
    TResult Function(_DiningTable value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DiningTable() when $default != null:
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
    TResult Function(_DiningTable value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiningTable():
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
    TResult? Function(_DiningTable value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiningTable() when $default != null:
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
    TResult Function(String id, String label, bool isActive)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DiningTable() when $default != null:
        return $default(_that.id, _that.label, _that.isActive);
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
    TResult Function(String id, String label, bool isActive) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiningTable():
        return $default(_that.id, _that.label, _that.isActive);
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
    TResult? Function(String id, String label, bool isActive)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiningTable() when $default != null:
        return $default(_that.id, _that.label, _that.isActive);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DiningTable implements DiningTable {
  const _DiningTable(
      {required this.id, required this.label, this.isActive = true});

  @override
  final String id;
  @override
  final String label;
  @override
  @JsonKey()
  final bool isActive;

  /// Create a copy of DiningTable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DiningTableCopyWith<_DiningTable> get copyWith =>
      __$DiningTableCopyWithImpl<_DiningTable>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DiningTable &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, label, isActive);

  @override
  String toString() {
    return 'DiningTable(id: $id, label: $label, isActive: $isActive)';
  }
}

/// @nodoc
abstract mixin class _$DiningTableCopyWith<$Res>
    implements $DiningTableCopyWith<$Res> {
  factory _$DiningTableCopyWith(
          _DiningTable value, $Res Function(_DiningTable) _then) =
      __$DiningTableCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String label, bool isActive});
}

/// @nodoc
class __$DiningTableCopyWithImpl<$Res> implements _$DiningTableCopyWith<$Res> {
  __$DiningTableCopyWithImpl(this._self, this._then);

  final _DiningTable _self;
  final $Res Function(_DiningTable) _then;

  /// Create a copy of DiningTable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? isActive = null,
  }) {
    return _then(_DiningTable(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
