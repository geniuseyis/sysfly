import 'package:flutter/material.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';

/// The round boarding-pass shortcut that floats to the right of the
/// navigation bar. It is independent of the tab selection.
class SysflyTicketActionButton extends StatelessWidget {
  const SysflyTicketActionButton({super.key, required this.onTap, this.size = 60});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Boarding pass',
      child: SysflyPressable(
        onTap: onTap,
        pressedScale: 0.92,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SysflyGradients.indicator,
            border: Border.all(color: const Color(0xFFF7F8FF), width: 2),
            boxShadow: SysflyShadows.nav,
          ),
          child: Center(
            child: CustomPaint(size: Size.square(size * 0.39), painter: const _TicketScanPainter()),
          ),
        ),
      ),
    );
  }
}

/// The reference glyph, redrawn from an enlarged frame: four thin rounded
/// corner brackets around a rounded block that a scan line splits in two.
class _TicketScanPainter extends CustomPainter {
  const _TicketScanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    const white = Color(0xFFFFFFFF);
    final stroke = Paint()
      ..color = white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final r = s * 0.25;
    final arm = s * 0.085;

    Path corner(double x, double y, double sx, double sy) => Path()
      ..moveTo(x, y + sy * (r + arm))
      ..lineTo(x, y + sy * r)
      ..arcToPoint(Offset(x + sx * r, y), radius: Radius.circular(r), clockwise: sx * sy > 0)
      ..lineTo(x + sx * (r + arm), y);

    final inset = s * 0.04;
    canvas.drawPath(corner(inset, inset, 1, 1), stroke);
    canvas.drawPath(corner(s - inset, inset, -1, 1), stroke);
    canvas.drawPath(corner(inset, s - inset, 1, -1), stroke);
    canvas.drawPath(corner(s - inset, s - inset, -1, -1), stroke);

    // Block, split by a gap with the scan line running through it.
    final fill = Paint()..color = white;
    final radius = Radius.circular(s * 0.15);
    const small = Radius.circular(1);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        s * 0.24,
        s * 0.235,
        s * 0.76,
        s * 0.425,
        topLeft: radius,
        topRight: radius,
        bottomLeft: small,
        bottomRight: small,
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        s * 0.24,
        s * 0.575,
        s * 0.76,
        s * 0.765,
        topLeft: small,
        topRight: small,
        bottomLeft: radius,
        bottomRight: radius,
      ),
      fill,
    );
    canvas.drawLine(Offset(s * 0.13, s * 0.5), Offset(s * 0.87, s * 0.5), stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
