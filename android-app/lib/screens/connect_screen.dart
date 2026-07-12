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
  Timer? _searchClock;
  StreamSubscription? _discoverSub;
  StreamSubscription? _statusSub;
  bool _connecting = false;
  String? _error;
  int _secondsSearching = 0;
  List<String> _myAddresses = [];

  @override
  void initState() {
    super.initState();
    _discoverSub = _socket.discoveredStream.listen((host) {
      setState(() => _found[host.address] = host);
    });
    _statusSub = _socket.statusStream.listen(_onStatus);
    _socket.localAddresses().then((addrs) {
      if (mounted) setState(() => _myAddresses = addrs);
    });
    _startDiscovery();
  }

  void _startDiscovery() {
    setState(() => _secondsSearching = 0);
    _socket.discover();
    _discoverTimer?.cancel();
    _discoverTimer = Timer.periodic(const Duration(seconds: 2), (_) => _socket.discover());
    _searchClock?.cancel();
    _searchClock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsSearching++);
    });
  }

  void _onStatus(ConnectionStatus status) {
    if (!mounted) return;
    if (status == ConnectionStatus.connected) {
      setState(() => _connecting = false);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GamepadScreen(socket: _socket),
      )).then((_) {
        setState(() => _error = null);
        _found.clear();
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
    _searchClock?.cancel();
    setState(() {
      _connecting = true;
      _error = null;
    });
    await _socket.connect(ip, deviceName: 'Phone');

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _connecting) {
        setState(() {
          _connecting = false;
          _error = 'No response from $ip.\n\n'
              '• Make sure VirtualGamepadHost.exe is running on the PC\n'
              '• Confirm both devices are on the same WiFi network\n'
              '• Check Windows Firewall allowed the app (all network types)\n'
              '• Port ${Protocol.port}/UDP must be reachable';
        });
      }
    });
  }

  @override
  void dispose() {
    _discoverTimer?.cancel();
    _searchClock?.cancel();
    _discoverSub?.cancel();
    _statusSub?.cancel();
    _socket.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1033), Color(0xFF0B0B14)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.sports_esports, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Virtual Gamepad',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        Text('Free & open source · WiFi controller',
                            style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Nearby PCs',
                trailing: _found.isEmpty
                    ? null
                    : TextButton.icon(
                        onPressed: () {
                          setState(() => _found.clear());
                          _startDiscovery();
                        },
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
                        label: const Text('Refresh', style: TextStyle(color: Colors.white54)),
                      ),
              ),
              const SizedBox(height: 10),
              if (_found.isEmpty) _SearchingCard(seconds: _secondsSearching, onRetry: _startDiscovery),
              ..._found.values.map((h) => _HostCard(
                    host: h,
                    connecting: _connecting,
                    onTap: _connecting ? null : () => _connectTo(h.address),
                  )),
              const SizedBox(height: 28),
              const _SectionHeader(title: 'Enter PC IP manually'),
              const SizedBox(height: 10),
              _ManualEntryCard(
                controller: _ipController,
                connecting: _connecting,
                onConnect: () => _connectTo(_ipController.text.trim()),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12.5, height: 1.4)),
                ),
              ],
              if (_myAddresses.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('This phone: ${_myAddresses.join(", ")}',
                    style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SearchingCard extends StatelessWidget {
  final int seconds;
  final VoidCallback onRetry;
  const _SearchingCard({required this.seconds, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final stuck = seconds >= 6;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Searching your WiFi network for PCs running Virtual Gamepad Host...',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
              ),
            ],
          ),
          if (stuck) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),
            Text(
              "Not finding it? Some routers block automatic discovery (guest WiFi, "
              "mesh networks, or \"AP isolation\" settings). Enter the PC's IP shown "
              "in its console window below instead - it always works.",
              style: TextStyle(color: Colors.amber.withOpacity(0.85), fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Search again'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  final DiscoveredHost host;
  final bool connecting;
  final VoidCallback? onTap;
  const _HostCard({required this.host, required this.connecting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6366F1).withOpacity(0.18),
                  ),
                  child: const Icon(Icons.computer, color: Color(0xFF9F8CFF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(host.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      Text(host.address, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                connecting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualEntryCard extends StatelessWidget {
  final TextEditingController controller;
  final bool connecting;
  final VoidCallback onConnect;
  const _ManualEntryCard({required this.controller, required this.connecting, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.dns_outlined, color: Colors.white38, size: 20),
              hintText: '192.168.1.42',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              return SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: connecting || !hasText ? null : onConnect,
                  child: connecting
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Connect', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
