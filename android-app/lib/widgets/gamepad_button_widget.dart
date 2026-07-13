import 'package:flutter/material.dart';

/// A round (or pill-shaped) button that reports press/release rather than
/// just tap, which is what a gamepad button needs (held == active). Solid
/// fill by default, brightening slightly on press, matching the design's
/// bold saturated button style.
class GamepadButtonWidget extends StatefulWidget {
  final String label;
  final Color color;
  final double size;
  final void Function(bool pressed) onChanged;
  final bool pill;
  final bool solid;
  final IconData? icon;

  const GamepadButtonWidget({
    super.key,
    required this.label,
    required this.onChanged,
    this.color = Colors.white,
    this.size = 56,
    this.pill = false,
    this.solid = true,
    this.icon,
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
    final baseColor = widget.solid ? widget.color : widget.color.withOpacity(0.18);
    final pressedColor = widget.solid ? Color.lerp(widget.color, Colors.white, 0.35)! : widget.color.withOpacity(0.9);

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.pill ? widget.size * 1.8 : widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _pressed ? pressedColor : baseColor,
          borderRadius: BorderRadius.circular(widget.size / 2),
          boxShadow: widget.solid
              ? [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        alignment: Alignment.center,
        child: widget.icon != null
            ? Icon(widget.icon, color: Colors.white, size: widget.size * 0.5)
            : Text(
                widget.label,
                style: TextStyle(
                  color: widget.solid ? Colors.white : (_pressed ? Colors.black : Colors.white.withOpacity(0.85)),
                  fontWeight: FontWeight.bold,
                  fontSize: widget.pill ? 12 : 18,
                ),
              ),
      ),
    );
  }
}
