import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../storefront/application/providers.dart';
import '../../storefront/drivers/supabase_auth.dart';

/// Turns this device into a self-order kiosk — gated by the restaurant's store
/// login so only staff (not a customer) can enable it. Verifies the store
/// credentials against the connected storefront's Supabase, then locks the
/// device to that storefront with the given kiosk number. The login is a
/// one-time authorization check; the kiosk then runs on its own anonymous
/// session (the store credentials are never stored on the device).
class KioskSetupScreen extends ConsumerStatefulWidget {
  const KioskSetupScreen({super.key});

  @override
  ConsumerState<KioskSetupScreen> createState() => _KioskSetupScreenState();
}

class _KioskSetupScreenState extends ConsumerState<KioskSetupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _number = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = context.l10n;
    final config = ref.read(storefrontConfigProvider);
    final active = ref.read(walletProvider).active;
    if (!config.isConnected || active == null) {
      setState(() => _error = l10n.kioskSetupNoStore);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = SupabaseAuth(url: config.url!, anonKey: config.anonKey!);
      await auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await ref
          .read(kioskModeProvider.notifier)
          .enable(active.id, number: int.tryParse(_number.text.trim()));
      // Kiosk mode is on; the home gate now shows the kiosk root. Pop back.
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.kioskSetupSignInFailed('$e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.kioskSetupTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Text(l10n.kioskSetupBody),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                decoration: InputDecoration(labelText: l10n.kioskSetupEmail),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                decoration: InputDecoration(labelText: l10n.kioskSetupPassword),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _number,
                decoration: InputDecoration(
                  labelText: l10n.kioskSetupNumber,
                  helperText: l10n.kioskSetupNumberHint,
                ),
                keyboardType: TextInputType.number,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _start,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.kioskSetupStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
