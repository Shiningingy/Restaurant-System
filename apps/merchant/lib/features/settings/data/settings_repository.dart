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

/// App settings stored in shared_preferences. Orders snapshot the tax
/// rate at creation, so changing it here never rewrites history.
class SettingsRepository {
  static const _taxRateBpKey = 'taxRateBp';
  static const _printerHostKey = 'printerHost';
  static const _printerPortKey = 'printerPort';
  static const _paperWidthKey = 'paperWidthChars';
  static const _businessNameKey = 'businessName';
  static const _receiptFooterKey = 'receiptFooter';

  /// 13% HST (Ontario) as the default — the user configures their own rate.
  static const defaultTaxRateBp = 1300;
  static const defaultPrinterPort = 9100;

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
}
