import 'package:flutter/material.dart';
import 'package:virtual_gamepad/theme.dart';

class DpadWidget extends StatefulWidget {
  final double size;
  final void Function({required bool up, required bool down, required bool left, required bool right}) onChanged;

  const DpadWidget({super.key, required this.onChanged, this.size = 140});

  @override
  State<DpadWidget> createState() => _DpadWidgetState();
}

class _DpadWidgetState extends State<DpadWidget> {
  bool up = false, down = false, left = false, right = false;

  void _update(Offset local) {
    final s = widget.size;
    final center = Offset(s / 2, s / 2);
    final rel = local - center;
    
    // A proportional deadzone makes scaling the size much safer
    final deadzone = s * 0.12; 

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

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _DpadPainter(up: up, down: down, left: left, right: right),
        ),
      ),
    );
  }
}

class _DpadPainter extends CustomPainter {
  final bool up, down, left, right;
  _DpadPainter({required this.up, required this.down, required this.left, required this.right});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // 1. Draw Outer Tactile Rim
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.black.withOpacity(0.4),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, rimPaint);

    // 2. Draw Main D-pad Body (Slightly smaller than rim)
  final bodyRadius = radius * 0.92;
    final bodyPaint = Paint()
      ..color = AppColors.stickFill 
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, bodyRadius, bodyPaint);

    // 3. Arrow Calculations & Geometry
    final arrowSize = radius * 0.22;
    final offset = radius * 0.62;

    _drawDirectionalArrow(canvas, center - Offset(0, offset), arrowSize, _Dir.up, up);
    _drawDirectionalArrow(canvas, center + Offset(0, offset), arrowSize, _Dir.down, down);
    _drawDirectionalArrow(canvas, center - Offset(offset, 0), arrowSize, _Dir.left, left);
    _drawDirectionalArrow(canvas, center + Offset(offset, 0), arrowSize, _Dir.right, right);
  }

  void _drawDirectionalArrow(Canvas canvas, Offset center, double s, _Dir dir, bool isActive) {
    // Active states glow vividly; idle states are clean, muted semi-transparents
    final arrowPaint = Paint()
      ..color = isActive ? AppColors.activeAccent : Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = isActive ? const MaskFilter.blur(BlurStyle.solid, 2) : null;

    final path = Path();
    switch (dir) {
      case _Dir.up:
        path.moveTo(center.dx, center.dy - s * 0.6);
        path.lineTo(center.dx - s, center.dy + s * 0.5);
        path.lineTo(center.dx, center.dy + s * 0.1); // Sleek chevron indentation
        path.lineTo(center.dx + s, center.dy + s * 0.5);
        break;
      case _Dir.down:
        path.moveTo(center.dx, center.dy + s * 0.6);
        path.lineTo(center.dx - s, center.dy - s * 0.5);
        path.lineTo(center.dx, center.dy - s * 0.1);
        path.lineTo(center.dx + s, center.dy - s * 0.5);
        break;
      case _Dir.left:
        path.moveTo(center.dx - s * 0.6, center.dy);
        path.lineTo(center.dx + s * 0.5, center.dy - s);
        path.lineTo(center.dx + s * 0.1, center.dy);
        path.lineTo(center.dx + s * 0.5, center.dy + s);
        break;
      case _Dir.right:
        path.moveTo(center.dx + s * 0.6, center.dy);
        path.lineTo(center.dx - s * 0.5, center.dy - s);
        path.lineTo(center.dx - s * 0.1, center.dy);
        path.lineTo(center.dx - s * 0.5, center.dy + s);
        break;
    }
    path.close();
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _DpadPainter oldDelegate) =>
      oldDelegate.up != up || oldDelegate.down != down || oldDelegate.left != left || oldDelegate.right != right;
}

enum _Dir { up, down, left, right }