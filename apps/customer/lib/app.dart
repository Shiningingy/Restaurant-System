import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_ui/restaurant_ui.dart';

import 'core/l10n_ext.dart';
import 'features/help/presentation/help_screen.dart';
import 'features/kiosk/presentation/kiosk_root.dart';
import 'features/storefront/application/providers.dart';
import 'features/storefront/presentation/menu_screen.dart';
import 'features/storefront/presentation/wallet_screen.dart';
import 'l10n/app_localizations.dart';

class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kiosk = ref.watch(kioskModeProvider);
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: ref.watch(localePreferenceProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildPosTheme(kiosk: kiosk),
      // Kiosk skips the first-run help dialog and the wallet entirely.
      home: kiosk
          ? const KioskRoot()
          : const FirstRunHelpGate(child: _HomeGate()),
    );
  }
}

/// Shows the wallet of saved restaurants until the customer opens one, then
/// that restaurant's menu.
class _HomeGate extends ConsumerWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(walletProvider).isConnected;
    return open ? const MenuScreen() : const WalletScreen();
  }
}
