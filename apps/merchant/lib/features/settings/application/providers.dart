import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../data/settings_repository.dart';
import '../data/tables_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final tablesRepositoryProvider = Provider<TablesRepository>(
  (ref) => TablesRepository(ref.watch(databaseProvider)),
);

final tablesProvider = StreamProvider<List<domain.DiningTable>>(
  (ref) => ref.watch(tablesRepositoryProvider).watchTables(),
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
