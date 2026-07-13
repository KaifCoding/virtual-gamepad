import 'dart:async';
import 'dart:io';
import 'protocol.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

/// Owns the UDP socket used for both discovery and streaming input to the PC.
class GamepadSocket {
  RawDatagramSocket? _socket;
  InternetAddress? _pcAddress;
  int _sequence = 0;
  Timer? _heartbeatTimer;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _discoveredController = StreamController<DiscoveredHost>.broadcast();

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<DiscoveredHost> get discoveredStream => _discoveredController.stream;

  ConnectionStatus status = ConnectionStatus.disconnected;

  Future<void> _ensureSocket() async {
    if (_socket != null) return;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.broadcastEnabled = true;
    _socket!.listen(_onEvent);
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;
    final reply = parseReply(datagram.data);
    if (reply == null) return;

    if (reply.type == Protocol.typeDiscoverResponse && reply.hostName != null) {
      _discoveredController.add(DiscoveredHost(
        name: reply.hostName!,
        address: datagram.address.address,
      ));
    } else if (reply.type == Protocol.typeHelloAck) {
      _setStatus(reply.helloOk == true
          ? ConnectionStatus.connected
          : ConnectionStatus.error);
    }
  }

  void _setStatus(ConnectionStatus s) {
    status = s;
    _statusController.add(s);
  }

  /// Broadcasts a DISCOVER packet on every local IPv4 interface's subnet.
  /// Sending only to 255.255.255.255 misses some phones/routers (dual
  /// WiFi+mobile-data routing, some OEM network stacks), so we also compute
  /// each interface's own directed broadcast address (e.g. 192.168.1.255)
  /// and send there too. Call repeatedly (e.g. every second) while the
  /// "searching" UI is open; discovered hosts arrive via [discoveredStream].
  Future<void> discover() async {
    await _ensureSocket();
    final packet = PacketBuilder.discover();

    final targets = <String>{'255.255.255.255'};
    try {
      for (final iface in await NetworkInterface.list(
          includeLoopback: false, type: InternetAddressType.IPv4)) {
        for (final addr in iface.addresses) {
          final b = _directedBroadcastFor(addr.address);
          if (b != null) targets.add(b);
        }
      }
    } catch (_) {
      // NetworkInterface.list can fail on some devices/permissions setups;
      // the global broadcast address above still gets tried.
    }

    for (final target in targets) {
      try {
        _socket!.send(packet, InternetAddress(target), Protocol.port);
      } catch (_) {
        // A given target may be unreachable; keep trying the others.
      }
    }
  }

  /// Assumes a /24 subnet (by far the most common on home/office WiFi) and
  /// returns e.g. "192.168.1.255" for "192.168.1.37". Good-enough heuristic
  /// without needing a plugin to read the real subnet mask.
  String? _directedBroadcastFor(String ipv4) {
    final parts = ipv4.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }

  /// Local IPv4 addresses of this phone, for troubleshooting UI ("make sure
  /// this matches the PC's subnet").
  Future<List<String>> localAddresses() async {
    try {
      final ifaces = await NetworkInterface.list(
          includeLoopback: false, type: InternetAddressType.IPv4);
      return [for (final i in ifaces) for (final a in i.addresses) a.address];
    } catch (_) {
      return [];
    }
  }

  /// Connects to a specific PC by IP address (from discovery or manual entry).
  Future<void> connect(String ipAddress, {String deviceName = 'Phone'}) async {
    await _ensureSocket();
    _pcAddress = InternetAddress(ipAddress);
    _setStatus(ConnectionStatus.connecting);
    _socket!.send(PacketBuilder.hello(deviceName), _pcAddress!, Protocol.port);

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_pcAddress == null) return;
      // Only send an explicit heartbeat if we haven't sent *any* packet
      // (input included) recently - input already counts as liveness.
      if (DateTime.now().difference(_lastSent).inMilliseconds > 500) {
        _socket?.send(PacketBuilder.heartbeat(), _pcAddress!, Protocol.port);
        _lastSent = DateTime.now();
      }
    });
  }

  /// Sends one INPUT frame. Call this at a steady rate (e.g. 60Hz) from a
  /// ticker while the gamepad screen is open.
  void sendInput({
    required int buttons,
    required double lx,
    required double ly,
    required double rx,
    required double ry,
    required double lt,
    required double rt,
  }) {
    if (_socket == null || _pcAddress == null) return;
    final packet = PacketBuilder.input(
      buttons: buttons,
      lx: lx,
      ly: ly,
      rx: rx,
      ry: ry,
      lt: lt,
      rt: rt,
      sequence: _sequence++,
    );
    _socket!.send(packet, _pcAddress!, Protocol.port);
    _lastSent = DateTime.now();
  }

  void disconnect() {
    if (_socket != null && _pcAddress != null) {
      _socket!.send(PacketBuilder.goodbye(), _pcAddress!, Protocol.port);
    }
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pcAddress = null;
    _setStatus(ConnectionStatus.disconnected);

  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _socket?.close();
    _statusController.close();
    _discoveredController.close();
  }
}
