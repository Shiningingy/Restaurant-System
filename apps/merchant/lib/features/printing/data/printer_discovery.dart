import 'dart:async';
import 'dart:io';

/// A network printer found on the local network.
class DiscoveredPrinter {
  final String host;
  final int port;

  const DiscoveredPrinter(this.host, this.port);

  @override
  bool operator ==(Object other) =>
      other is DiscoveredPrinter && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}

/// Finds ESC/POS network printers by probing the raw-print port (9100) across
/// every active local IPv4 subnet — so it discovers both wired and **Wi-Fi**
/// printers in one pass (each interface, incl. the wireless one, is scanned).
///
/// Pure dart:io, so it runs the same on Windows and Android. Bluetooth printers
/// are a separate transport (no driver yet) and are not covered here.
class PrinterDiscovery {
  final int port;
  final Duration probeTimeout;

  /// How many hosts to probe at once. A /24 is 254 hosts; batching keeps the
  /// open-socket count bounded while staying fast.
  final int concurrency;

  PrinterDiscovery({
    this.port = 9100,
    this.probeTimeout = const Duration(milliseconds: 400),
    this.concurrency = 64,
  });

  /// The /24 prefixes (e.g. `192.168.1`) of every active, non-loopback IPv4
  /// interface — one scan target each, covering Ethernet and Wi-Fi alike.
  Future<List<String>> localPrefixes() async {
    final prefixes = <String>{};
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length == 4) {
          prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    }
    return prefixes.toList();
  }

  /// Streams printers as they're found, so the UI can show results live.
  Stream<DiscoveredPrinter> discover() async* {
    final prefixes = await localPrefixes();
    final hosts = [
      for (final prefix in prefixes)
        for (var i = 1; i <= 254; i++) '$prefix.$i',
    ];
    for (var i = 0; i < hosts.length; i += concurrency) {
      final batch = hosts.skip(i).take(concurrency).toList();
      final reachable = await Future.wait(batch.map(canReach));
      for (var j = 0; j < batch.length; j++) {
        if (reachable[j]) yield DiscoveredPrinter(batch[j], port);
      }
    }
  }

  /// True if a short-lived socket to [host] on [port] connects — i.e. something
  /// is listening on the raw-print port, almost always a printer.
  Future<bool> canReach(String host) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: probeTimeout);
      return true;
    } on Object {
      return false;
    } finally {
      socket?.destroy();
    }
  }
}
