// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_item_attribute.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MenuItemAttribute {
  String get id;
  String get label;
  String get value;
  int get sortOrder;

  /// Create a copy of MenuItemAttribute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MenuItemAttributeCopyWith<MenuItemAttribute> get copyWith =>
      _$MenuItemAttributeCopyWithImpl<MenuItemAttribute>(
          this as MenuItemAttribute, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MenuItemAttribute &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, label, value, sortOrder);

  @override
  String toString() {
    return 'MenuItemAttribute(id: $id, label: $label, value: $value, sortOrder: $sortOrder)';
  }
}

/// @nodoc
abstract mixin class $MenuItemAttributeCopyWith<$Res> {
  factory $MenuItemAttributeCopyWith(
          MenuItemAttribute value, $Res Function(MenuItemAttribute) _then) =
      _$MenuItemAttributeCopyWithImpl;
  @useResult
  $Res call({String id, String label, String value, int sortOrder});
}

/// @nodoc
class _$MenuItemAttributeCopyWithImpl<$Res>
    implements $MenuItemAttributeCopyWith<$Res> {
  _$MenuItemAttributeCopyWithImpl(this._self, this._then);

  final MenuItemAttribute _self;
  final $Res Function(MenuItemAttribute) _then;

  /// Create a copy of MenuItemAttribute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? value = null,
    Object? sortOrder = null,
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
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [MenuItemAttribute].
extension MenuItemAttributePatterns on MenuItemAttribute {
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
    TResult Function(_MenuItemAttribute value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MenuItemAttribute() when $default != null:
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
    TResult Function(_MenuItemAttribute value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItemAttribute():
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
    TResult? Function(_MenuItemAttribute value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItemAttribute() when $default != null:
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
    TResult Function(String id, String label, String value, int sortOrder)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MenuItemAttribute() when $default != null:
        return $default(_that.id, _that.label, _that.value, _that.sortOrder);
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
    TResult Function(String id, String label, String value, int sortOrder)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItemAttribute():
        return $default(_that.id, _that.label, _that.value, _that.sortOrder);
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
    TResult? Function(String id, String label, String value, int sortOrder)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItemAttribute() when $default != null:
        return $default(_that.id, _that.label, _that.value, _that.sortOrder);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MenuItemAttribute implements MenuItemAttribute {
  const _MenuItemAttribute(
      {required this.id,
      required this.label,
      required this.value,
      this.sortOrder = 0});

  @override
  final String id;
  @override
  final String label;
  @override
  final String value;
  @override
  @JsonKey()
  final int sortOrder;

  /// Create a copy of MenuItemAttribute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MenuItemAttributeCopyWith<_MenuItemAttribute> get copyWith =>
      __$MenuItemAttributeCopyWithImpl<_MenuItemAttribute>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MenuItemAttribute &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, label, value, sortOrder);

  @override
  String toString() {
    return 'MenuItemAttribute(id: $id, label: $label, value: $value, sortOrder: $sortOrder)';
  }
}

/// @nodoc
abstract mixin class _$MenuItemAttributeCopyWith<$Res>
    implements $MenuItemAttributeCopyWith<$Res> {
  factory _$MenuItemAttributeCopyWith(
          _MenuItemAttribute value, $Res Function(_MenuItemAttribute) _then) =
      __$MenuItemAttributeCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String label, String value, int sortOrder});
}

/// @nodoc
class __$MenuItemAttributeCopyWithImpl<$Res>
    implements _$MenuItemAttributeCopyWith<$Res> {
  __$MenuItemAttributeCopyWithImpl(this._self, this._then);

  final _MenuItemAttribute _self;
  final $Res Function(_MenuItemAttribute) _then;

  /// Create a copy of MenuItemAttribute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? value = null,
    Object? sortOrder = null,
  }) {
    return _then(_MenuItemAttribute(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
