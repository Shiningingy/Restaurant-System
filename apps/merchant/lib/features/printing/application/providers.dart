import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import '../../../core/providers.dart';
import '../../orders/application/providers.dart';
import '../../payments/application/providers.dart';
import '../../../core/settings/providers.dart';
import '../../../core/settings/settings_repository.dart';
import '../data/print_job_repository.dart';
import '../drivers/escpos_network_driver.dart';
import '../drivers/windows_raw_printer_driver.dart';
import 'print_service.dart';

/// Builds the driver for a printer config, or null when it isn't configured /
/// not supported on this platform.
domain.PrinterDriver? driverFor(PrinterConfig cfg) {
  if (!cfg.isConfigured) return null;
  switch (cfg.transport) {
    case domain.PrinterTransport.network:
      return EscPosNetworkDriver(
        host: cfg.host!,
        port: cfg.port,
        paperWidthChars: cfg.paperWidthChars,
      );
    case domain.PrinterTransport.usb:
      if (!Platform.isWindows) return null;
      return WindowsRawPrinterDriver(
        printerName: cfg.windowsPrinterName!,
        paperWidthChars: cfg.paperWidthChars,
      );
    case domain.PrinterTransport.bluetooth:
      return null;
  }
}

final printJobRepositoryProvider = Provider<PrintJobRepository>(
  (ref) => PrintJobRepository(ref.watch(databaseProvider)),
);

final printServiceProvider = Provider<PrintService>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return PrintService(
    jobs: ref.watch(printJobRepositoryProvider),
    orders: ref.watch(orderRepositoryProvider),
    payments: ref.watch(paymentRepositoryProvider),
    tables: ref.watch(tablesRepositoryProvider),
    settings: settings,
    // Read settings at print time, so a config change applies immediately.
    // Each job goes to its destination printer (kitchen vs receipt).
    buildDriver: (kind) => driverFor(settings.printerFor(kind)),
  );
});

/// Recent print jobs for the Settings queue view.
final printJobsProvider = StreamProvider<List<PrintJobRow>>(
  (ref) => ref.watch(printJobRepositoryProvider).watchRecent(),
);
