import 'package:flutter/material.dart';

import '../theme.dart';

/// A classic 4-way D-pad rendered as a solid filled circle with triangular
/// arrows, matching the design. Reports which directions are currently
/// held; diagonals work naturally since up/down and left/right are
/// independent.
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
    const deadzone = 16.0;

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
      child: SizedBox(
        width: s,
        height: s,
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

    final basePaint = Paint()..color = AppColors.stickFill;
    canvas.drawCircle(center, radius, basePaint);

    final arrowPaint = Paint()..color = Colors.white;
    final activePaint = Paint()..color = Colors.white.withOpacity(0.55);
    final arrowSize = radius * 0.32;
    final offset = radius * 0.5;

    _drawTriangle(canvas, center - Offset(0, offset), arrowSize, _Dir.up, up ? activePaint : arrowPaint);
    _drawTriangle(canvas, center + Offset(0, offset), arrowSize, _Dir.down, down ? activePaint : arrowPaint);
    _drawTriangle(canvas, center - Offset(offset, 0), arrowSize, _Dir.left, left ? activePaint : arrowPaint);
    _drawTriangle(canvas, center + Offset(offset, 0), arrowSize, _Dir.right, right ? activePaint : arrowPaint);
  }

  void _drawTriangle(Canvas canvas, Offset center, double s, _Dir dir, Paint paint) {
    final path = Path();
    switch (dir) {
      case _Dir.up:
        path.moveTo(center.dx, center.dy - s);
        path.lineTo(center.dx - s, center.dy + s * 0.7);
        path.lineTo(center.dx + s, center.dy + s * 0.7);
        break;
      case _Dir.down:
        path.moveTo(center.dx, center.dy + s);
        path.lineTo(center.dx - s, center.dy - s * 0.7);
        path.lineTo(center.dx + s, center.dy - s * 0.7);
        break;
      case _Dir.left:
        path.moveTo(center.dx - s, center.dy);
        path.lineTo(center.dx + s * 0.7, center.dy - s);
        path.lineTo(center.dx + s * 0.7, center.dy + s);
        break;
      case _Dir.right:
        path.moveTo(center.dx + s, center.dy);
        path.lineTo(center.dx - s * 0.7, center.dy - s);
        path.lineTo(center.dx - s * 0.7, center.dy + s);
        break;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DpadPainter oldDelegate) =>
      oldDelegate.up != up || oldDelegate.down != down || oldDelegate.left != left || oldDelegate.right != right;
}

enum _Dir { up, down, left, right }
