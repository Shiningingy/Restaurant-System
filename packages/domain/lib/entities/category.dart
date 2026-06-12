import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
  }) = _Category;
}
