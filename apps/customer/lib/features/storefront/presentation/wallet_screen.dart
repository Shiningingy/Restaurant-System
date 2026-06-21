import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/language_menu.dart';
import '../../cart/cart.dart';
import '../../help/presentation/help_screen.dart';
import '../application/providers.dart';
import '../data/storefront_config.dart';
import 'connect_screen.dart';
import 'profile_screen.dart';
import 'storefront_qr.dart';

/// The home screen: the customer's wallet of saved restaurants. Tap one to
/// open its menu; add more by scanning a QR or entering a link. Fully
/// device-local — no account, no central server.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(walletProvider).storefronts;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.walletTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.walletProfile,
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            tooltip: context.l10n.helpTitle,
            icon: const Icon(Icons.help_outline),
            onPressed: () => openHelp(context),
          ),
          const LanguageMenu(),
        ],
      ),
      floatingActionButton: stores.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.walletAdd),
            ),
      body: stores.isEmpty
          ? _Empty(onAdd: () => _add(context))
          : ListView(
              children: [
                for (final store in stores)
                  Builder(
                    builder: (context) {
                      final host = Uri.tryParse(store.url)?.host ?? store.url;
                      return ListTile(
                        leading: const Icon(Icons.storefront_outlined),
                        title: Text(store.label),
                        subtitle: store.label == host ? null : Text(host),
                        onTap: () => _open(ref, store.id),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'rename') {
                              _rename(context, ref, store);
                            } else if (v == 'share') {
                              showStorefrontQr(context, store);
                            } else if (v == 'remove') {
                              _confirmRemove(context, ref, store);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.edit_outlined),
                                title: Text(context.l10n.walletRename),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'share',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.qr_code_2),
                                title: Text(context.l10n.walletShare),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.delete_outline),
                                title: Text(context.l10n.walletRemove),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }

  void _open(WidgetRef ref, String id) {
    // A new restaurant means a fresh cart — items belong to one menu.
    ref.read(cartProvider.notifier).clear();
    ref.read(walletProvider.notifier).open(id);
  }

  void _add(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ConnectScreen()));

  /// Lets the customer set their own nickname for a restaurant (priority over
  /// the merchant's name). Pre-fills the current nickname; blank clears it.
  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    SavedStorefront store,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: store.nickname ?? '');
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.walletRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.walletRenameLabel,
            hintText: store.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.profileSave),
          ),
        ],
      ),
    );
    if (nickname == null) return; // cancelled
    await ref.read(walletProvider.notifier).rename(store.id, nickname);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    SavedStorefront store,
  ) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.walletRemoveConfirm(store.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.walletRemove),
          ),
        ],
      ),
    );
    if (ok ?? false) ref.read(walletProvider.notifier).remove(store.id);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.walletEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(context.l10n.walletEmptyBody, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.walletAdd),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
