import 'dart:async';

import 'package:flutter/material.dart';

import '../network/gamepad_socket.dart';
import '../network/protocol.dart';
import 'gamepad_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final GamepadSocket _socket = GamepadSocket();
  final TextEditingController _ipController = TextEditingController();
  final Map<String, DiscoveredHost> _found = {}; // address -> host
  Timer? _discoverTimer;
  StreamSubscription? _discoverSub;
  StreamSubscription? _statusSub;
  bool _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _discoverSub = _socket.discoveredStream.listen((host) {
      setState(() => _found[host.address] = host);
    });
    _statusSub = _socket.statusStream.listen(_onStatus);
    _startDiscovery();
  }

  void _startDiscovery() {
    _socket.discover();
    _discoverTimer?.cancel();
    _discoverTimer = Timer.periodic(const Duration(seconds: 2), (_) => _socket.discover());
  }

  void _onStatus(ConnectionStatus status) {
    if (!mounted) return;
    if (status == ConnectionStatus.connected) {
      setState(() => _connecting = false);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GamepadScreen(socket: _socket),
      )).then((_) {
        // Returned from gamepad screen (user disconnected) - resume discovery.
        setState(() => _error = null);
        _startDiscovery();
      });
    } else if (status == ConnectionStatus.error) {
      setState(() {
        _connecting = false;
        _error = 'PC rejected the connection. Is ViGEmBus installed there?';
      });
    }
  }

  Future<void> _connectTo(String ip) async {
    _discoverTimer?.cancel();
    setState(() {
      _connecting = true;
      _error = null;
    });
    await _socket.connect(ip, deviceName: 'Phone');

    // Give the PC a moment to reply; if nothing comes back, tell the user.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _connecting) {
        setState(() {
          _connecting = false;
          _error = 'No response from $ip. Check the IP, and that both devices '
              'are on the same WiFi network with port ${Protocol.port} allowed through the firewall.';
        });
      }
    });
  }

  @override
  void dispose() {
    _discoverTimer?.cancel();
    _discoverSub?.cancel();
    _statusSub?.cancel();
    _socket.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Virtual Gamepad'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nearby PCs', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: _found.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Searching for PCs running Virtual Gamepad Host on your WiFi...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                  : ListView(
                      children: _found.values
                          .map((h) => Card(
                                color: Colors.white10,
                                child: ListTile(
                                  leading: const Icon(Icons.computer, color: Colors.white70),
                                  title: Text(h.name, style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(h.address, style: const TextStyle(color: Colors.white38)),
                                  trailing: _connecting
                                      ? const SizedBox(
                                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                                  onTap: _connecting ? null : () => _connectTo(h.address),
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            const Text('Or enter PC IP manually', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '192.168.1.42',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _connecting || _ipController.text.trim().isEmpty
                      ? null
                      : () => _connectTo(_ipController.text.trim()),
                  child: const Text('Connect'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
