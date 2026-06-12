import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/printing/drivers/escpos_network_driver.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

void main() {
  test('delivers the payload to a listening printer', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final received = Completer<List<int>>();
    server.listen((client) {
      final bytes = <int>[];
      client.listen(
        bytes.addAll,
        onDone: () {
          // testConnection() opens a probe connection that sends nothing;
          // only the real print job carries bytes.
          if (bytes.isNotEmpty && !received.isCompleted) {
            received.complete(bytes);
          }
        },
      );
    });

    final driver = EscPosNetworkDriver(
      host: server.address.address,
      port: server.port,
      paperWidthChars: 48,
    );
    final payload = [0x1B, 0x40, 0x48, 0x49, 0x0A];

    expect(await driver.testConnection(), isTrue);
    final result = await driver.printJob(
      domain.PrintJobData(
        id: 'j1',
        kind: domain.PrintJobKind.testPage,
        payload: payload,
      ),
    );

    expect(result.isOk, isTrue);
    expect(await received.future, payload);
    await server.close();
  });

  test('reports a retryable error when nothing is listening', () async {
    // Bind then close to get a port that is certainly unused.
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final deadPort = probe.port;
    await probe.close();

    final driver = EscPosNetworkDriver(
      host: InternetAddress.loopbackIPv4.address,
      port: deadPort,
      paperWidthChars: 48,
      timeout: const Duration(seconds: 2),
    );

    expect(await driver.testConnection(), isFalse);
    final result = await driver.printJob(
      const domain.PrintJobData(
        id: 'j1',
        kind: domain.PrintJobKind.testPage,
        payload: [0x00],
      ),
    );
    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.isRetryable, isTrue);
  });
}
