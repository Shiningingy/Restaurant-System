import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../orders/application/providers.dart';
import '../application/providers.dart';

/// A staff-sent payment link: a QR for a customer standing at the counter, and
/// optional email / SMS delivery for one who isn't (a phone-in order).
///
/// Deliberately **dismissable**. The link keeps being polled in the background
/// by [payLinkServiceProvider], so staff can close this and serve the next
/// customer — the dot on the order board turns green by itself when the money
/// lands. Holding the till hostage to someone else's phone would be worse than
/// the problem this solves.
Future<void> showPayLinkSheet(
  BuildContext context, {
  required String orderId,
  required domain.Money amount,
  String? shopName,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        _PayLinkSheet(orderId: orderId, amount: amount, shopName: shopName),
  );
}

class _PayLinkSheet extends ConsumerStatefulWidget {
  final String orderId;
  final domain.Money amount;
  final String? shopName;

  const _PayLinkSheet({
    required this.orderId,
    required this.amount,
    this.shopName,
  });

  @override
  ConsumerState<_PayLinkSheet> createState() => _PayLinkSheetState();
}

class _PayLinkSheetState extends ConsumerState<_PayLinkSheet> {
  final _email = TextEditingController();
  final _phone = TextEditingController();

  String? _url;
  String? _error;
  String? _notice;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _create();
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    try {
      final url = await ref
          .read(payLinkServiceProvider)
          .createLink(
            orderId: widget.orderId,
            amount: widget.amount,
            label: widget.shopName,
          );
      if (mounted) setState(() => _url = url);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = context.l10n.payLinkCreateFailed('$e'));
      }
    }
  }

  Future<void> _send() async {
    final url = _url;
    if (url == null) return;
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    if (email.isEmpty && phone.isEmpty) {
      setState(() => _notice = context.l10n.payLinkNoContact);
      return;
    }
    setState(() {
      _sending = true;
      _notice = null;
    });
    try {
      final sent = await ref
          .read(payLinkServiceProvider)
          .sendLink(
            message: context.l10n.payLinkCustomerMessage(
              widget.amount.format(),
              url,
            ),
            subject: context.l10n.payLinkCustomerSubject,
            email: email.isEmpty ? null : email,
            phone: phone.isEmpty ? null : phone,
          );
      if (!mounted) return;
      setState(() {
        // Zero channels attempted means neither Resend nor Twilio is configured.
        // Saying "sent" there would leave staff waiting on a message that was
        // never going anywhere.
        _notice = sent == 0
            ? context.l10n.payLinkNotConfigured
            : context.l10n.payLinkSent;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() => _notice = context.l10n.payLinkSendFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.payLinkTitle(widget.amount.format())),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Text(_error!, style: TextStyle(color: scheme.error))
              else if (_url == null)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white, // scanners need the quiet zone white
                    child: QrImageView(data: _url!, size: 220),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.payLinkScanHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 28),
                Text(
                  l10n.payLinkOrSend,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: l10n.payLinkEmail,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  decoration: InputDecoration(
                    labelText: l10n.payLinkPhone,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(l10n.payLinkSend),
                  ),
                ),
                if (_notice != null) ...[
                  const SizedBox(height: 6),
                  Text(_notice!, style: Theme.of(context).textTheme.bodySmall),
                ],
                const Divider(height: 28),
                _StatusLine(orderId: widget.orderId),
                const SizedBox(height: 6),
                Text(
                  l10n.payLinkKeepServing,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

/// Live payment state, straight off the order the poller is updating.
class _StatusLine extends ConsumerWidget {
  final String orderId;

  const _StatusLine({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<domain.Order?>(
      stream: ref.watch(orderRepositoryProvider).watchOrder(orderId),
      builder: (context, snapshot) {
        final status =
            snapshot.data?.payLinkStatus ?? domain.PayLinkStatus.pending;
        final (color, label) = switch (status) {
          domain.PayLinkStatus.pending => (
            Colors.amber.shade700,
            l10n.payLinkWaiting,
          ),
          domain.PayLinkStatus.paid => (
            Colors.green.shade600,
            l10n.payLinkPaid,
          ),
          domain.PayLinkStatus.failed => (scheme.error, l10n.payLinkFailed),
        };
        return Row(
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
