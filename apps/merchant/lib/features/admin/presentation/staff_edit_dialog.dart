import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import '../data/staff_repository.dart';
import '../domain/staff.dart';
import 'role_labels.dart';

/// Add or edit a staff member. On a new member a 4-digit PIN is required; when
/// editing, leaving the PIN blank keeps the current one. Creating the very
/// first owner (bootstrap) signs them in.
Future<void> showStaffEditDialog(
  BuildContext context,
  WidgetRef ref, {
  Staff? existing,
  bool forceOwner = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _StaffEditDialog(existing: existing, forceOwner: forceOwner),
  );
}

class _StaffEditDialog extends ConsumerStatefulWidget {
  final Staff? existing;

  /// Bootstrap: the first account must be an owner, so the role is fixed.
  final bool forceOwner;

  const _StaffEditDialog({this.existing, this.forceOwner = false});

  @override
  ConsumerState<_StaffEditDialog> createState() => _StaffEditDialogState();
}

class _StaffEditDialogState extends ConsumerState<_StaffEditDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  final TextEditingController _pin = TextEditingController();
  late StaffRole _role = widget.forceOwner
      ? StaffRole.owner
      : (widget.existing?.role ?? StaffRole.server);
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final pin = _pin.text;
    if (name.isEmpty) {
      setState(() => _error = context.l10n.adminStaffNameRequired);
      return;
    }
    if (_isNew && pin.length < 4) {
      setState(() => _error = context.l10n.adminStaffPinRequired);
      return;
    }
    if (!_isNew && pin.isNotEmpty && pin.length < 4) {
      setState(() => _error = context.l10n.adminStaffPinRequired);
      return;
    }

    final id = widget.existing?.id ?? domain.newId();
    final pinHash = pin.isNotEmpty
        ? StaffRepository.hashPin(id, pin)
        : widget.existing!.pinHash;
    final staff = Staff(id: id, name: name, role: _role, pinHash: pinHash);

    final wasEmpty = (ref.read(staffRosterProvider).value ?? const []).isEmpty;
    await ref.read(staffRepositoryProvider).upsert(staff);
    // Bootstrap: signing in the first owner so the roster owner isn't locked
    // out of their own setup.
    if (wasEmpty && staff.role == StaffRole.owner) {
      ref.read(sessionProvider.notifier).setActive(staff);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isNew ? context.l10n.adminNewStaff : context.l10n.adminEditStaff,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: context.l10n.adminStaffName),
          ),
          const SizedBox(height: 12),
          if (widget.forceOwner)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_outlined),
              title: Text(context.l10n.adminStaffRole),
              trailing: Text(roleLabel(context, StaffRole.owner)),
            )
          else
            DropdownButtonFormField<StaffRole>(
              initialValue: _role,
              decoration: InputDecoration(
                labelText: context.l10n.adminStaffRole,
              ),
              items: [
                for (final r in StaffRole.values)
                  DropdownMenuItem(
                    value: r,
                    child: Text(roleLabel(context, r)),
                  ),
              ],
              onChanged: (r) => setState(() => _role = r ?? _role),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _pin,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: context.l10n.pinFieldLabel,
              counterText: '',
              helperText: _isNew ? null : context.l10n.adminStaffPinKeepHint,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(context.l10n.commonSave)),
      ],
    );
  }
}
