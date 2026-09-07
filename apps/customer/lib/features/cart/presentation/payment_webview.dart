import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/l10n_ext.dart';
import '../../storefront/application/providers.dart';

/// Renders the processor's hosted payment page (served by the `pay-online`
/// function) inside the app. Two shapes, decided by what the function answers:
///
/// **A — the function REDIRECTS (302) to the processor** (Stripe Checkout). The
/// processor serves its own page as real `text/html` on its own origin, so we
/// simply navigate the webview there and get out of the way. This is the simple
/// path: no interception, no origin games.
///
/// **B — the function returns the page itself** (Moneris hosted tokenization,
/// HelcimPay.js, Stripe Payment Element). Supabase serves edge-function output as
/// `text/plain` (anti-phishing), so a browser won't render it. We fetch the HTML
/// ourselves and feed it to the webview under our Supabase origin — which is what
/// Moneris's iframe checks against the registered source domain:
///  - **mobile** (Android/iOS): `loadData` + `baseUrl` (origin honored natively);
///  - **Windows** (WebView2): navigate to the real URL and relabel the response
///    `text/html` via request interception (WebView2 ignores `baseUrl` for
///    in-memory data, but a real navigation keeps the origin).
///
/// We must NOT follow the redirect while fetching — doing so would re-serve the
/// processor's page under OUR origin and break it.
///
/// Pops `true` once the order's `payment_status` flips to paid; backing out pops
/// `null`, which the checkout treats as "not paid" (and cleans up the order).
class PaymentWebView extends ConsumerStatefulWidget {
  /// `<origin>/functions/v1/pay-online?order_id=<id>` — its origin is what
  /// Moneris's iframe checks, and the page's verify-call resolves against it.
  final String pageUrl;
  final String orderId;

  const PaymentWebView({
    super.key,
    required this.pageUrl,
    required this.orderId,
  });

  @override
  ConsumerState<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends ConsumerState<PaymentWebView> {
  String? _html;
  String? _redirectUrl; // set when the function 302s us to the processor
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final client = http.Client();
    try {
      // Deliberately do NOT follow redirects: a 302 means the processor hosts the
      // page itself, and following it here would hand us their HTML to re-serve
      // under our own origin (shape B), which breaks it.
      final request = http.Request('GET', Uri.parse(widget.pageUrl))
        ..followRedirects = false;
      final resp = await client
          .send(request)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;

      if (resp.statusCode >= 300 && resp.statusCode < 400) {
        final location = resp.headers['location'];
        if (location != null && location.isNotEmpty) {
          // Resolve in case the processor ever sends a relative Location.
          final target = Uri.parse(widget.pageUrl).resolve(location).toString();
          setState(() => _redirectUrl = target);
          return;
        }
      }
      if (resp.statusCode >= 300) {
        setState(() => _error = 'HTTP ${resp.statusCode}');
        return;
      }
      final body = await resp.stream.bytesToString();
      if (!mounted) return;
      setState(() => _html = body);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      client.close();
    }
  }

  /// Watches the order for the function flipping it to paid (it's the only
  /// writer of `paid`), then closes with success.
  void _startPolling() {
    _poll = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final storefront = ref.read(storefrontProvider);
      if (storefront == null) return;
      try {
        final state = await storefront.fetchState(widget.orderId);
        if (!mounted) return;
        if (state.paymentStatus == 'paid') {
          timer.cancel();
          Navigator.of(context).pop(true);
        }
      } on Object {
        // Transient — keep polling.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.checkoutPayOnline)),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.checkoutOrderFailed(_error!),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _redirectUrl != null
          ? _hostedWebview(_redirectUrl!)
          : _html == null
          ? const Center(child: CircularProgressIndicator())
          : _webview(_html!),
    );
  }

  /// Shape A — the processor hosts the page. Just navigate; it is served as real
  /// `text/html` on the processor's own origin, so nothing needs intercepting.
  Widget _hostedWebview(String url) => InAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(url)),
  );

  Widget _webview(String html) {
    // Windows/WebView2: navigate to the real URL (keeps the origin) and serve
    // the fetched HTML back as text/html for that one request.
    if (Platform.isWindows) {
      return InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.pageUrl)),
        initialSettings: InAppWebViewSettings(useShouldInterceptRequest: true),
        shouldInterceptRequest: (controller, request) async {
          if (request.url.toString() == widget.pageUrl) {
            return WebResourceResponse(
              contentType: 'text/html',
              contentEncoding: 'utf-8',
              data: Uint8List.fromList(utf8.encode(html)),
            );
          }
          return null; // the Moneris iframe + the verify POST load normally
        },
      );
    }
    // Mobile: in-memory HTML with the full page URL as the base — so the page's
    // origin is our supabase.co domain AND its `location` carries the order_id
    // the verify-call needs.
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: html,
        baseUrl: WebUri(widget.pageUrl),
        mimeType: 'text/html',
        encoding: 'utf-8',
      ),
    );
  }
}
