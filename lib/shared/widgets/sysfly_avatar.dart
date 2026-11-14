import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';

/// Round profile picture. The reference uses a photograph; no photo ships
/// with the demo, so a monochrome portrait is drawn instead. Pass [image] to
/// show a real picture.
class SysflyAvatar extends StatelessWidget {
  const SysflyAvatar({super.key, this.size = 92, this.image, required this.name});

  final double size;
  final ImageProvider? image;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Profile picture of $name',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(color: SysflyColors.surface, shape: BoxShape.circle, boxShadow: SysflyShadows.card),
        child: ClipOval(
          child: image != null
              ? Image(image: image!, fit: BoxFit.cover)
              : CustomPaint(painter: const _PortraitPainter(), child: const SizedBox.expand()),
        ),
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  const _PortraitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.9,
          colors: [Color(0xFF3A3D48), Color(0xFF14151B)],
        ).createShader(rect),
    );

    // Shoulders.
    final shoulders = Path()
      ..moveTo(w * 0.08, h * 1.05)
      ..quadraticBezierTo(w * 0.12, h * 0.74, w * 0.38, h * 0.7)
      ..lineTo(w * 0.62, h * 0.7)
      ..quadraticBezierTo(w * 0.88, h * 0.74, w * 0.92, h * 1.05)
      ..close();
    canvas.drawPath(shoulders, Paint()..color = const Color(0xFF2A2C35));

    // Neck.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.42, h * 0.56, w * 0.16, h * 0.2), Radius.circular(w * 0.06)),
      Paint()..color = const Color(0xFFB9B4AE),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.38, h * 0.7)
        ..quadraticBezierTo(w * 0.5, h * 0.84, w * 0.62, h * 0.7)
        ..close(),
      Paint()..color = const Color(0xFFB9B4AE),
    );

    // Face.
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.44), width: w * 0.34, height: h * 0.4), Paint()..color = const Color(0xFFCDC8C2));

    // Curly hair.
    final hair = Paint()..color = const Color(0xFF17181D);
    for (final c in const [
      Offset(0.36, 0.3), Offset(0.44, 0.24), Offset(0.53, 0.23), Offset(0.62, 0.27), Offset(0.67, 0.35), //
      Offset(0.33, 0.39), Offset(0.4, 0.3), Offset(0.58, 0.3), Offset(0.49, 0.28),
    ]) {
      canvas.drawCircle(Offset(w * c.dx, h * c.dy), w * 0.085, hair);
    }

    // Smile and eyes.
    final feature = Paint()
      ..color = const Color(0xFF3B3835)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.16, height: h * 0.1), 0.25, 2.64, false, feature);
    canvas.drawCircle(Offset(w * 0.44, h * 0.43), w * 0.013, Paint()..color = const Color(0xFF3B3835));
    canvas.drawCircle(Offset(w * 0.56, h * 0.43), w * 0.013, Paint()..color = const Color(0xFF3B3835));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Initials in a tinted circle, e.g. the traveller chip on the seat map.
class SysflyInitials extends StatelessWidget {
  const SysflyInitials({
    super.key,
    required this.initials,
    this.size = 40,
    this.background = SysflyColors.tile,
    this.foreground = SysflyColors.link,
    this.verified = false,
  });

  final String initials;
  final double size;
  final Color background;
  final Color foreground;

  /// Shows the small green tick used for a completed traveller.
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + (verified ? 2 : 0),
      height: size + (verified ? 2 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: TrText(
              initials,
              style: SysflyTypography.bodyStrong.copyWith(fontSize: size * 0.34, color: foreground),
            ),
          ),
          if (verified)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: BoxDecoration(
                  color: SysflyColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: SysflyColors.surface, width: 1.5),
                ),
                child: SysflyIcon(SysflyIcons.check, size: size * 0.2, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
