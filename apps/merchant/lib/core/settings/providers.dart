import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../providers.dart';
import '../sync/providers.dart';
import 'settings_repository.dart';
import 'tables_repository.dart';

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

/// Both printer configs (kitchen + receipt), refreshed when either is saved.
class PrintersNotifier extends Notifier<Map<PrinterRole, PrinterConfig>> {
  @override
  Map<PrinterRole, PrinterConfig> build() {
    final r = ref.watch(settingsRepositoryProvider);
    return {for (final role in PrinterRole.values) role: r.printerConfig(role)};
  }

  Future<void> save(PrinterRole role, PrinterConfig config) async {
    await ref.read(settingsRepositoryProvider).setPrinterConfig(role, config);
    ref.invalidateSelf();
  }
}

final printersProvider =
    NotifierProvider<PrintersNotifier, Map<PrinterRole, PrinterConfig>>(
      PrintersNotifier.new,
    );

/// Whether a receipt can be printed — the receipt printer is configured, or
/// (fallback) the kitchen one is. Gates the reprint/auto-print actions.
final receiptPrinterReadyProvider = Provider<bool>((ref) {
  final printers = ref.watch(printersProvider);
  return printers[PrinterRole.receipt]!.isConfigured ||
      printers[PrinterRole.kitchen]!.isConfigured;
});

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

/// The chosen UI language. `null` means follow the system locale; the
/// merchant overrides it in Settings → Language. Persisted via
/// [SettingsRepository.appLocaleCode].
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.watch(settingsRepositoryProvider).appLocaleCode;
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale? locale) async {
    await ref
        .read(settingsRepositoryProvider)
        .setAppLocaleCode(locale?.languageCode);
    state = locale;
  }
}

final localePreferenceProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class NameDisplayNotifier extends Notifier<NameDisplay> {
  @override
  NameDisplay build() => ref.watch(settingsRepositoryProvider).nameDisplay;

  Future<void> save(NameDisplay value) async {
    await ref.read(settingsRepositoryProvider).setNameDisplay(value);
    state = value;
  }
}

final nameDisplayProvider = NotifierProvider<NameDisplayNotifier, NameDisplay>(
  NameDisplayNotifier.new,
);

/// The language the item second names are written in (e.g. 'zh'), or null. Sent
/// with the published menu so the customer app can surface the matching name.
class SecondNameLanguageNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(settingsRepositoryProvider).secondNameLanguage;

  Future<void> set(String? code) async {
    await ref.read(settingsRepositoryProvider).setSecondNameLanguage(code);
    ref.invalidateSelf();
  }
}

final secondNameLanguageProvider =
    NotifierProvider<SecondNameLanguageNotifier, String?>(
      SecondNameLanguageNotifier.new,
    );

/// Checkout pricing: a service fee charged on every order, and the discount
/// presets + the cap staff may discount without a manager.
class CheckoutPricing {
  final int serviceFeeBp;
  final List<int> discountPresetsBp;
  final int discountThresholdBp;

  const CheckoutPricing({
    required this.serviceFeeBp,
    required this.discountPresetsBp,
    required this.discountThresholdBp,
  });
}

class CheckoutPricingNotifier extends Notifier<CheckoutPricing> {
  @override
  CheckoutPricing build() {
    final r = ref.watch(settingsRepositoryProvider);
    return CheckoutPricing(
      serviceFeeBp: r.serviceFeeBp,
      discountPresetsBp: r.discountPresetsBp,
      discountThresholdBp: r.discountThresholdBp,
    );
  }

  Future<void> setServiceFeeBp(int bp) async {
    await ref.read(settingsRepositoryProvider).setServiceFeeBp(bp);
    ref.invalidateSelf();
  }

  Future<void> setDiscountPresetsBp(List<int> presets) async {
    await ref.read(settingsRepositoryProvider).setDiscountPresetsBp(presets);
    ref.invalidateSelf();
  }

  Future<void> setDiscountThresholdBp(int bp) async {
    await ref.read(settingsRepositoryProvider).setDiscountThresholdBp(bp);
    ref.invalidateSelf();
  }
}

final checkoutPricingProvider =
    NotifierProvider<CheckoutPricingNotifier, CheckoutPricing>(
      CheckoutPricingNotifier.new,
    );

/// Online-ordering preferences: how soon a pickup can be requested, and
/// whether to chime when a new order lands.
class OnlineOrderSettings {
  final int pickupLeadMinutes;
  final bool newOrderSound;

  const OnlineOrderSettings({
    required this.pickupLeadMinutes,
    required this.newOrderSound,
  });
}

class OnlineOrderSettingsNotifier extends Notifier<OnlineOrderSettings> {
  @override
  OnlineOrderSettings build() {
    final r = ref.watch(settingsRepositoryProvider);
    return OnlineOrderSettings(
      pickupLeadMinutes: r.pickupLeadMinutes,
      newOrderSound: r.newOrderSound,
    );
  }

  Future<void> setPickupLead(int minutes) async {
    await ref.read(settingsRepositoryProvider).setPickupLeadMinutes(minutes);
    ref.invalidateSelf();
  }

  Future<void> setNewOrderSound(bool on) async {
    await ref.read(settingsRepositoryProvider).setNewOrderSound(on);
    ref.invalidateSelf();
  }
}

final onlineOrderSettingsProvider =
    NotifierProvider<OnlineOrderSettingsNotifier, OnlineOrderSettings>(
      OnlineOrderSettingsNotifier.new,
    );
