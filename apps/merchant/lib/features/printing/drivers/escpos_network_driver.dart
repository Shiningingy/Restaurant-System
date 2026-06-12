import 'dart:async';
import 'dart:io';

import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// ESC/POS over raw TCP ("JetDirect", port 9100) — the protocol every
/// LAN thermal printer speaks. Works on all platforms, which is why it
/// ships before Bluetooth (docs/ROADMAP.md Phase 2).
///
/// This file is the only place allowed to open printer sockets
/// (docs/PRINCIPLES.md — hardware abstraction).
class EscPosNetworkDriver implements domain.PrinterDriver {
  final String host;
  final int port;
  final Duration timeout;

  @override
  final domain.PrinterCapabilities capabilities;

  EscPosNetworkDriver({
    required this.host,
    this.port = 9100,
    required int paperWidthChars,
    this.timeout = const Duration(seconds: 5),
  }) : capabilities = domain.PrinterCapabilities(
         paperWidthChars: paperWidthChars,
         supportsCut: true,
         transport: domain.PrinterTransport.network,
       );

  @override
  Future<domain.Result<void, domain.PrintError>> printJob(
    domain.PrintJobData job,
  ) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      socket.add(job.payload);
      await socket.flush().timeout(timeout);
      return const domain.Ok(null);
    } on SocketException catch (e) {
      return domain.Err(
        domain.PrintError('Printer unreachable at $host:$port (${e.message})'),
      );
    } on TimeoutException {
      return domain.Err(domain.PrintError('Printer at $host:$port timed out'));
    } finally {
      socket?.destroy();
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
