import 'package:flutter/material.dart';

/// A classic 4-way D-pad. Reports which directions are currently held;
/// diagonals work naturally since up/down and left/right are independent.
class DpadWidget extends StatefulWidget {
  final double size;
  final void Function({required bool up, required bool down, required bool left, required bool right}) onChanged;

  const DpadWidget({super.key, required this.onChanged, this.size = 120});

  @override
  State<DpadWidget> createState() => _DpadWidgetState();
}

class _DpadWidgetState extends State<DpadWidget> {
  bool up = false, down = false, left = false, right = false;

  void _update(Offset local) {
    final s = widget.size;
    final center = Offset(s / 2, s / 2);
    final rel = local - center;
    const deadzone = 14.0;

    final newUp = rel.dy < -deadzone;
    final newDown = rel.dy > deadzone;
    final newLeft = rel.dx < -deadzone;
    final newRight = rel.dx > deadzone;

    if (newUp != up || newDown != down || newLeft != left || newRight != right) {
      setState(() {
        up = newUp;
        down = newDown;
        left = newLeft;
        right = newRight;
      });
      widget.onChanged(up: up, down: down, left: left, right: right);
    }
  }

  void _reset() {
    setState(() => up = down = left = right = false);
    widget.onChanged(up: false, down: false, left: false, right: false);
  }

  Widget _arrow(IconData icon, bool active) => Icon(
        icon,
        size: 22,
        color: active ? Colors.black : Colors.white.withOpacity(0.7),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
              ),
            ),
            Positioned(
              top: 4,
              child: Container(
                width: s * 0.32,
                height: s * 0.32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: up ? Colors.white.withOpacity(0.85) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8)),
                child: _arrow(Icons.keyboard_arrow_up, up),
              ),
            ),
            Positioned(
              bottom: 4,
              child: Container(
                width: s * 0.32,
                height: s * 0.32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: down ? Colors.white.withOpacity(0.85) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8)),
                child: _arrow(Icons.keyboard_arrow_down, down),
              ),
            ),
            Positioned(
              left: 4,
              child: Container(
                width: s * 0.32,
                height: s * 0.32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: left ? Colors.white.withOpacity(0.85) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8)),
                child: _arrow(Icons.keyboard_arrow_left, left),
              ),
            ),
            Positioned(
              right: 4,
              child: Container(
                width: s * 0.32,
                height: s * 0.32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: right ? Colors.white.withOpacity(0.85) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8)),
                child: _arrow(Icons.keyboard_arrow_right, right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
