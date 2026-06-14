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

  /// Optional human item number (e.g. "A01") for ordering "by number".
  /// Distinct from [sortOrder], which is the internal display order.
  String? get code;

  /// Optional second name line (e.g. a native-language name), shown stacked
  /// under [name]. Language-agnostic — both lines always show together.
  String? get nameSecondary;
  String? get sku;
  int get sortOrder;
  bool get isActive;

  /// Ids of the modifier groups offered with this item
  /// (filled by the repository from the join table).
  List<String> get modifierGroupIds;

  /// User-defined renamable text fields (filled by the repository).
  List<MenuItemAttribute> get attributes;

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
            (identical(other.code, code) || other.code == code) &&
            (identical(other.nameSecondary, nameSecondary) ||
                other.nameSecondary == nameSecondary) &&
            (identical(other.sku, sku) || other.sku == sku) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality()
                .equals(other.modifierGroupIds, modifierGroupIds) &&
            const DeepCollectionEquality()
                .equals(other.attributes, attributes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      categoryId,
      name,
      price,
      code,
      nameSecondary,
      sku,
      sortOrder,
      isActive,
      const DeepCollectionEquality().hash(modifierGroupIds),
      const DeepCollectionEquality().hash(attributes));

  @override
  String toString() {
    return 'MenuItem(id: $id, categoryId: $categoryId, name: $name, price: $price, code: $code, nameSecondary: $nameSecondary, sku: $sku, sortOrder: $sortOrder, isActive: $isActive, modifierGroupIds: $modifierGroupIds, attributes: $attributes)';
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
      String? code,
      String? nameSecondary,
      String? sku,
      int sortOrder,
      bool isActive,
      List<String> modifierGroupIds,
      List<MenuItemAttribute> attributes});
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
    Object? code = freezed,
    Object? nameSecondary = freezed,
    Object? sku = freezed,
    Object? sortOrder = null,
    Object? isActive = null,
    Object? modifierGroupIds = null,
    Object? attributes = null,
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
      code: freezed == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      nameSecondary: freezed == nameSecondary
          ? _self.nameSecondary
          : nameSecondary // ignore: cast_nullable_to_non_nullable
              as String?,
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
      attributes: null == attributes
          ? _self.attributes
          : attributes // ignore: cast_nullable_to_non_nullable
              as List<MenuItemAttribute>,
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
            String? code,
            String? nameSecondary,
            String? sku,
            int sortOrder,
            bool isActive,
            List<String> modifierGroupIds,
            List<MenuItemAttribute> attributes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MenuItem() when $default != null:
        return $default(
            _that.id,
            _that.categoryId,
            _that.name,
            _that.price,
            _that.code,
            _that.nameSecondary,
            _that.sku,
            _that.sortOrder,
            _that.isActive,
            _that.modifierGroupIds,
            _that.attributes);
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
            String? code,
            String? nameSecondary,
            String? sku,
            int sortOrder,
            bool isActive,
            List<String> modifierGroupIds,
            List<MenuItemAttribute> attributes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItem():
        return $default(
            _that.id,
            _that.categoryId,
            _that.name,
            _that.price,
            _that.code,
            _that.nameSecondary,
            _that.sku,
            _that.sortOrder,
            _that.isActive,
            _that.modifierGroupIds,
            _that.attributes);
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
            String? code,
            String? nameSecondary,
            String? sku,
            int sortOrder,
            bool isActive,
            List<String> modifierGroupIds,
            List<MenuItemAttribute> attributes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MenuItem() when $default != null:
        return $default(
            _that.id,
            _that.categoryId,
            _that.name,
            _that.price,
            _that.code,
            _that.nameSecondary,
            _that.sku,
            _that.sortOrder,
            _that.isActive,
            _that.modifierGroupIds,
            _that.attributes);
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
      this.code,
      this.nameSecondary,
      this.sku,
      this.sortOrder = 0,
      this.isActive = true,
      final List<String> modifierGroupIds = const [],
      final List<MenuItemAttribute> attributes = const []})
      : _modifierGroupIds = modifierGroupIds,
        _attributes = attributes;

  @override
  final String id;
  @override
  final String categoryId;
  @override
  final String name;
  @override
  final Money price;

  /// Optional human item number (e.g. "A01") for ordering "by number".
  /// Distinct from [sortOrder], which is the internal display order.
  @override
  final String? code;

  /// Optional second name line (e.g. a native-language name), shown stacked
  /// under [name]. Language-agnostic — both lines always show together.
  @override
  final String? nameSecondary;
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

  /// User-defined renamable text fields (filled by the repository).
  final List<MenuItemAttribute> _attributes;

  /// User-defined renamable text fields (filled by the repository).
  @override
  @JsonKey()
  List<MenuItemAttribute> get attributes {
    if (_attributes is EqualUnmodifiableListView) return _attributes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attributes);
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
            (identical(other.code, code) || other.code == code) &&
            (identical(other.nameSecondary, nameSecondary) ||
                other.nameSecondary == nameSecondary) &&
            (identical(other.sku, sku) || other.sku == sku) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality()
                .equals(other._modifierGroupIds, _modifierGroupIds) &&
            const DeepCollectionEquality()
                .equals(other._attributes, _attributes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      categoryId,
      name,
      price,
      code,
      nameSecondary,
      sku,
      sortOrder,
      isActive,
      const DeepCollectionEquality().hash(_modifierGroupIds),
      const DeepCollectionEquality().hash(_attributes));

  @override
  String toString() {
    return 'MenuItem(id: $id, categoryId: $categoryId, name: $name, price: $price, code: $code, nameSecondary: $nameSecondary, sku: $sku, sortOrder: $sortOrder, isActive: $isActive, modifierGroupIds: $modifierGroupIds, attributes: $attributes)';
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
      String? code,
      String? nameSecondary,
      String? sku,
      int sortOrder,
      bool isActive,
      List<String> modifierGroupIds,
      List<MenuItemAttribute> attributes});
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
    Object? code = freezed,
    Object? nameSecondary = freezed,
    Object? sku = freezed,
    Object? sortOrder = null,
    Object? isActive = null,
    Object? modifierGroupIds = null,
    Object? attributes = null,
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
      code: freezed == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      nameSecondary: freezed == nameSecondary
          ? _self.nameSecondary
          : nameSecondary // ignore: cast_nullable_to_non_nullable
              as String?,
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
      attributes: null == attributes
          ? _self._attributes
          : attributes // ignore: cast_nullable_to_non_nullable
              as List<MenuItemAttribute>,
    ));
  }
}

// dart format on
