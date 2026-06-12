/// Shared domain package for the Restaurant System.
///
/// Pure Dart — no Flutter imports allowed in this package. Both the
/// merchant and customer apps depend on it.
library;

export 'entities/category.dart';
export 'entities/dining_table.dart';
export 'entities/menu_item.dart';
export 'entities/modifier.dart';
export 'entities/order.dart';
export 'entities/payment.dart';
export 'ports/online_order_channel.dart';
export 'ports/payment_terminal.dart';
export 'ports/printer_driver.dart';
export 'ports/sync_backend.dart';
export 'src/ids.dart';
export 'src/money.dart';
export 'src/order_totals.dart';
export 'src/result.dart';
