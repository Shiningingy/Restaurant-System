import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../storefront/application/providers.dart';
import 'kiosk_order_screen.dart';

/// The kiosk's home. Ensures the device is locked to its storefront, then shows
/// a full-screen attract screen; tapping it starts a fresh order. This is the
/// root route, so the order flow returns here (the auto-reset) via
/// `popUntil(isFirst)`.
class KioskRoot extends ConsumerWidget {
  const KioskRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final kioskId = ref
        .read(storefrontConfigRepositoryProvider)
        .kioskStorefrontId;

    // After a reboot the kiosk's storefront may not be the open one — reopen it.
    if (kioskId != null && wallet.active?.id != kioskId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(walletProvider.notifier).open(kioskId);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!wallet.isConnected) {
      return Scaffold(
        body: Center(child: Text(context.l10n.kioskNotConnected)),
      );
    }
    return const _AttractScreen();
  }
}

class _AttractScreen extends ConsumerWidget {
  const _AttractScreen();

  void _start(BuildContext context, WidgetRef ref) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const KioskOrderScreen()));
  }

  Future<void> _confirmExit(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.kioskExitTitle),
        content: Text(context.l10n.kioskExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.kioskExit),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(kioskModeProvider.notifier).disable();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(menuProvider).value?.restaurantName;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: theme.colorScheme.primaryContainer,
              child: InkWell(
                onTap: () => _start(context, ref),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 96,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 24),
                        if (name != null && name.isNotEmpty)
                          Text(
                            name,
                            style: theme.textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.kioskTapToOrder,
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        FilledButton.icon(
                          onPressed: () => _start(context, ref),
                          icon: const Icon(Icons.touch_app),
                          label: Text(context.l10n.kioskStart),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 24,
                            ),
                            textStyle: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Staff-only exit: long-press the top-left corner.
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => _confirmExit(context, ref),
                child: const SizedBox(width: 64, height: 64),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
