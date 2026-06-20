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
}
