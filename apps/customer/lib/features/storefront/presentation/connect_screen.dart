import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';

/// First-run screen: the customer connects to a restaurant's storefront
/// using the URL + key the restaurant shares (e.g. via a QR code).
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _url = TextEditingController();
  final _key = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_url.text.trim().isEmpty || _key.text.trim().isEmpty) {
      setState(() => _error = 'Enter the restaurant URL and key.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    // The home gate switches to the menu once the config becomes connected.
    await ref
        .read(storefrontConfigProvider.notifier)
        .connect(url: _url.text, anonKey: _key.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to a restaurant')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              const Text(
                'Scan or enter the storefront your restaurant gave you to '
                'browse the menu and preorder for pickup.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _url,
                decoration: const InputDecoration(
                  labelText: 'Storefront URL',
                  hintText: 'https://xxxx.supabase.co',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _key,
                decoration: const InputDecoration(labelText: 'Access key'),
                maxLines: 2,
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
                onPressed: _busy ? null : _connect,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
