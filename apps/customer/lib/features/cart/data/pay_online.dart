import 'package:url_launcher/url_launcher.dart';

/// The restaurant's `pay-online` Edge Function URL for [orderId], derived from
/// the storefront's Supabase base URL. Opens Moneris's hosted checkout page —
/// the customer pays on Moneris; the function verifies and flips the order to
/// paid (which the status screen then polls).
Uri payOnlineUrl(String storefrontUrl, String orderId) {
  final base = storefrontUrl.endsWith('/') ? storefrontUrl : '$storefrontUrl/';
  return Uri.parse(
    '${base}functions/v1/pay-online',
  ).replace(queryParameters: {'order_id': orderId});
}

/// Opens the hosted checkout in the system browser (works on every platform,
/// no embedded webview). Returns false if no browser could be launched.
Future<bool> launchPayOnline(String storefrontUrl, String orderId) {
  return launchUrl(
    payOnlineUrl(storefrontUrl, orderId),
    mode: LaunchMode.externalApplication,
  );
}
