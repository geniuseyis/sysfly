import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Travel scene behind the sign-in panel: a sky, layered mountains, clouds,
/// a tree, a bus-stop sign, an aircraft with a dashed trail and a traveller
/// with a backpack and suitcase.
///
/// The reference uses a raster illustration that is not part of this
/// project, so the scene is redrawn here as vector art with the same
/// composition and palette. It is painted on a 440 x 344 canvas and scaled
/// to the available width.
class LoginIllustration extends StatelessWidget {
  const LoginIllustration({super.key});

  static const double designWidth = 440;
  static const double designHeight = 344;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(painter: const _ScenePainter(), child: const SizedBox.expand()),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter();

  static const _skin = Color(0xFFF3B995);
  static const _skinShade = Color(0xFFE4A07B);
  static const _hair = Color(0xFF1E3D73);
  static const _shirt = Color(0xFF1F8C8F);
  static const _pack = Color(0xFFF2B43C);
  static const _packShade = Color(0xFFCB8B1F);
  static const _shorts = Color(0xFF7392B5);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / LoginIllustration.designWidth;
    final drawnHeight = LoginIllustration.designHeight * scale;

    // Sky fills the whole area; the scene is anchored to the bottom.
    final sky = Offset.zero & size;
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC3DCF6), Color(0xFFD9E9FA), Color(0xFFE6F1FC)],
        ).createShader(sky),
    );

    canvas.save();
    canvas.translate(0, size.height - drawnHeight);
    canvas.scale(scale);
    _scene(canvas);
    canvas.restore();
  }

  void _scene(Canvas canvas) {
    Paint fill(Color c) => Paint()..color = c;

    // Distant clouds.
    _cloud(canvas, const Offset(22, 126), 0.9, const Color(0xCCFFFFFF));
    _cloud(canvas, const Offset(414, 74), 0.7, const Color(0xB3FFFFFF));

    // Aircraft and its dashed trail.
    final trail = Path()
      ..moveTo(96, 96)
      ..quadraticBezierTo(150, 66, 214, 70);
    final dash = Paint()
      ..color = const Color(0xFF5B79C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final metric = trail.computeMetrics().first;
    for (var d = 0.0; d < metric.length; d += 7) {
      canvas.drawPath(metric.extractPath(d, d + 3), dash);
    }
    _aircraft(canvas, const Offset(226, 69), -0.06, 7, const Color(0xFF223C8F));

    // Far range.
    canvas.drawPath(
      Path()
        ..moveTo(-10, 250)
        ..quadraticBezierTo(60, 150, 122, 118)
        ..quadraticBezierTo(140, 110, 158, 124)
        ..quadraticBezierTo(240, 190, 300, 250)
        ..close(),
      fill(const Color(0xFFB4C3F0)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(122, 118)
        ..quadraticBezierTo(140, 110, 158, 124)
        ..quadraticBezierTo(150, 150, 118, 158)
        ..quadraticBezierTo(104, 176, 78, 180)
        ..quadraticBezierTo(104, 140, 122, 118)
        ..close(),
      fill(const Color(0xFFCBD6F6)),
    );

    // Main peak with a shaded face.
    canvas.drawPath(
      Path()
        ..moveTo(110, 262)
        ..quadraticBezierTo(180, 170, 226, 138)
        ..quadraticBezierTo(244, 126, 262, 140)
        ..quadraticBezierTo(350, 200, 452, 250)
        ..lineTo(452, 262)
        ..close(),
      fill(const Color(0xFF8799E0)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(244, 132)
        ..quadraticBezierTo(256, 132, 262, 140)
        ..quadraticBezierTo(350, 200, 452, 250)
        ..lineTo(452, 262)
        ..lineTo(300, 262)
        ..quadraticBezierTo(250, 210, 244, 132)
        ..close(),
      fill(const Color(0xFF5E72BC)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(40, 262)
        ..quadraticBezierTo(96, 196, 150, 176)
        ..quadraticBezierTo(190, 210, 232, 262)
        ..close(),
      fill(const Color(0xFF6F82CE)),
    );

    // Near hills.
    canvas.drawPath(
      Path()
        ..moveTo(-10, 252)
        ..quadraticBezierTo(120, 222, 250, 250)
        ..quadraticBezierTo(350, 268, 452, 240)
        ..lineTo(452, 350)
        ..lineTo(-10, 350)
        ..close(),
      fill(const Color(0xFF79A9DC)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, 292)
        ..quadraticBezierTo(140, 268, 300, 296)
        ..quadraticBezierTo(380, 308, 452, 290)
        ..lineTo(452, 350)
        ..lineTo(-10, 350)
        ..close(),
      fill(const Color(0xFF8DB7E4)),
    );

    // Tree on the right.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(409, 170, 7, 130), const Radius.circular(3)),
      fill(const Color(0xFF8C9CC0)),
    );
    for (final (c, r) in const [(Offset(412, 150), 30.0), (Offset(430, 176), 24.0), (Offset(396, 180), 20.0), (Offset(424, 130), 20.0)]) {
      canvas.drawCircle(c, r, fill(const Color(0xFF8FA4CF)));
    }
    canvas.drawCircle(const Offset(404, 142), 16, fill(const Color(0xFFA3B5DB)));

    // Bus-stop sign.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(340, 132, 7, 190), const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFE7ECF5), Color(0xFFAEB8CC)])
            .createShader(const Rect.fromLTWH(340, 132, 7, 190)),
    );
    const sign = Rect.fromLTWH(307, 65, 73, 73);
    canvas.drawRRect(RRect.fromRectAndRadius(sign, const Radius.circular(13)), fill(const Color(0xFFB9781C)));
    canvas.drawRRect(RRect.fromRectAndRadius(sign.deflate(4), const Radius.circular(10)), fill(_pack));
    canvas.drawRRect(RRect.fromRectAndRadius(sign.deflate(11), const Radius.circular(7)), fill(const Color(0xFF6B4311)));
    // Bus front.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(326, 84, 35, 30), const Radius.circular(7)), fill(_pack));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(330, 88, 27, 13), const Radius.circular(4)), fill(const Color(0xFFFFF7E6)));
    canvas.drawCircle(const Offset(332, 107), 2.4, fill(const Color(0xFF6B4311)));
    canvas.drawCircle(const Offset(355, 107), 2.4, fill(const Color(0xFF6B4311)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(329, 113, 6, 6), const Radius.circular(2)), fill(_pack));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(352, 113, 6, 6), const Radius.circular(2)), fill(_pack));

    _traveller(canvas);

    // Foreground clouds at the lower corners.
    _cloud(canvas, const Offset(20, 304), 1.15, const Color(0xFFFFFFFF));
    _cloud(canvas, const Offset(396, 300), 1.25, const Color(0xFFFFFFFF));
    canvas.drawPath(
      Path()
        ..moveTo(404, 344)
        ..lineTo(452, 290)
        ..lineTo(452, 344)
        ..close(),
      fill(const Color(0xFFC9D1DF)),
    );
  }

  void _traveller(Canvas canvas) {
    Paint fill(Color c) => Paint()..color = c;

    // Suitcase handle beside the left leg.
    final handle = Paint()
      ..color = const Color(0xFF2B3550)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(150, 344)
        ..lineTo(150, 296)
        ..lineTo(172, 296)
        ..lineTo(172, 344),
      handle,
    );

    // Legs.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(186, 276, 18, 80), const Radius.circular(8)), fill(_skinShade));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(206, 276, 18, 80), const Radius.circular(8)), fill(_skin));

    // Shorts.
    canvas.drawPath(
      Path()
        ..moveTo(178, 240)
        ..lineTo(230, 240)
        ..quadraticBezierTo(234, 270, 230, 296)
        ..lineTo(206, 296)
        ..lineTo(204, 276)
        ..lineTo(202, 296)
        ..lineTo(180, 296)
        ..quadraticBezierTo(174, 268, 178, 240)
        ..close(),
      fill(_shorts),
    );

    // Extended right arm.
    final arm = Paint()
      ..color = _skin
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(222, 198), const Offset(292, 206), arm);
    canvas.drawCircle(const Offset(297, 205), 6.5, fill(_skin));
    // Short sleeve.
    canvas.drawPath(
      Path()
        ..moveTo(212, 186)
        ..quadraticBezierTo(236, 186, 242, 198)
        ..lineTo(238, 212)
        ..quadraticBezierTo(224, 208, 212, 210)
        ..close(),
      fill(_shirt),
    );

    // Torso.
    canvas.drawPath(
      Path()
        ..moveTo(170, 190)
        ..quadraticBezierTo(170, 178, 186, 176)
        ..lineTo(218, 176)
        ..quadraticBezierTo(232, 180, 232, 196)
        ..lineTo(232, 246)
        ..lineTo(176, 246)
        ..close(),
      fill(_shirt),
    );

    // Backpack with two pockets and straps.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(160, 184, 44, 62), const Radius.circular(10)), fill(_pack));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(165, 198, 26, 16), const Radius.circular(4)), fill(_packShade));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(165, 220, 30, 20), const Radius.circular(5)), fill(_packShade));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(196, 186, 6, 50), const Radius.circular(3)), fill(const Color(0xFFDFA02A)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(176, 178, 14, 9), const Radius.circular(4)), fill(_packShade));

    // Neck, head and hair, seen from behind and turned to the right.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(196, 162, 13, 20), const Radius.circular(5)), fill(_skinShade));
    canvas.drawOval(const Rect.fromLTWH(184, 126, 40, 46), fill(_skin));
    canvas.drawPath(
      Path()
        ..moveTo(206, 122)
        ..quadraticBezierTo(170, 116, 164, 152)
        ..quadraticBezierTo(160, 178, 176, 184)
        ..quadraticBezierTo(196, 186, 200, 168)
        ..quadraticBezierTo(214, 150, 214, 136)
        ..quadraticBezierTo(222, 132, 222, 128)
        ..quadraticBezierTo(216, 120, 206, 122)
        ..close(),
      fill(_hair),
    );
    canvas.drawPath(
      Path()
        ..moveTo(190, 126)
        ..quadraticBezierTo(172, 134, 170, 158)
        ..quadraticBezierTo(178, 140, 196, 132)
        ..close(),
      fill(const Color(0xFF2E55A0)),
    );
  }

  static void _cloud(Canvas canvas, Offset at, double scale, Color color) {
    final paint = Paint()..color = color;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(scale);
    canvas.drawCircle(const Offset(-16, 6), 12, paint);
    canvas.drawCircle(const Offset(0, -4), 16, paint);
    canvas.drawCircle(const Offset(18, 4), 13, paint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-28, 4, 58, 16), const Radius.circular(8)), paint);
    canvas.restore();
  }

  static void _aircraft(Canvas canvas, Offset at, double angle, double s, Color color) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    final body = Path()
      ..moveTo(s * 1.3, 0)
      ..quadraticBezierTo(s * 0.95, -s * 0.24, s * 0.3, -s * 0.24)
      ..lineTo(-s * 0.35, -s * 1.15)
      ..lineTo(-s * 0.72, -s * 1.15)
      ..lineTo(-s * 0.35, -s * 0.24)
      ..lineTo(-s * 0.9, -s * 0.2)
      ..lineTo(-s * 1.15, -s * 0.58)
      ..lineTo(-s * 1.4, -s * 0.58)
      ..lineTo(-s * 1.2, 0)
      ..lineTo(-s * 1.4, s * 0.58)
      ..lineTo(-s * 1.15, s * 0.58)
      ..lineTo(-s * 0.9, s * 0.2)
      ..lineTo(-s * 0.35, s * 0.24)
      ..lineTo(-s * 0.72, s * 1.15)
      ..lineTo(-s * 0.35, s * 1.15)
      ..lineTo(s * 0.3, s * 0.24)
      ..quadraticBezierTo(s * 0.95, s * 0.24, s * 1.3, 0)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Four-colour "G" mark for the Google button.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: const _GoogleMarkPainter());
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    // Angles in radians, clockwise from three o'clock.
    canvas.drawArc(rect, -math.pi * 0.25, -math.pi * 0.62, false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(rect, -math.pi * 0.87, -math.pi * 0.34, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, math.pi * 0.79, -math.pi * 0.52, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, math.pi * 0.27, -math.pi * 0.29, false, arc(const Color(0xFF4285F4)));
    canvas.drawRect(Rect.fromLTWH(s * 0.5, s * 0.41, s * 0.48, stroke * 0.92), Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
