import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/l10n_ext.dart';
import '../data/storefront_config.dart';
import '../data/storefront_link.dart';

/// Shows a saved restaurant's connection as a QR code so a friend can scan it
/// to add the same restaurant. Safe to display — the anon key is publishable
/// and the data behind it is guarded by RLS.
Future<void> showStorefrontQr(BuildContext context, SavedStorefront store) {
  final payload = StorefrontLink(
    url: store.url,
    anonKey: store.anonKey,
    name: store.name,
  ).encode();
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.shareTitle(store.label)),
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
          Text(context.l10n.shareHint, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.shareClose),
        ),
      ],
    ),
  );
}
