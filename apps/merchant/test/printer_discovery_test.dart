import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/printing/data/printer_discovery.dart';

void main() {
  test('DiscoveredPrinter has value equality', () {
    expect(
      const DiscoveredPrinter('192.168.1.50', 9100),
      const DiscoveredPrinter('192.168.1.50', 9100),
    );
    expect(
      const DiscoveredPrinter('192.168.1.50', 9100),
      isNot(const DiscoveredPrinter('192.168.1.51', 9100)),
    );
  });

  test('canReach finds a listening socket and rejects a closed port', () async {
    // Stand in for a printer: a server listening on the loopback interface.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close());
    server.listen((socket) => socket.destroy());

    final discovery = PrinterDiscovery(
      port: server.port,
      probeTimeout: const Duration(seconds: 2),
    );

    expect(await discovery.canReach('127.0.0.1'), isTrue);

    // A port nobody is listening on connects-refused → not reachable.
    final closed = PrinterDiscovery(
      port: server.port,
      probeTimeout: const Duration(milliseconds: 300),
    );
    await server.close();
    expect(await closed.canReach('127.0.0.1'), isFalse);
  });

  test('localPrefixes returns dotted /24 prefixes without throwing', () async {
    final prefixes = await PrinterDiscovery().localPrefixes();
    for (final p in prefixes) {
      expect(p.split('.'), hasLength(3));
    }
  });
}
