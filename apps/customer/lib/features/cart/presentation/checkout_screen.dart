import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../storefront/application/providers.dart';
import '../../storefront/presentation/status_screen.dart';
import '../cart.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  TimeOfDay _pickup = TimeOfDay.now().replacing(
    hour: (TimeOfDay.now().hour + (TimeOfDay.now().minute > 30 ? 1 : 0)) % 24,
  );
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final config = ref.read(storefrontConfigProvider);
    _name = TextEditingController(text: config.customerName ?? '');
    _phone = TextEditingController(text: config.customerPhone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  DateTime get _pickupDateTime {
    final now = DateTime.now();
    var when = DateTime(
      now.year,
      now.month,
      now.day,
      _pickup.hour,
      _pickup.minute,
    );
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  Future<void> _place() async {
    final storefront = ref.read(storefrontProvider);
    if (storefront == null) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    final cart = ref.read(cartProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final submission = domain.PreorderSubmission(
        customerName: _name.text.trim(),
        customerPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        requestedPickupAt: _pickupDateTime,
        lines: cart.lines.map((l) => l.toPreorderLine()).toList(),
      );
      final orderId = await storefront.submitPreorder(
        submission,
        customerUid: ref.read(storefrontConfigProvider).customerUid,
      );
      await ref
          .read(storefrontConfigRepositoryProvider)
          .rememberCustomer(name: _name.text.trim(), phone: _phone.text.trim());
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              StatusScreen(orderId: orderId, total: submission.total),
        ),
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not place the order: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Your name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Pickup time'),
            trailing: Text(
              _pickup.format(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _pickup,
              );
              if (picked != null) setState(() => _pickup = picked);
            },
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleMedium),
              Text(
                cart.total.format(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pay at the counter when you pick up.',
            style: Theme.of(context).textTheme.bodySmall,
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
            onPressed: _busy ? null : _place,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Place preorder'),
          ),
        ],
      ),
    );
  }
}
