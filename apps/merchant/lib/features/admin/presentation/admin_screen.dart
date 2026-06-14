import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import '../domain/staff.dart';
import 'role_labels.dart';
import 'staff_edit_dialog.dart';

/// Manager/owner home: staff & roles plus placeholders for future management
/// functions. Reached only when the current role allows `accessAdmin` (the
/// nav rail enforces that).
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(staffRosterProvider).value ?? const [];
    final canManage = ref.watch(canProvider(AppPermission.manageStaff));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navAdmin)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (roster.isEmpty)
            _BootstrapCard(
              onCreate: () =>
                  showStaffEditDialog(context, ref, forceOwner: true),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.adminStaffSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (canManage)
                  TextButton.icon(
                    onPressed: () => showStaffEditDialog(context, ref),
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(context.l10n.adminAddStaff),
                  ),
              ],
            ),
            for (final s in roster)
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    s.name.isEmpty
                        ? '?'
                        : s.name.characters.first.toUpperCase(),
                  ),
                ),
                title: Text(s.name),
                subtitle: Text(roleLabel(context, s.role)),
                trailing: canManage
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: context.l10n.commonEdit,
                            onPressed: () =>
                                showStaffEditDialog(context, ref, existing: s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: context.l10n.commonDelete,
                            onPressed: () => _deleteStaff(context, ref, s),
                          ),
                        ],
                      )
                    : null,
              ),
            if (!canManage)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.adminManageStaffOwnerOnly,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
          const Divider(height: 32),
          Text(
            context.l10n.adminManagementSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          _PlaceholderTile(
            icon: Icons.verified_user_outlined,
            title: context.l10n.adminOnlineAuth,
            subtitle: context.l10n.adminOnlineAuthBody,
          ),
          _PlaceholderTile(
            icon: Icons.percent_outlined,
            title: context.l10n.adminDiscounts,
          ),
          _PlaceholderTile(
            icon: Icons.point_of_sale_outlined,
            title: context.l10n.adminEndOfDay,
          ),
          _PlaceholderTile(
            icon: Icons.download_outlined,
            title: context.l10n.adminExport,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(
    BuildContext context,
    WidgetRef ref,
    Staff staff,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    // Never strand the roster without an owner.
    if (staff.role == StaffRole.owner) {
      final owners = await ref.read(staffRepositoryProvider).ownerCount();
      if (owners <= 1) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.adminCannotDeleteLastOwner)),
        );
        return;
      }
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.adminRemoveStaffConfirm(staff.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(staffRepositoryProvider).delete(staff.id);
      // If the signed-in user removed themselves, drop back to baseline.
      if (ref.read(sessionProvider)?.id == staff.id) {
        ref.read(sessionProvider.notifier).signOut();
      }
    }
  }
}

class _BootstrapCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _BootstrapCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.adminBootstrapTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.adminBootstrapBody),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.shield_outlined),
                label: Text(context.l10n.adminCreateFirstOwner),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _PlaceholderTile({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Chip(label: Text(context.l10n.adminComingSoon)),
    );
  }
}
