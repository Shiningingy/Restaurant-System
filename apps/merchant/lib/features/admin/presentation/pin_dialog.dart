import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import '../domain/staff.dart';

/// Prompts for a PIN and signs the matching staff member in. Returns the
/// signed-in [Staff] on success, or null if cancelled. Re-prompts on a wrong
/// PIN. The caller decides whether that staff's role is sufficient.
Future<Staff?> showPinDialog(BuildContext context, WidgetRef ref) {
  return showDialog<Staff>(
    context: context,
    builder: (context) => const _PinDialog(),
  );
}

/// Ensures the current role satisfies [permission]. Returns true if already
/// allowed; otherwise prompts for a PIN. After a successful sign-in it
/// re-checks the new role — if still insufficient (e.g. a server signed in for
/// a manager action) it shows a message and returns false.
Future<bool> requirePermission(
  BuildContext context,
  WidgetRef ref,
  AppPermission permission,
) async {
  if (ref.read(canProvider(permission))) return true;
  final messenger = ScaffoldMessenger.of(context);
  final insufficientMsg = context.l10n.roleAccessRequired;
  final staff = await showPinDialog(context, ref);
  if (staff == null) return false;
  if (allows(staff.role, permission)) return true;
  messenger.showSnackBar(SnackBar(content: Text(insufficientMsg)));
  return false;
}

class _PinDialog extends ConsumerStatefulWidget {
  const _PinDialog();

  @override
  ConsumerState<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<_PinDialog> {
  final _controller = TextEditingController();
  bool _error = false;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text;
    if (pin.length < 4) return;
    setState(() {
      _busy = true;
      _error = false;
    });
    final staff = await ref.read(sessionProvider.notifier).signInWithPin(pin);
    if (!mounted) return;
    if (staff == null) {
      setState(() {
        _busy = false;
        _error = true;
        _controller.clear();
      });
      return;
    }
    Navigator.pop(context, staff);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.pinEnterTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        maxLength: 4,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: context.l10n.pinFieldLabel,
          counterText: '',
          errorText: _error ? context.l10n.pinIncorrect : null,
        ),
        onChanged: (v) {
          if (v.length == 4 && !_busy) _submit();
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(context.l10n.pinUnlock),
        ),
      ],
    );
  }
}
