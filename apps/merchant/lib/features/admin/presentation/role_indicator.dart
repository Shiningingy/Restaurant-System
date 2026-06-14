import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import 'pin_dialog.dart';
import 'role_labels.dart';

/// Compact active-user / role control for the navigation rail's trailing area.
/// Signed out → a sign-in button (PIN). Signed in → an avatar menu to switch
/// user or sign out. Empty roster (bootstrap) → a quiet badge, no actions.
class RoleIndicator extends ConsumerWidget {
  const RoleIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(staffRosterProvider).value ?? const [];
    final session = ref.watch(sessionProvider);

    if (roster.isEmpty) {
      // Nothing set up yet — full access until an owner creates the roster.
      return IconButton(
        icon: const Icon(Icons.person_outline),
        tooltip: context.l10n.roleNoStaffYet,
        onPressed: null,
      );
    }

    if (session == null) {
      return IconButton(
        icon: const Icon(Icons.login),
        tooltip: context.l10n.roleSignIn,
        onPressed: () => showPinDialog(context, ref),
      );
    }

    final initial = session.name.isEmpty
        ? '?'
        : session.name.characters.first.toUpperCase();
    return PopupMenuButton<String>(
      tooltip: '${session.name} · ${roleLabel(context, session.role)}',
      onSelected: (v) async {
        switch (v) {
          case 'switch':
            await showPinDialog(context, ref);
          case 'signout':
            ref.read(sessionProvider.notifier).signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(session.name),
            subtitle: Text(roleLabel(context, session.role)),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'switch',
          child: Text(context.l10n.roleSwitchUser),
        ),
        PopupMenuItem(value: 'signout', child: Text(context.l10n.roleSignOut)),
      ],
      child: CircleAvatar(radius: 16, child: Text(initial)),
    );
  }
}
