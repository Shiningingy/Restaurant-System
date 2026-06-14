import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Shorthand for `AppLocalizations.of(context)!` so call sites read
/// `context.l10n.connectTitle` instead of the full lookup.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
