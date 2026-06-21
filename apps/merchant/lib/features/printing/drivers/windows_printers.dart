import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Lists the printers installed in Windows (local + connected) so the settings
/// UI can offer them in a dropdown. Returns an empty list off Windows.
class WindowsPrinters {
  static List<String> list() {
    if (!Platform.isWindows) return const [];
    const level =
        4; // PRINTER_INFO_4 — name + server + attributes (lightweight)
    const flags = PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS;
    final pcbNeeded = calloc<Uint32>();
    final pcReturned = calloc<Uint32>();
    try {
      // First call sizes the buffer; it "fails" with the needed byte count.
      EnumPrinters(flags, nullptr, level, nullptr, 0, pcbNeeded, pcReturned);
      final cb = pcbNeeded.value;
      if (cb == 0) return const [];
      final buffer = calloc<Uint8>(cb);
      try {
        final ok = EnumPrinters(
          flags,
          nullptr,
          level,
          buffer,
          cb,
          pcbNeeded,
          pcReturned,
        );
        if (ok == 0) return const [];
        final count = pcReturned.value;
        final base = buffer.cast<PRINTER_INFO_4>();
        final names = <String>[];
        for (var i = 0; i < count; i++) {
          final name = (base + i).ref.pPrinterName;
          if (name != nullptr) names.add(name.toDartString());
        }
        return names;
      } finally {
        calloc.free(buffer);
      }
    } finally {
      calloc.free(pcbNeeded);
      calloc.free(pcReturned);
    }
  }
}
