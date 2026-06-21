import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

/// Network printer configuration; null [host] means no printer set up.
class PrinterSettings {
  final String? host;
  final int port;

  /// Characters per line: 48 for 80mm paper, 32 for 58mm.
  final int paperWidthChars;

  const PrinterSettings({
    required this.host,
    required this.port,
    required this.paperWidthChars,
  });

  bool get isConfigured => host != null && host!.isNotEmpty;
}

/// Where the optional bilingual second name is shown. Defaults match the
/// original behaviour: on the order screen and kitchen ticket, not the receipt.
class NameDisplay {
  final bool orderScreen;
  final bool kitchenTicket;
  final bool receipt;

  const NameDisplay({
    this.orderScreen = true,
    this.kitchenTicket = true,
    this.receipt = false,
  });

  NameDisplay copyWith({
    bool? orderScreen,
    bool? kitchenTicket,
    bool? receipt,
  }) => NameDisplay(
    orderScreen: orderScreen ?? this.orderScreen,
    kitchenTicket: kitchenTicket ?? this.kitchenTicket,
    receipt: receipt ?? this.receipt,
  );
}

/// App settings stored in shared_preferences. Orders snapshot the tax
/// rate at creation, so changing it here never rewrites history.
class SettingsRepository {
  static const _taxRateBpKey = 'taxRateBp';
  static const _printerHostKey = 'printerHost';
  static const _printerPortKey = 'printerPort';
  static const _paperWidthKey = 'paperWidthChars';
  static const _businessNameKey = 'businessName';
  static const _receiptFooterKey = 'receiptFooter';
  static const _appLocaleKey = 'appLocale';
  static const _secondNameOrderKey = 'secondNameOrderScreen';
  static const _secondNameKitchenKey = 'secondNameKitchen';
  static const _secondNameReceiptKey = 'secondNameReceipt';
  static const _pickupLeadKey = 'pickupLeadMinutes';
  static const _newOrderSoundKey = 'newOrderSound';
  static const _secondNameLangKey = 'secondNameLanguage';
  static const _serviceFeeBpKey = 'serviceFeeBp';
  static const _discountPresetsKey = 'discountPresetsBp';
  static const _discountThresholdKey = 'discountThresholdBp';
  static const _helpSeenKey = 'helpSeen';

  /// Staff may apply a manual discount up to this without a manager — 15%.
  static const defaultDiscountThresholdBp = 1500;

  /// 13% HST (Ontario) as the default — the user configures their own rate.
  static const defaultTaxRateBp = 1300;
  static const defaultPrinterPort = 9100;

  /// Soonest a customer can ask to pick up, measured from order time. The
  /// customer app enforces this when choosing a pickup time (it's published
  /// with the menu); 15 minutes is a sane default for a small kitchen.
  static const defaultPickupLeadMinutes = 15;

  final SharedPreferences prefs;

  SettingsRepository(this.prefs);

  int get taxRateBp => prefs.getInt(_taxRateBpKey) ?? defaultTaxRateBp;

  Future<void> setTaxRateBp(int bp) => prefs.setInt(_taxRateBpKey, bp);

  PrinterSettings get printer => PrinterSettings(
    host: prefs.getString(_printerHostKey),
    port: prefs.getInt(_printerPortKey) ?? defaultPrinterPort,
    paperWidthChars: prefs.getInt(_paperWidthKey) ?? domain.EscPos.width80mm,
  );

  Future<void> setPrinter(PrinterSettings settings) async {
    final host = settings.host;
    if (host == null || host.isEmpty) {
      await prefs.remove(_printerHostKey);
    } else {
      await prefs.setString(_printerHostKey, host);
    }
    await prefs.setInt(_printerPortKey, settings.port);
    await prefs.setInt(_paperWidthKey, settings.paperWidthChars);
  }

  /// Restaurant identity printed on customer receipts.
  domain.ReceiptConfig get receiptConfig => domain.ReceiptConfig(
    businessName: prefs.getString(_businessNameKey) ?? 'My Restaurant',
    footer: prefs.getString(_receiptFooterKey) ?? 'Thank you!',
  );

  Future<void> setBusinessName(String name) =>
      prefs.setString(_businessNameKey, name);

  Future<void> setReceiptFooter(String footer) =>
      prefs.setString(_receiptFooterKey, footer);

  /// Preferred UI language code ('en' / 'zh'), or null to follow the system
  /// locale.
  String? get appLocaleCode => prefs.getString(_appLocaleKey);

  Future<void> setAppLocaleCode(String? code) => code == null
      ? prefs.remove(_appLocaleKey)
      : prefs.setString(_appLocaleKey, code);

  /// Per-surface visibility of the bilingual second name.
  NameDisplay get nameDisplay => NameDisplay(
    orderScreen: prefs.getBool(_secondNameOrderKey) ?? true,
    kitchenTicket: prefs.getBool(_secondNameKitchenKey) ?? true,
    receipt: prefs.getBool(_secondNameReceiptKey) ?? false,
  );

  Future<void> setNameDisplay(NameDisplay value) async {
    await prefs.setBool(_secondNameOrderKey, value.orderScreen);
    await prefs.setBool(_secondNameKitchenKey, value.kitchenTicket);
    await prefs.setBool(_secondNameReceiptKey, value.receipt);
  }

  /// Minimum lead time (minutes) before a requested pickup. Published with
  /// the menu so the customer app can't ask for an impossible time.
  int get pickupLeadMinutes =>
      prefs.getInt(_pickupLeadKey) ?? defaultPickupLeadMinutes;

  Future<void> setPickupLeadMinutes(int minutes) =>
      prefs.setInt(_pickupLeadKey, minutes);

  /// Whether to play an alert sound when a new online order arrives.
  bool get newOrderSound => prefs.getBool(_newOrderSoundKey) ?? true;

  Future<void> setNewOrderSound(bool on) =>
      prefs.setBool(_newOrderSoundKey, on);

  /// The language code the item second names are written in (e.g. 'zh'), or
  /// null/empty if not set. Published so the customer app can surface the
  /// second name as the primary line when its language matches.
  String? get secondNameLanguage => prefs.getString(_secondNameLangKey);

  Future<void> setSecondNameLanguage(String? code) =>
      (code == null || code.isEmpty)
      ? prefs.remove(_secondNameLangKey)
      : prefs.setString(_secondNameLangKey, code);

  /// Service-fee rate in basis points charged on every order (0 = none).
  int get serviceFeeBp => prefs.getInt(_serviceFeeBpKey) ?? 0;

  Future<void> setServiceFeeBp(int bp) => prefs.setInt(_serviceFeeBpKey, bp);

  /// Preset discount percentages (basis points) offered at checkout, e.g.
  /// [500, 1000, 1500]. Set by a manager+.
  List<int> get discountPresetsBp =>
      (prefs.getStringList(_discountPresetsKey) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toList();

  Future<void> setDiscountPresetsBp(List<int> presets) => prefs.setStringList(
    _discountPresetsKey,
    presets.map((e) => e.toString()).toList(),
  );

  /// The most a manual discount can be (basis points) before it needs a
  /// manager's approval. Set by a manager+.
  int get discountThresholdBp =>
      prefs.getInt(_discountThresholdKey) ?? defaultDiscountThresholdBp;

  Future<void> setDiscountThresholdBp(int bp) =>
      prefs.setInt(_discountThresholdKey, bp);

  /// Whether the first-run welcome (pointing to the user guide) has been shown.
  bool get helpSeen => prefs.getBool(_helpSeenKey) ?? false;

  Future<void> setHelpSeen(bool seen) => prefs.setBool(_helpSeenKey, seen);
}
