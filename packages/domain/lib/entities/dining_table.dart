import 'package:freezed_annotation/freezed_annotation.dart';

part 'dining_table.freezed.dart';

@freezed
abstract class DiningTable with _$DiningTable {
  const factory DiningTable({
    required String id,
    required String label,
    @Default(true) bool isActive,
  }) = _DiningTable;
}
