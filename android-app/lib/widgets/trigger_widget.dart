import 'package:flutter/material.dart';

/// A vertical pressure-style slider for LT/RT. Drag down = more pressure,
/// releasing snaps back to 0, matching a spring-loaded analog trigger.
class TriggerWidget extends StatefulWidget {
  final String label;
  final double width;
  final double height;
  final void Function(double value) onChanged;

  const TriggerWidget({
    super.key,
    required this.label,
    required this.onChanged,
    this.width = 56,
    this.height = 90,
  });

  @override
  State<TriggerWidget> createState() => _TriggerWidgetState();
}

class _TriggerWidgetState extends State<TriggerWidget> {
  double _value = 0;

  void _update(Offset local) {
    final v = (local.dy / widget.height).clamp(0.0, 1.0);
    setState(() => _value = v);
    widget.onChanged(v);
  }

  void _reset() {
    setState(() => _value = 0);
    widget.onChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.width,
            height: widget.height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: _value,
                child: Container(color: Colors.white.withOpacity(0.75)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(widget.label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ],
      ),
    );
  }
}
