import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import '../data/storefront_config.dart';

/// Edits the device-local customer profile (name / phone / email) used to
/// prefill pickup orders. Not an account — just remembered details.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(walletProvider).profile;
    _name = TextEditingController(text: profile.name ?? '');
    _phone = TextEditingController(text: profile.phone ?? '');
    _email = TextEditingController(text: profile.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    await ref
        .read(walletProvider.notifier)
        .saveProfile(
          CustomerProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n.profileIntro,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: context.l10n.profileNameLabel,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: InputDecoration(
              labelText: context.l10n.profilePhoneLabel,
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            decoration: InputDecoration(
              labelText: context.l10n.profileEmailLabel,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(context.l10n.profileSave)),
        ],
      ),
    );
  }
}
