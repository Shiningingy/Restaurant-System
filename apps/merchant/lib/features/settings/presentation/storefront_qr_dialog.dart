import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';

/// Shows the restaurant's storefront as a QR code for customers to scan with
/// the ordering app. Built from the restaurant's own Supabase URL + anon key
/// (publishable — RLS guards the data), so it's safe to display or print.
Future<void> showStorefrontConnectQr(
  BuildContext context, {
  required String url,
  required String anonKey,
  String? name,
}) {
  final payload = domain.StorefrontLink(
    url: url,
    anonKey: anonKey,
    name: name,
  ).encode();
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.setCustomerQrTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: payload,
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.setCustomerQrHint, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonClose),
        ),
      ],
    ),
  );
}
