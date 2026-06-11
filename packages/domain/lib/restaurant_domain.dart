/// Shared domain package for the Restaurant System.
///
/// Pure Dart — no Flutter imports allowed in this package. Both the
/// merchant and customer apps depend on it.
library;

export 'ports/online_order_channel.dart';
export 'ports/payment_terminal.dart';
export 'ports/printer_driver.dart';
export 'ports/sync_backend.dart';
export 'src/ids.dart';
export 'src/money.dart';
export 'src/result.dart';
