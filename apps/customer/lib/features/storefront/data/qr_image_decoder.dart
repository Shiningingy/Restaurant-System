import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

import 'storefront_link.dart';

/// Decodes a storefront QR from a still image (e.g. a saved/screenshotted QR),
/// for platforms without a camera scanner (desktop). Pure Dart — no plugin —
/// so it works on Windows where mobile_scanner has no implementation.
///
/// Returns the parsed [StorefrontLink], or null if the image holds no QR or
/// the QR isn't one of ours.
StorefrontLink? decodeStorefrontQrFromImageBytes(Uint8List bytes) {
  final raw = _readQr(bytes);
  return raw == null ? null : StorefrontLink.tryParse(raw);
}

String? _readQr(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return null;
  // zxing2 wants 32-bit ARGB pixels; image v4 gives them via ABGR byte order.
  final pixels = image
      .convert(numChannels: 4)
      .getBytes(order: img.ChannelOrder.abgr)
      .buffer
      .asInt32List();
  final source = RGBLuminanceSource(image.width, image.height, pixels);
  final bitmap = BinaryBitmap(HybridBinarizer(source));
  try {
    return QRCodeReader().decode(bitmap).text;
  } on Object {
    // NotFoundException etc. — no readable QR in the image.
    return null;
  }
}
