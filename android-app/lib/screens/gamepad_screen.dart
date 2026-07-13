import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/gamepad_state.dart';
import '../network/gamepad_socket.dart';
import '../network/protocol.dart';
import '../theme.dart';
import '../widgets/dpad_widget.dart';
import '../widgets/gamepad_button_widget.dart';
import '../widgets/joystick_widget.dart';
import '../widgets/trigger_widget.dart';

/// Matches the exact control layout from the reference mockup: LT/RB/D-pad
/// stacked on the far left, a Back/Guide/Start icon row + L3/R3 pills in the
/// upper middle, dual sticks either side of center, RB/RT on the upper
/// right, and the ABXY diamond on the lower right. Landscape-only - see
/// initState/dispose.
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
    // Every other screen in the app is portrait-only, so lock straight back
    // to portrait here rather than "allow everything" - avoids a frame or
    // two of sideways UI while ConnectScreen's own re-lock kicks in.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _disconnect() {
    widget.socket.disconnect();
    Navigator.of(context).pop();
  }

  /// Positions a child using fractional (0-1) coordinates of the *center*
  /// of the control, matching how the reference mockup was measured, so
  /// the whole layout scales cleanly across phone screen sizes.
  Widget _at(BoxConstraints c, double xFrac, double yFrac, double w, double h, Widget child) {
    final left = c.maxWidth * xFrac - w / 2;
    final top = c.maxHeight * yFrac - h / 2;
    return Positioned(left: left, top: top, width: w, height: h, child: Center(child: child));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gamepadBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.4,
            colors: [AppColors.gamepadTop, AppColors.gamepadBottom],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final c = constraints;
              return Stack(
                children: [
                  // LT - top left, biggest circle on that side
                  _at(c, 0.078, 0.182, 112, 112,
                      TriggerWidget(label: 'LT', size: 112, onChanged: (v) => _state.setLeftTrigger(v))),

                  // LB - below LT
                  _at(c, 0.184, 0.339, 70, 70,
                      GamepadButtonWidget(
                        label: 'LB',
                        size: 70,
                        color: AppColors.stickFill,
                        onChanged: (p) => _state.setButton(Protocol.bitLb, p),
                      )),

                  // D-pad - lower left
                  _at(c, 0.112, 0.620, 180, 180,
                      DpadWidget(
                        size: 150,
                        onChanged: ({required up, required down, required left, required right}) {
                          _state.setDpad(up: up, down: down, left: left, right: right);
                        },
                      )),

                  // Disconnect - small circle, top center
                  _at(c, 0.470, 0.068, 50, 50,
                      GestureDetector(
                        onTap: _disconnect,
                        child: Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.stickFill, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 22),
                        ),
                      )),

                  // Back / Guide / Start row - upper middle
                  _at(c, 0.371, 0.242, 60, 60,
                      GamepadButtonWidget(
                        label: '',
                        icon: Icons.menu,
                        size: 60,
                        color: AppColors.stickFill,
                        onChanged: (p) => _state.setButton(Protocol.bitBack, p),
                      )),
                  _at(c, 0.470, 0.242, 68, 68,
                      GamepadButtonWidget(
                        label: '',
                        icon: Icons.sports_esports,
                        size: 68,
                        color: AppColors.stickFill,
                        onChanged: (p) => _state.setButton(Protocol.bitGuide, p),
                      )),
                  _at(c, 0.570, 0.242, 60, 60,
                      GamepadButtonWidget(
                        label: '',
                        icon: Icons.tune,
                        size: 60,
                        color: AppColors.stickFill,
                        onChanged: (p) => _state.setButton(Protocol.bitStart, p),
                      )),

                  // L3 / R3 - pills just above the sticks
                  _at(c, 0.416, 0.475, 90, 56,
                      GamepadButtonWidget(
                        label: 'LEFT',
                        pill: true,
                        size: 40,
                        color: AppColors.stickFill,
                        onChanged: (p) => _state.setButton(Protocol.bitLsClick, p),
                      )),
                  _at(c, 0.526, 0.475, 90, 56,
                      GamepadButtonWidget(
                        label: 'RIGHT',
                        pill: true,
                        size: 40,
                        color: AppColors.stickFill,
                        onChanged: (p) => _state.setButton(Protocol.bitRsClick, p),
                      )),

                  // Left stick
                  _at(c, 0.310, 0.751, 160, 160,
                      JoystickWidget(size: 160, onChanged: (x, y) => _state.setLeftStick(x, y))),

                  // Right stick
                  _at(c, 0.685, 0.751, 160, 160,
                      JoystickWidget(size: 160, onChanged: (x, y) => _state.setRightStick(x, y))),

                  // RB - upper right
                  _at(c, 0.815, 0.346, 70, 70,
                      GamepadButtonWidget(
                        label: 'RB',
                        size: 70,
                        color: AppColors.stickFill,
                        onChanged: (p) => _state.setButton(Protocol.bitRb, p),
                      )),

                  // RT - top right corner, biggest circle on that side
                  _at(c, 0.922, 0.182, 112, 112,
                      TriggerWidget(label: 'RT', size: 112, onChanged: (v) => _state.setRightTrigger(v))),

                  // ABXY diamond
                  _at(c, 0.890, 0.620, 150, 150, _FaceButtons(state: _state, size: 150)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
class _FaceButtons extends StatelessWidget {
  final GamepadState state;
  final double size;
  const _FaceButtons({required this.state, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: GamepadButtonWidget(
              label: 'Y',
              color: AppColors.buttonY,
              onChanged: (p) => state.setButton(Protocol.bitY, p),
            ),
          ),
          Positioned(
            bottom: 0,
            child: GamepadButtonWidget(
              label: 'A',
              color: AppColors.buttonA,
              onChanged: (p) => state.setButton(Protocol.bitA, p),
            ),
          ),
          Positioned(
            left: 0,
            child: GamepadButtonWidget(
              label: 'X',
              color: AppColors.buttonX,
              onChanged: (p) => state.setButton(Protocol.bitX, p),
            ),
          ),
          Positioned(
            right: 0,
            child: GamepadButtonWidget(
              label: 'B',
              color: AppColors.buttonB,
              onChanged: (p) => state.setButton(Protocol.bitB, p),
            ),
          ),
        ],
      ),
    );
  }
}
