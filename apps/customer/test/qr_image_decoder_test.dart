import 'dart:typed_data';

import 'package:customer/features/storefront/data/qr_image_decoder.dart';
import 'package:customer/features/storefront/data/storefront_link.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Renders [text] as a black-on-white QR PNG with a quiet zone — a stand-in
/// for a saved/screenshotted QR image the customer would upload.
Uint8List renderQrPng(String text, {int scale = 8, int quiet = 4}) {
  final code = QrCode.fromData(
    data: text,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final qr = QrImage(code);
  final n = code.moduleCount;
  final size = (n + quiet * 2) * scale;
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (qr.isDark(y, x)) {
        final px = (x + quiet) * scale;
        final py = (y + quiet) * scale;
        img.fillRect(
          image,
          x1: px,
          y1: py,
          x2: px + scale - 1,
          y2: py + scale - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
  }
  return img.encodePng(image);
}

void main() {
  test('decodes a storefront QR image back into a StorefrontLink', () {
    const link = StorefrontLink(
      url: 'https://abcd1234.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCexamplekey',
      name: 'Yee Sushi',
    );
    final png = renderQrPng(link.encode());

    final decoded = decodeStorefrontQrFromImageBytes(png);

    expect(decoded, isNotNull);
    expect(decoded!.url, link.url);
    expect(decoded.anonKey, link.anonKey);
    expect(decoded.name, link.name);
  });

  test('returns null for an image with no QR code', () {
    final blank = img.Image(width: 100, height: 100);
    img.fill(blank, color: img.ColorRgb8(255, 255, 255));
    expect(
      decodeStorefrontQrFromImageBytes(img.encodePng(blank)),
      isNull,
    );
  });

  test('returns null for a QR that is not one of ours', () {
    final png = renderQrPng('https://example.com/not-a-storefront');
    expect(decodeStorefrontQrFromImageBytes(png), isNull);
  });
}
