import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:win32/win32.dart';

/// Sends raw ESC/POS bytes to a printer installed in Windows, addressed by
/// name through the print spooler (`OpenPrinter` → `StartDocPrinter` RAW →
/// `WritePrinter`). This covers USB, serial and shared printers — anything
/// Windows lists — without needing the printer on the network.
///
/// Windows-only; off Windows every call returns a non-retryable error. This is
/// the only file allowed to talk to the spooler (docs/PRINCIPLES.md — hardware
/// abstraction).
class WindowsRawPrinterDriver implements domain.PrinterDriver {
  final String printerName;

  @override
  final domain.PrinterCapabilities capabilities;

  WindowsRawPrinterDriver({
    required this.printerName,
    required int paperWidthChars,
  }) : capabilities = domain.PrinterCapabilities(
         paperWidthChars: paperWidthChars,
         supportsCut: true,
         transport: domain.PrinterTransport.usb,
       );

  @override
  Future<domain.Result<void, domain.PrintError>> printJob(
    domain.PrintJobData job,
  ) async => _send(job.payload);

  @override
  Future<bool> testConnection() async {
    if (!Platform.isWindows) return false;
    final handle = _open();
    if (handle == null) return false;
    ClosePrinter(handle);
    return true;
  }

  // --- internals ---

  /// Opens the printer, returning its handle or null if it can't be opened.
  int? _open() {
    final name = printerName.toNativeUtf16(allocator: calloc);
    final phPrinter = calloc<HANDLE>();
    try {
      if (OpenPrinter(name, phPrinter, nullptr) == 0) return null;
      return phPrinter.value;
    } finally {
      calloc.free(name);
      calloc.free(phPrinter);
    }
  }

  domain.Result<void, domain.PrintError> _send(List<int> bytes) {
    if (!Platform.isWindows) {
      return const domain.Err(
        domain.PrintError(
          'Windows printer transport is only available on Windows',
          isRetryable: false,
        ),
      );
    }
    final handle = _open();
    if (handle == null) {
      return domain.Err(
        domain.PrintError('Cannot open Windows printer "$printerName"'),
      );
    }
    final docName = 'Receipt'.toNativeUtf16(allocator: calloc);
    final dataType = 'RAW'.toNativeUtf16(allocator: calloc);
    final docInfo = calloc<DOC_INFO_1>()
      ..ref.pDocName = docName
      ..ref.pOutputFile = nullptr
      ..ref.pDatatype = dataType;
    final buffer = calloc<Uint8>(bytes.length);
    final written = calloc<Uint32>();
    try {
      if (StartDocPrinter(handle, 1, docInfo.cast()) == 0) {
        return domain.Err(
          domain.PrintError('StartDocPrinter failed for "$printerName"'),
        );
      }
      if (StartPagePrinter(handle) == 0) {
        EndDocPrinter(handle);
        return domain.Err(
          domain.PrintError('StartPagePrinter failed for "$printerName"'),
        );
      }
      buffer.asTypedList(bytes.length).setAll(0, bytes);
      final ok = WritePrinter(handle, buffer.cast(), bytes.length, written);
      EndPagePrinter(handle);
      EndDocPrinter(handle);
      if (ok == 0 || written.value != bytes.length) {
        return domain.Err(
          domain.PrintError('WritePrinter failed for "$printerName"'),
        );
      }
      return const domain.Ok(null);
    } finally {
      ClosePrinter(handle);
      calloc.free(docName);
      calloc.free(dataType);
      calloc.free(docInfo);
      calloc.free(buffer);
      calloc.free(written);
    }
  }
}
