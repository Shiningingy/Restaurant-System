import '../src/result.dart';

/// What kind of document a print job produces.
enum PrintJobKind { customerReceipt, kitchenTicket, testPage }

/// Lifecycle of a queued print job (persisted in the merchant app's
/// print_jobs table). `queued` and `failed` jobs survive restarts;
/// failed jobs can be retried from the UI.
enum PrintJobStatus { queued, printing, done, failed }

/// A queued print job. The payload is the already-rendered ESC/POS byte
/// stream; rendering (templates) is a separate concern from transport.
class PrintJobData {
  final String id;
  final PrintJobKind kind;
  final List<int> payload;
  final String? orderId;

  const PrintJobData({
    required this.id,
    required this.kind,
    required this.payload,
    this.orderId,
  });
}

enum PrinterTransport { bluetooth, network, usb }

class PrinterCapabilities {
  /// Paper width in characters (typically 32 for 58mm, 48 for 80mm).
  final int paperWidthChars;
  final bool supportsCut;
  final PrinterTransport transport;

  const PrinterCapabilities({
    required this.paperWidthChars,
    required this.supportsCut,
    required this.transport,
  });
}

class PrintError {
  final String message;
  final bool isRetryable;

  const PrintError(this.message, {this.isRetryable = true});

  @override
  String toString() => 'PrintError($message, retryable: $isRetryable)';
}

/// Hardware abstraction for receipt printers.
///
/// Implementations live under `apps/merchant/lib/features/printing/drivers/`
/// and are the ONLY place printer SDK packages may be imported
/// (see docs/PRINCIPLES.md — hardware abstraction).
///
/// Planned implementations:
///  - EscPosNetworkDriver  (LAN/TCP 9100 — works on all platforms)
///  - EscPosBluetoothDriver (iOS/Android only)
abstract interface class PrinterDriver {
  PrinterCapabilities get capabilities;

  Future<Result<void, PrintError>> printJob(PrintJobData job);

  Future<bool> testConnection();
}
