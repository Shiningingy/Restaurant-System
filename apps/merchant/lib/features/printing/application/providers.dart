import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/providers.dart';
import '../../orders/application/providers.dart';
import '../../settings/application/providers.dart';
import '../data/print_job_repository.dart';
import '../drivers/escpos_network_driver.dart';
import 'print_service.dart';

final printJobRepositoryProvider = Provider<PrintJobRepository>(
  (ref) => PrintJobRepository(ref.watch(databaseProvider)),
);

final printServiceProvider = Provider<PrintService>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return PrintService(
    jobs: ref.watch(printJobRepositoryProvider),
    orders: ref.watch(orderRepositoryProvider),
    tables: ref.watch(tablesRepositoryProvider),
    settings: settings,
    // Read settings at print time, so a config change applies immediately.
    buildDriver: () {
      final printer = settings.printer;
      final host = printer.host;
      if (host == null || host.isEmpty) return null;
      return EscPosNetworkDriver(
        host: host,
        port: printer.port,
        paperWidthChars: printer.paperWidthChars,
      );
    },
  );
});

/// Recent print jobs for the Settings queue view.
final printJobsProvider = StreamProvider<List<PrintJobRow>>(
  (ref) => ref.watch(printJobRepositoryProvider).watchRecent(),
);
