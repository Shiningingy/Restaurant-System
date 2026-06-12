import 'package:shared_preferences/shared_preferences.dart';

/// App settings stored in shared_preferences. Orders snapshot the tax
/// rate at creation, so changing it here never rewrites history.
class SettingsRepository {
  static const _taxRateBpKey = 'taxRateBp';

  /// 13% HST (Ontario) as the default — the user configures their own rate.
  static const defaultTaxRateBp = 1300;

  final SharedPreferences prefs;

  SettingsRepository(this.prefs);

  int get taxRateBp => prefs.getInt(_taxRateBpKey) ?? defaultTaxRateBp;

  Future<void> setTaxRateBp(int bp) => prefs.setInt(_taxRateBpKey, bp);
}
