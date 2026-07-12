import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/gamepad_state.dart';
import '../network/gamepad_socket.dart';
import '../network/protocol.dart';
import '../widgets/dpad_widget.dart';
import '../widgets/gamepad_button_widget.dart';
import '../widgets/joystick_widget.dart';
import '../widgets/trigger_widget.dart';

class GamepadScreen extends StatefulWidget {
  final GamepadSocket socket;
  const GamepadScreen({super.key, required this.socket});

  @override
  State<GamepadScreen> createState() => _GamepadScreenState();
}

class _GamepadScreenState extends State<GamepadScreen> {
  late final GamepadState _state;

  @override
  void initState() {
    super.initState();
    _state = GamepadState(widget.socket);
    _state.start();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _state.stop();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _disconnect() {
    widget.socket.disconnect();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.4,
            colors: [Color(0xFF1A1033), Color(0xFF0B0B14)],
          ),
        ),
        child: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // Left cluster: stick + d-pad, stacked
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      JoystickWidget(
                        label: 'LS',
                        onChanged: (x, y) {
                          _state.setLeftStick(x, y);
                        },
                      ),
                      DpadWidget(
                        onChanged: ({required up, required down, required left, required right}) {
                          _state.setDpad(up: up, down: down, left: left, right: right);
                        },
                      ),
                    ],
                  ),
                ),
                // Center cluster: triggers/shoulders + start/back
                SizedBox(
                  width: 130,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TriggerWidget(label: 'LT', onChanged: (v) => _state.setLeftTrigger(v)),
                          TriggerWidget(label: 'RT', onChanged: (v) => _state.setRightTrigger(v)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GamepadButtonWidget(
                            label: 'LB',
                            pill: true,
                            size: 26,
                            onChanged: (p) => _state.setButton(Protocol.bitLb, p),
                          ),
                          GamepadButtonWidget(
                            label: 'RB',
                            pill: true,
                            size: 26,
                            onChanged: (p) => _state.setButton(Protocol.bitRb, p),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GamepadButtonWidget(
                            label: 'BACK',
                            pill: true,
                            size: 22,
                            onChanged: (p) => _state.setButton(Protocol.bitBack, p),
                          ),
                          GamepadButtonWidget(
                            label: 'START',
                            pill: true,
                            size: 22,
                            onChanged: (p) => _state.setButton(Protocol.bitStart, p),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right cluster: face buttons + stick
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FaceButtons(state: _state),
                      JoystickWidget(
                        label: 'RS',
                        onChanged: (x, y) {
                          _state.setRightStick(x, y);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white38),
                onPressed: _disconnect,
                tooltip: 'Disconnect',
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

/// The diamond of A/B/X/Y face buttons.
class _FaceButtons extends StatelessWidget {
  final GamepadState state;
  const _FaceButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: GamepadButtonWidget(
              label: 'Y',
              color: Colors.amber,
              onChanged: (p) => state.setButton(Protocol.bitY, p),
            ),
          ),
          Positioned(
            bottom: 0,
            child: GamepadButtonWidget(
              label: 'A',
              color: Colors.green,
              onChanged: (p) => state.setButton(Protocol.bitA, p),
            ),
          ),
          Positioned(
            left: 0,
            child: GamepadButtonWidget(
              label: 'X',
              color: Colors.blue,
              onChanged: (p) => state.setButton(Protocol.bitX, p),
            ),
          ),
          Positioned(
            right: 0,
            child: GamepadButtonWidget(
              label: 'B',
              color: Colors.red,
              onChanged: (p) => state.setButton(Protocol.bitB, p),
            ),
          ),
        ],
      ),
    );
  }
}
