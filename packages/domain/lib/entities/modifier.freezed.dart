// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'modifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModifierGroup {
  String get id;
  String get name;
  int get minSelect;
  int get maxSelect;

  /// Filled by the repository; not stored on the group row itself.
  List<Modifier> get modifiers;

  /// Create a copy of ModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ModifierGroupCopyWith<ModifierGroup> get copyWith =>
      _$ModifierGroupCopyWithImpl<ModifierGroup>(
          this as ModifierGroup, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ModifierGroup &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.minSelect, minSelect) ||
                other.minSelect == minSelect) &&
            (identical(other.maxSelect, maxSelect) ||
                other.maxSelect == maxSelect) &&
            const DeepCollectionEquality().equals(other.modifiers, modifiers));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, minSelect, maxSelect,
      const DeepCollectionEquality().hash(modifiers));

  @override
  String toString() {
    return 'ModifierGroup(id: $id, name: $name, minSelect: $minSelect, maxSelect: $maxSelect, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $ModifierGroupCopyWith<$Res> {
  factory $ModifierGroupCopyWith(
          ModifierGroup value, $Res Function(ModifierGroup) _then) =
      _$ModifierGroupCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      int minSelect,
      int maxSelect,
      List<Modifier> modifiers});
}

/// @nodoc
class _$ModifierGroupCopyWithImpl<$Res>
    implements $ModifierGroupCopyWith<$Res> {
  _$ModifierGroupCopyWithImpl(this._self, this._then);

  final ModifierGroup _self;
  final $Res Function(ModifierGroup) _then;

  /// Create a copy of ModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? minSelect = null,
    Object? maxSelect = null,
    Object? modifiers = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      minSelect: null == minSelect
          ? _self.minSelect
          : minSelect // ignore: cast_nullable_to_non_nullable
              as int,
      maxSelect: null == maxSelect
          ? _self.maxSelect
          : maxSelect // ignore: cast_nullable_to_non_nullable
              as int,
      modifiers: null == modifiers
          ? _self.modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }
}

/// Adds pattern-matching-related methods to [ModifierGroup].
extension ModifierGroupPatterns on ModifierGroup {
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
    TResult Function(_ModifierGroup value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ModifierGroup() when $default != null:
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
    TResult Function(_ModifierGroup value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ModifierGroup():
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
    TResult? Function(_ModifierGroup value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ModifierGroup() when $default != null:
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
    TResult Function(String id, String name, int minSelect, int maxSelect,
            List<Modifier> modifiers)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ModifierGroup() when $default != null:
        return $default(_that.id, _that.name, _that.minSelect, _that.maxSelect,
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
    TResult Function(String id, String name, int minSelect, int maxSelect,
            List<Modifier> modifiers)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ModifierGroup():
        return $default(_that.id, _that.name, _that.minSelect, _that.maxSelect,
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
    TResult? Function(String id, String name, int minSelect, int maxSelect,
            List<Modifier> modifiers)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ModifierGroup() when $default != null:
        return $default(_that.id, _that.name, _that.minSelect, _that.maxSelect,
            _that.modifiers);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ModifierGroup implements ModifierGroup {
  const _ModifierGroup(
      {required this.id,
      required this.name,
      this.minSelect = 0,
      this.maxSelect = 1,
      final List<Modifier> modifiers = const []})
      : _modifiers = modifiers;

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final int minSelect;
  @override
  @JsonKey()
  final int maxSelect;

  /// Filled by the repository; not stored on the group row itself.
  final List<Modifier> _modifiers;

  /// Filled by the repository; not stored on the group row itself.
  @override
  @JsonKey()
  List<Modifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  /// Create a copy of ModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ModifierGroupCopyWith<_ModifierGroup> get copyWith =>
      __$ModifierGroupCopyWithImpl<_ModifierGroup>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ModifierGroup &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.minSelect, minSelect) ||
                other.minSelect == minSelect) &&
            (identical(other.maxSelect, maxSelect) ||
                other.maxSelect == maxSelect) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, minSelect, maxSelect,
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString() {
    return 'ModifierGroup(id: $id, name: $name, minSelect: $minSelect, maxSelect: $maxSelect, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class _$ModifierGroupCopyWith<$Res>
    implements $ModifierGroupCopyWith<$Res> {
  factory _$ModifierGroupCopyWith(
          _ModifierGroup value, $Res Function(_ModifierGroup) _then) =
      __$ModifierGroupCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int minSelect,
      int maxSelect,
      List<Modifier> modifiers});
}

/// @nodoc
class __$ModifierGroupCopyWithImpl<$Res>
    implements _$ModifierGroupCopyWith<$Res> {
  __$ModifierGroupCopyWithImpl(this._self, this._then);

  final _ModifierGroup _self;
  final $Res Function(_ModifierGroup) _then;

  /// Create a copy of ModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? minSelect = null,
    Object? maxSelect = null,
    Object? modifiers = null,
  }) {
    return _then(_ModifierGroup(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      minSelect: null == minSelect
          ? _self.minSelect
          : minSelect // ignore: cast_nullable_to_non_nullable
              as int,
      maxSelect: null == maxSelect
          ? _self.maxSelect
          : maxSelect // ignore: cast_nullable_to_non_nullable
              as int,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }
}

/// @nodoc
mixin _$Modifier {
  String get id;
  String get groupId;
  String get name;
  Money get priceDelta;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ModifierCopyWith<Modifier> get copyWith =>
      _$ModifierCopyWithImpl<Modifier>(this as Modifier, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Modifier &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.priceDelta, priceDelta) ||
                other.priceDelta == priceDelta));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, groupId, name, priceDelta);

  @override
  String toString() {
    return 'Modifier(id: $id, groupId: $groupId, name: $name, priceDelta: $priceDelta)';
  }
}

/// @nodoc
abstract mixin class $ModifierCopyWith<$Res> {
  factory $ModifierCopyWith(Modifier value, $Res Function(Modifier) _then) =
      _$ModifierCopyWithImpl;
  @useResult
  $Res call({String id, String groupId, String name, Money priceDelta});
}

/// @nodoc
class _$ModifierCopyWithImpl<$Res> implements $ModifierCopyWith<$Res> {
  _$ModifierCopyWithImpl(this._self, this._then);

  final Modifier _self;
  final $Res Function(Modifier) _then;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? name = null,
    Object? priceDelta = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      priceDelta: null == priceDelta
          ? _self.priceDelta
          : priceDelta // ignore: cast_nullable_to_non_nullable
              as Money,
    ));
  }
}

/// Adds pattern-matching-related methods to [Modifier].
extension ModifierPatterns on Modifier {
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
    TResult Function(_Modifier value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Modifier() when $default != null:
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
    TResult Function(_Modifier value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Modifier():
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
    TResult? Function(_Modifier value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Modifier() when $default != null:
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
    TResult Function(String id, String groupId, String name, Money priceDelta)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Modifier() when $default != null:
        return $default(_that.id, _that.groupId, _that.name, _that.priceDelta);
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
    TResult Function(String id, String groupId, String name, Money priceDelta)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Modifier():
        return $default(_that.id, _that.groupId, _that.name, _that.priceDelta);
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
    TResult? Function(String id, String groupId, String name, Money priceDelta)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Modifier() when $default != null:
        return $default(_that.id, _that.groupId, _that.name, _that.priceDelta);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Modifier implements Modifier {
  const _Modifier(
      {required this.id,
      required this.groupId,
      required this.name,
      this.priceDelta = Money.zero});

  @override
  final String id;
  @override
  final String groupId;
  @override
  final String name;
  @override
  @JsonKey()
  final Money priceDelta;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ModifierCopyWith<_Modifier> get copyWith =>
      __$ModifierCopyWithImpl<_Modifier>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Modifier &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.priceDelta, priceDelta) ||
                other.priceDelta == priceDelta));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, groupId, name, priceDelta);

  @override
  String toString() {
    return 'Modifier(id: $id, groupId: $groupId, name: $name, priceDelta: $priceDelta)';
  }
}

/// @nodoc
abstract mixin class _$ModifierCopyWith<$Res>
    implements $ModifierCopyWith<$Res> {
  factory _$ModifierCopyWith(_Modifier value, $Res Function(_Modifier) _then) =
      __$ModifierCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String groupId, String name, Money priceDelta});
}

/// @nodoc
class __$ModifierCopyWithImpl<$Res> implements _$ModifierCopyWith<$Res> {
  __$ModifierCopyWithImpl(this._self, this._then);

  final _Modifier _self;
  final $Res Function(_Modifier) _then;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? name = null,
    Object? priceDelta = null,
  }) {
    return _then(_Modifier(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      priceDelta: null == priceDelta
          ? _self.priceDelta
          : priceDelta // ignore: cast_nullable_to_non_nullable
              as Money,
    ));
  }
}

// dart format on
