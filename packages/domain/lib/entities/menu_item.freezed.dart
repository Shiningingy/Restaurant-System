// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MenuItem {
  String get id;
  String get categoryId;
  String get name;
  Money get price;
  String? get sku;
  int get sortOrder;
  bool get isActive;

  /// Ids of the modifier groups offered with this item
  /// (filled by the repository from the join table).
  List<String> get modifierGroupIds;

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MenuItemCopyWith<MenuItem> get copyWith =>
      _$MenuItemCopyWithImpl<MenuItem>(this as MenuItem, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MenuItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.sku, sku) || other.sku == sku) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality()
                .equals(other.modifierGroupIds, modifierGroupIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      categoryId,
      name,
      price,
      sku,
      sortOrder,
      isActive,
      const DeepCollectionEquality().hash(modifierGroupIds));

  @override
  String toString() {
    return 'MenuItem(id: $id, categoryId: $categoryId, name: $name, price: $price, sku: $sku, sortOrder: $sortOrder, isActive: $isActive, modifierGroupIds: $modifierGroupIds)';
  }
}

/// @nodoc
abstract mixin class $MenuItemCopyWith<$Res> {
  factory $MenuItemCopyWith(MenuItem value, $Res Function(MenuItem) _then) =
      _$MenuItemCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String categoryId,
      String name,
      Money price,
      String? sku,
      int sortOrder,
      bool isActive,
      List<String> modifierGroupIds});
}

/// @nodoc
class _$MenuItemCopyWithImpl<$Res> implements $MenuItemCopyWith<$Res> {
  _$MenuItemCopyWithImpl(this._self, this._then);

  final MenuItem _self;
  final $Res Function(MenuItem) _then;

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? name = null,
    Object? price = null,
    Object? sku = freezed,
    Object? sortOrder = null,
    Object? isActive = null,
    Object? modifierGroupIds = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as Money,
      sku: freezed == sku
          ? _self.sku
          : sku // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      modifierGroupIds: null == modifierGroupIds
          ? _self.modifierGroupIds
          : modifierGroupIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [MenuItem].
extension MenuItemPatterns on MenuItem {
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
    TResult Function(_MenuItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MenuItem() when $default != null:
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
    TResult Function(_MenuItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItem():
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
    TResult? Function(_MenuItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItem() when $default != null:
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
            String categoryId,
            String name,
            Money price,
            String? sku,
            int sortOrder,
            bool isActive,
            List<String> modifierGroupIds)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MenuItem() when $default != null:
        return $default(_that.id, _that.categoryId, _that.name, _that.price,
            _that.sku, _that.sortOrder, _that.isActive, _that.modifierGroupIds);
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
            String categoryId,
            String name,
            Money price,
            String? sku,
            int sortOrder,
            bool isActive,
            List<String> modifierGroupIds)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItem():
        return $default(_that.id, _that.categoryId, _that.name, _that.price,
            _that.sku, _that.sortOrder, _that.isActive, _that.modifierGroupIds);
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
            String categoryId,
            String name,
            Money price,
            String? sku,
            int sortOrder,
            bool isActive,
            List<String> modifierGroupIds)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItem() when $default != null:
        return $default(_that.id, _that.categoryId, _that.name, _that.price,
            _that.sku, _that.sortOrder, _that.isActive, _that.modifierGroupIds);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MenuItem implements MenuItem {
  const _MenuItem(
      {required this.id,
      required this.categoryId,
      required this.name,
      required this.price,
      this.sku,
      this.sortOrder = 0,
      this.isActive = true,
      final List<String> modifierGroupIds = const []})
      : _modifierGroupIds = modifierGroupIds;

  @override
  final String id;
  @override
  final String categoryId;
  @override
  final String name;
  @override
  final Money price;
  @override
  final String? sku;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  @JsonKey()
  final bool isActive;

  /// Ids of the modifier groups offered with this item
  /// (filled by the repository from the join table).
  final List<String> _modifierGroupIds;

  /// Ids of the modifier groups offered with this item
  /// (filled by the repository from the join table).
  @override
  @JsonKey()
  List<String> get modifierGroupIds {
    if (_modifierGroupIds is EqualUnmodifiableListView)
      return _modifierGroupIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifierGroupIds);
  }

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MenuItemCopyWith<_MenuItem> get copyWith =>
      __$MenuItemCopyWithImpl<_MenuItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MenuItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.sku, sku) || other.sku == sku) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality()
                .equals(other._modifierGroupIds, _modifierGroupIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      categoryId,
      name,
      price,
      sku,
      sortOrder,
      isActive,
      const DeepCollectionEquality().hash(_modifierGroupIds));

  @override
  String toString() {
    return 'MenuItem(id: $id, categoryId: $categoryId, name: $name, price: $price, sku: $sku, sortOrder: $sortOrder, isActive: $isActive, modifierGroupIds: $modifierGroupIds)';
  }
}

/// @nodoc
abstract mixin class _$MenuItemCopyWith<$Res>
    implements $MenuItemCopyWith<$Res> {
  factory _$MenuItemCopyWith(_MenuItem value, $Res Function(_MenuItem) _then) =
      __$MenuItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String categoryId,
      String name,
      Money price,
      String? sku,
      int sortOrder,
      bool isActive,
      List<String> modifierGroupIds});
}

/// @nodoc
class __$MenuItemCopyWithImpl<$Res> implements _$MenuItemCopyWith<$Res> {
  __$MenuItemCopyWithImpl(this._self, this._then);

  final _MenuItem _self;
  final $Res Function(_MenuItem) _then;

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? name = null,
    Object? price = null,
    Object? sku = freezed,
    Object? sortOrder = null,
    Object? isActive = null,
    Object? modifierGroupIds = null,
  }) {
    return _then(_MenuItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as Money,
      sku: freezed == sku
          ? _self.sku
          : sku // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      modifierGroupIds: null == modifierGroupIds
          ? _self._modifierGroupIds
          : modifierGroupIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
