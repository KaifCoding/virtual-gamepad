import 'package:flutter/material.dart';

/// A round (or pill-shaped) button that reports press/release rather than
/// just tap, which is what a gamepad button needs (held == active).
class GamepadButtonWidget extends StatefulWidget {
  final String label;
  final Color color;
  final double size;
  final void Function(bool pressed) onChanged;
  final bool pill;

  const GamepadButtonWidget({
    super.key,
    required this.label,
    required this.onChanged,
    this.color = Colors.white,
    this.size = 56,
    this.pill = false,
  });

  @override
  State<GamepadButtonWidget> createState() => _GamepadButtonWidgetState();
}

class _GamepadButtonWidgetState extends State<GamepadButtonWidget> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.pill ? widget.size * 1.8 : widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _pressed ? widget.color.withOpacity(0.9) : widget.color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(widget.pill ? widget.size / 2 : widget.size / 2),
          border: Border.all(color: widget.color.withOpacity(0.6), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            color: _pressed ? Colors.black : Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.bold,
            fontSize: widget.pill ? 12 : 18,
          ),
        ),
      ),
    );
  }
}
