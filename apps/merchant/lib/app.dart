import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n_ext.dart';
import 'features/settings/application/providers.dart';
import 'l10n/app_localizations.dart';
import 'features/menu/presentation/menu_screen.dart';
import 'features/online_orders/presentation/inbox_screen.dart';
import 'features/orders/presentation/order_screen.dart';
import 'features/orders/presentation/orders_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

// Built per MerchantApp instance so navigation state never leaks
// between app instances (matters for widget tests).
GoRouter _createRouter() => GoRouter(
  initialLocation: '/orders',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      OrderScreen(orderId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/menu',
              builder: (context, state) => const MenuScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (context, state) => const InboxScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class MerchantApp extends ConsumerStatefulWidget {
  const MerchantApp({super.key});

  @override
  ConsumerState<MerchantApp> createState() => _MerchantAppState();
}

class _MerchantAppState extends ConsumerState<MerchantApp> {
  late final GoRouter _router = _createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: ref.watch(localePreferenceProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class _HomeShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _HomeShell({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: const Icon(Icons.receipt_long),
                label: Text(context.l10n.navOrders),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.restaurant_menu_outlined),
                selectedIcon: const Icon(Icons.restaurant_menu),
                label: Text(context.l10n.navMenu),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.inbox_outlined),
                selectedIcon: const Icon(Icons.inbox),
                label: Text(context.l10n.navInbox),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: Text(context.l10n.navReports),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(context.l10n.navSettings),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}
