import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../../sync/application/providers.dart';
import '../data/settings_repository.dart';
import '../data/tables_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final tablesRepositoryProvider = Provider<TablesRepository>(
  (ref) => TablesRepository(
    ref.watch(databaseProvider),
    journal: ref.watch(syncJournalProvider),
  ),
);

final tablesProvider = StreamProvider<List<domain.DiningTable>>(
  (ref) => ref.watch(tablesRepositoryProvider).watchTables(),
);

class PrinterSettingsNotifier extends Notifier<PrinterSettings> {
  @override
  PrinterSettings build() => ref.watch(settingsRepositoryProvider).printer;

  Future<void> save(PrinterSettings settings) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setPrinter(settings);
    state = repo.printer;
  }
}

final printerSettingsProvider =
    NotifierProvider<PrinterSettingsNotifier, PrinterSettings>(
      PrinterSettingsNotifier.new,
    );

class ReceiptConfigNotifier extends Notifier<domain.ReceiptConfig> {
  @override
  domain.ReceiptConfig build() =>
      ref.watch(settingsRepositoryProvider).receiptConfig;

  Future<void> setBusinessName(String name) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setBusinessName(name);
    state = repo.receiptConfig;
  }

  Future<void> setFooter(String footer) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setReceiptFooter(footer);
    state = repo.receiptConfig;
  }
}

final receiptConfigProvider =
    NotifierProvider<ReceiptConfigNotifier, domain.ReceiptConfig>(
      ReceiptConfigNotifier.new,
    );

class TaxRateNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(settingsRepositoryProvider).taxRateBp;

  Future<void> setBp(int bp) async {
    await ref.read(settingsRepositoryProvider).setTaxRateBp(bp);
    state = bp;
  }
}

final taxRateBpProvider = NotifierProvider<TaxRateNotifier, int>(
  TaxRateNotifier.new,
);
