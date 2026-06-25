import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:shared_preferences/shared_preferences.dart';

/// The two printer roles a shop can configure independently. A kitchen ticket
/// goes to [kitchen]; a customer receipt (and the cash-drawer kick) to
/// [receipt]. A one-printer shop configures just one and the other falls back.
enum PrinterRole { kitchen, receipt }

/// How the customer-facing second screen behaves.
/// - [passive]: mirrors the order being rung up; rotating promo when idle.
/// - [kiosk]: a dedicated self-order kiosk (customers order themselves).
/// - [hybrid]: promo + a "tap to order" affordance when idle, but mirrors the
///   cashier's order while one is active (one screen serving both purposes).
enum CustomerDisplayMode { passive, kiosk, hybrid }

/// The brand-logo slots: a [global] default plus one per place a logo appears.
/// Each is an optional image; a placement with none falls back to [global]
/// (and [global] itself falls back to the generic glyph). So a shop can set a
/// single default and be done, or give any individual spot its own logo.
enum BrandLogoSlot {
  /// The default logo, used wherever a placement has none of its own.
  global,

  /// Merchant app navigation rail.
  appNav,

  /// Customer display — the idle/welcome screen.
  displayWelcome,

  /// Customer display — the live order header (terracotta).
  displayOrderHeader,

  /// Kiosk — the header (terracotta).
  kioskHeader,

  /// Kiosk — the order-confirmation screen.
  kioskConfirm,
}

/// Configuration for one printer. Transport is either a network printer
/// (`network`, host:port over TCP 9100) or a Windows-installed printer
/// (`usb`, addressed by name through the print spooler — covers USB, serial
/// and shared printers on Windows).
class PrinterConfig {
  final domain.PrinterTransport transport;

  /// Network transport.
  final String? host;
  final int port;

  /// Windows-printer transport — the installed printer's name.
  final String? windowsPrinterName;

  /// Characters per line: 48 for 80mm paper, 32 for 58mm.
  final int paperWidthChars;

  /// Text encoding for this printer (Western ASCII vs Chinese/GBK).
  final domain.TicketCharset charset;

  /// Receipt role only: pulse the cash drawer after printing a receipt.
  final bool openDrawer;

  const PrinterConfig({
    this.transport = domain.PrinterTransport.network,
    this.host,
    this.port = SettingsRepository.defaultPrinterPort,
    this.windowsPrinterName,
    this.paperWidthChars = domain.EscPos.width80mm,
    // Auto by default: the app sends Chinese (GBK) only when a ticket contains
    // CJK, so the owner never has to pick an encoder.
    this.charset = domain.TicketCharset.auto,
    this.openDrawer = false,
  });

  bool get isConfigured => transport == domain.PrinterTransport.network
      ? host != null && host!.isNotEmpty
      : windowsPrinterName != null && windowsPrinterName!.isNotEmpty;

  PrinterConfig copyWith({
    domain.PrinterTransport? transport,
    String? host,
    int? port,
    String? windowsPrinterName,
    int? paperWidthChars,
    domain.TicketCharset? charset,
    bool? openDrawer,
  }) => PrinterConfig(
    transport: transport ?? this.transport,
    host: host ?? this.host,
    port: port ?? this.port,
    windowsPrinterName: windowsPrinterName ?? this.windowsPrinterName,
    paperWidthChars: paperWidthChars ?? this.paperWidthChars,
    charset: charset ?? this.charset,
    openDrawer: openDrawer ?? this.openDrawer,
  );
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
  static const _autoAcceptKioskKey = 'autoAcceptKiosk';
  static const _secondNameLangKey = 'secondNameLanguage';
  static const _serviceFeeBpKey = 'serviceFeeBp';
  static const _discountPresetsKey = 'discountPresetsBp';
  static const _discountThresholdKey = 'discountThresholdBp';
  static const _categoryVerticalKey = 'categoryVertical';
  static const _displayPromoKey = 'displayPromoLines';
  static const _displayPromoImagesKey = 'displayPromoImages';
  static const _brandLogoKeys = <BrandLogoSlot, String>{
    // global keeps the original key so an already-set logo becomes the default.
    BrandLogoSlot.global: 'brandLogoPath',
    BrandLogoSlot.appNav: 'brandLogoAppNav',
    BrandLogoSlot.displayWelcome: 'brandLogoWelcome',
    BrandLogoSlot.displayOrderHeader: 'brandLogoOrderHeader',
    BrandLogoSlot.kioskHeader: 'brandLogoKioskHeader',
    BrandLogoSlot.kioskConfirm: 'brandLogoKioskConfirm',
  };
  static const _displayModeKey = 'customerDisplayMode';
  static const _kioskSeqKey = 'kioskOrderSeq';
  static const _kioskPayHereKey = 'kioskPayHere';
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

  // --- Per-role printers (kitchen + receipt) ---

  String _rolePrefix(PrinterRole role) => 'printer.${role.name}';

  /// The printer configured for [role]. When a role has no saved config yet,
  /// falls back to the legacy single network printer so existing setups keep
  /// printing until reconfigured.
  PrinterConfig printerConfig(PrinterRole role) {
    final p = _rolePrefix(role);
    final transportName = prefs.getString('$p.transport');
    if (transportName == null) {
      return PrinterConfig(
        host: prefs.getString(_printerHostKey),
        port: prefs.getInt(_printerPortKey) ?? defaultPrinterPort,
        paperWidthChars:
            prefs.getInt(_paperWidthKey) ?? domain.EscPos.width80mm,
      );
    }
    return PrinterConfig(
      transport:
          domain.PrinterTransport.values.asNameMap()[transportName] ??
          domain.PrinterTransport.network,
      host: prefs.getString('$p.host'),
      port: prefs.getInt('$p.port') ?? defaultPrinterPort,
      windowsPrinterName: prefs.getString('$p.win'),
      paperWidthChars: prefs.getInt('$p.width') ?? domain.EscPos.width80mm,
      charset:
          domain.TicketCharset.values.asNameMap()[prefs.getString(
            '$p.charset',
          )] ??
          domain.TicketCharset.auto,
      openDrawer: prefs.getBool('$p.drawer') ?? false,
    );
  }

  Future<void> setPrinterConfig(PrinterRole role, PrinterConfig c) async {
    final p = _rolePrefix(role);
    await prefs.setString('$p.transport', c.transport.name);
    await _setOrRemove('$p.host', c.host);
    await prefs.setInt('$p.port', c.port);
    await _setOrRemove('$p.win', c.windowsPrinterName);
    await prefs.setInt('$p.width', c.paperWidthChars);
    await prefs.setString('$p.charset', c.charset.name);
    await prefs.setBool('$p.drawer', c.openDrawer);
  }

  /// The printer a job of [kind] should print to. Kitchen tickets go to the
  /// kitchen printer, receipts (and the test page) to the receipt printer;
  /// either falls back to the other role when its own isn't configured.
  PrinterConfig printerFor(domain.PrintJobKind kind) {
    final primary = kind == domain.PrintJobKind.kitchenTicket
        ? PrinterRole.kitchen
        : PrinterRole.receipt;
    final cfg = printerConfig(primary);
    if (cfg.isConfigured) return cfg;
    final other = primary == PrinterRole.kitchen
        ? PrinterRole.receipt
        : PrinterRole.kitchen;
    final fallback = printerConfig(other);
    return fallback.isConfigured ? fallback : cfg;
  }

  Future<void> _setOrRemove(String key, String? value) =>
      (value == null || value.isEmpty)
      ? prefs.remove(key)
      : prefs.setString(key, value);

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

  /// Whether in-store kiosk orders auto-accept straight to the Orders board
  /// (default on). Off routes them through the Inbox like remote orders.
  bool get autoAcceptKiosk => prefs.getBool(_autoAcceptKioskKey) ?? true;

  Future<void> setAutoAcceptKiosk(bool on) =>
      prefs.setBool(_autoAcceptKioskKey, on);

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

  /// Whether the order screen lists categories vertically (a left column that
  /// can show them all at once) rather than the horizontal scrolling row.
  bool get categoryVertical => prefs.getBool(_categoryVerticalKey) ?? false;

  Future<void> setCategoryVertical(bool vertical) =>
      prefs.setBool(_categoryVerticalKey, vertical);

  /// Promo lines that rotate on the customer display while no order is being
  /// rung up. Empty = just show the business name.
  List<String> get displayPromoLines =>
      prefs.getStringList(_displayPromoKey) ?? const [];

  Future<void> setDisplayPromoLines(List<String> lines) =>
      prefs.setStringList(_displayPromoKey, lines);

  /// Absolute paths of promo photos that play as a slideshow on the customer
  /// display while idle (alongside any promo text). Empty = no slideshow.
  List<String> get displayPromoImages =>
      prefs.getStringList(_displayPromoImagesKey) ?? const [];

  Future<void> setDisplayPromoImages(List<String> paths) =>
      prefs.setStringList(_displayPromoImagesKey, paths);

  /// Absolute path of the shop's brand logo for a given appearance [slot]
  /// (light / dark / wordmark). Null = none set for that slot. Set in Settings,
  /// so a multi-shop build needs no bundled per-shop asset.
  String? brandLogoPath(BrandLogoSlot slot) =>
      prefs.getString(_brandLogoKeys[slot]!);

  Future<void> setBrandLogoPath(BrandLogoSlot slot, String? path) async {
    final key = _brandLogoKeys[slot]!;
    if (path == null || path.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, path);
    }
  }

  /// How the customer-facing second screen behaves: a passive order/promo
  /// display, a dedicated self-order kiosk, or hybrid (promo + tap-to-order
  /// when idle, mirror while the cashier is ringing). Defaults to passive.
  CustomerDisplayMode get customerDisplayMode =>
      CustomerDisplayMode.values.asNameMap()[prefs.getString(
        _displayModeKey,
      )] ??
      CustomerDisplayMode.passive;

  Future<void> setCustomerDisplayMode(CustomerDisplayMode mode) =>
      prefs.setString(_displayModeKey, mode.name);

  /// Hands out the next kiosk pickup number and advances the counter. Cycles
  /// 0–999 (so codes stay short: K0 … K999 then back to K0). "K" = kiosk.
  Future<int> nextKioskNumber() async {
    final n = prefs.getInt(_kioskSeqKey) ?? 0;
    await prefs.setInt(_kioskSeqKey, (n + 1) % 1000);
    return n;
  }

  /// Whether the kiosk offers "pay here" (card at the kiosk) in addition to
  /// pay-at-counter. Off by default — and pay-here is not wired to a processor
  /// yet, so the kiosk shows it as coming soon. When off, all kiosk orders are
  /// pay-at-counter.
  bool get kioskPayHere => prefs.getBool(_kioskPayHereKey) ?? false;

  Future<void> setKioskPayHere(bool on) => prefs.setBool(_kioskPayHereKey, on);

  /// Whether the first-run welcome (pointing to the user guide) has been shown.
  bool get helpSeen => prefs.getBool(_helpSeenKey) ?? false;

  Future<void> setHelpSeen(bool seen) => prefs.setBool(_helpSeenKey, seen);
}
