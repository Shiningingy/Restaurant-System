import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/language_menu.dart';
import '../application/providers.dart';
import '../data/storefront_link.dart';
import 'scan_screen.dart';

/// Adds a restaurant to the wallet using the URL + key the restaurant shares
/// (scanned from its QR code, or typed by hand). On success the restaurant
/// opens and this screen pops back to its menu.
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _url = TextEditingController();
  final _key = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Manual URL/key entry is collapsed by default — scanning the restaurant's
  /// QR is the intended path. On desktop (no scanner) it's shown from the start.
  bool _manual = false;

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final link = await Navigator.of(context).push<StorefrontLink>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (link == null) return;
    _url.text = link.url;
    _key.text = link.anonKey;
    if (link.name != null) _name.text = link.name!;
    await _connect();
  }

  Future<void> _connect() async {
    if (_url.text.trim().isEmpty || _key.text.trim().isEmpty) {
      setState(() => _error = context.l10n.connectErrorEmptyFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(walletProvider.notifier)
          .addAndConnect(url: _url.text, anonKey: _key.text, name: _name.text);
      // The restaurant is now active; the home gate shows its menu beneath us.
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = context.l10n.menuLoadError(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.connectAddTitle),
        actions: const [LanguageMenu()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Text(context.l10n.connectIntro),
              const SizedBox(height: 24),
              if (qrScanSupported) ...[
                FilledButton.icon(
                  onPressed: _busy ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(context.l10n.connectScanButton),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                if (!_manual) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _manual = true),
                    child: Text(context.l10n.connectEnterManually),
                  ),
                ],
              ],
              // Manual fields: always on desktop (no scanner), or once the
              // customer chooses "enter manually" on mobile.
              if (!qrScanSupported || _manual) ...[
                if (qrScanSupported) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          context.l10n.connectOrDivider,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _url,
                  decoration: InputDecoration(
                    labelText: context.l10n.connectUrlLabel,
                    hintText: 'https://xxxx.supabase.co',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _key,
                  decoration: InputDecoration(
                    labelText: context.l10n.connectKeyLabel,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: context.l10n.connectNameLabel,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _connect,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.connectButton),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
