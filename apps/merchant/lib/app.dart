import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_ui/restaurant_ui.dart';

import 'core/l10n_ext.dart';
import 'core/window/window_control.dart';
import 'features/admin/application/providers.dart';
import 'features/admin/domain/staff.dart';
import 'features/admin/presentation/admin_screen.dart';
import 'features/admin/presentation/role_indicator.dart';
import 'features/help/presentation/help_screen.dart';
import 'core/settings/providers.dart';
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
      builder: (context, state, shell) => FirstRunHelpGate(
        child: _HomeShell(shell: shell, location: state.uri.path),
      ),
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
              path: '/admin',
              builder: (context, state) => const AdminScreen(),
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
  void initState() {
    super.initState();
    // F11 toggles the main window's fullscreen, anywhere in the app.
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _router.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      () async {
        final state = await ref
            .read(windowControlProvider)
            .toggleMainFullscreen();
        if (mounted) ref.read(mainFullscreenProvider.notifier).set(state);
      }();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: ref.watch(localePreferenceProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildPosTheme(),
      routerConfig: _router,
    );
  }
}

/// A nav destination plus the permission needed to see it (null = everyone).
/// Order MUST match the router's branch order.
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final AppPermission? permission;

  const _NavItem(this.icon, this.selectedIcon, this.label, [this.permission]);
}

class _HomeShell extends ConsumerWidget {
  final StatefulNavigationShell shell;

  /// Current full path — used to hide the nav rail on an order's full-screen
  /// editor (`/orders/<id>`), which has its own back button.
  final String location;

  const _HomeShell({required this.shell, required this.location});

  static final _orderDetail = RegExp(r'^/orders/[^/]+');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final hideRail = _orderDetail.hasMatch(location);
    final items = <_NavItem>[
      _NavItem(
        Icons.receipt_long_outlined,
        Icons.receipt_long,
        context.l10n.navOrders,
      ),
      _NavItem(
        Icons.restaurant_menu_outlined,
        Icons.restaurant_menu,
        context.l10n.navMenu,
        AppPermission.editMenu,
      ),
      _NavItem(Icons.inbox_outlined, Icons.inbox, context.l10n.navInbox),
      _NavItem(
        Icons.bar_chart_outlined,
        Icons.bar_chart,
        context.l10n.navReports,
        AppPermission.viewReports,
      ),
      _NavItem(
        Icons.admin_panel_settings_outlined,
        Icons.admin_panel_settings,
        context.l10n.navAdmin,
        AppPermission.accessAdmin,
      ),
      _NavItem(
        Icons.settings_outlined,
        Icons.settings,
        context.l10n.navSettings,
      ),
    ];
    // Branch indices the current role may see, in branch order.
    final visible = [
      for (var i = 0; i < items.length; i++)
        if (items[i].permission == null || allows(role, items[i].permission!))
          i,
    ];

    // If the active branch just became hidden (e.g. a manager signed out while
    // on Reports), bounce back to Orders.
    if (!visible.contains(shell.currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) shell.goBranch(0);
      });
    }
    final selected = visible.indexOf(shell.currentIndex);

    // The order editor takes the whole window (more room for the menu grid);
    // its app-bar back button returns to the orders board.
    if (hideRail) return shell;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selected < 0 ? 0 : selected,
            onDestinationSelected: (railIndex) {
              final branch = visible[railIndex];
              shell.goBranch(
                branch,
                initialLocation: branch == shell.currentIndex,
              );
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: BrandMark(
                logoPath: ref.watch(brandLogosProvider).light,
                size: 40,
                fallbackColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: const RoleIndicator(),
                ),
              ),
            ),
            destinations: [
              for (final i in visible)
                NavigationRailDestination(
                  icon: Icon(items[i].icon),
                  selectedIcon: Icon(items[i].selectedIcon),
                  label: Text(items[i].label),
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
