import 'package:freezed_annotation/freezed_annotation.dart';

import '../src/money.dart';

part 'modifier.freezed.dart';

/// A group of choices offered with a menu item, e.g. "Size" (min 1, max 1)
/// or "Add-ons" (min 0, max many).
@freezed
abstract class ModifierGroup with _$ModifierGroup {
  const factory ModifierGroup({
    required String id,
    required String name,
    @Default(0) int minSelect,
    @Default(1) int maxSelect,

    /// Filled by the repository; not stored on the group row itself.
    @Default([]) List<Modifier> modifiers,
  }) = _ModifierGroup;
}

@freezed
abstract class Modifier with _$Modifier {
  const factory Modifier({
    required String id,
    required String groupId,
    required String name,
    @Default(Money.zero) Money priceDelta,
  }) = _Modifier;
}
