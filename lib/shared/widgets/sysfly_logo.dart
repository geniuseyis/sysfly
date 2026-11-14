import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/design_system/design_system.dart';

/// The sysfly wordmark with its curved, glowing flight trail.
///
/// [arc] draws the trail from 0 to 1, [flare] fades in the star at its end
/// and [wordmark] fades in the lettering, so the splash screen can animate
/// each part; all default to their finished state.
class SysflyLogo extends StatelessWidget {
  const SysflyLogo({super.key, this.fontSize = 28, this.arc = 1, this.flare = 1, this.wordmark = 1});

  final double fontSize;
  final double arc;
  final double flare;
  final double wordmark;

  @override
  Widget build(BuildContext context) {
    final style = SysflyTypography.brand(fontSize);
    final painter = TextPainter(
      text: TextSpan(text: AppBrand.name, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final textSize = painter.size;
    painter.dispose();

    // Room for the trail: it rises about 0.2 widths above the lettering and
    // runs slightly past both ends.
    final headroom = textSize.width * 0.24;
    final side = textSize.width * 0.12;
    return Semantics(
      label: AppBrand.name,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: textSize.width + side * 2,
          height: textSize.height + headroom,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: side,
                top: headroom,
                child: Opacity(
                  opacity: wordmark.clamp(0.0, 1.0),
                  child: TrText(AppBrand.name, style: style, textScaler: TextScaler.noScaling),
                ),
              ),
              Positioned(
                left: side,
                top: headroom,
                width: textSize.width,
                height: textSize.height,
                child: RepaintBoundary(
                  child: CustomPaint(painter: FlightTrailPainter(progress: arc, flare: flare)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the flight trail over a box the size of the wordmark.
///
/// The trail is a circular arc (radius 0.81 of the wordmark width, measured
/// from the reference) drawn with a taper and a glow. While it is being drawn
/// a small aircraft leads it; when [flare] rises the aircraft gives way to a
/// four-point star with a horizontal streak.
class FlightTrailPainter extends CustomPainter {
  const FlightTrailPainter({required this.progress, required this.flare});

  final double progress;
  final double flare;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final w = size.width;
    // Measured against the reference wordmark of width w: the arc is part of
    // a circle of radius 0.715 w centred 0.626 w along, its top sits 0.2 w
    // above the tops of the letters, it starts level with the middle of the
    // first letter and ends just past the top of the last one.
    final radius = w * 0.715;
    final lettersTop = size.height * 0.2;
    final centre = Offset(w * 0.626, lettersTop - w * 0.2 + radius);
    const startAngle = -math.pi / 2 - 1.066; // 61 degrees left of vertical
    const sweep = 1.066 + 0.724; // to 41.5 degrees right of vertical

    final full = Path()..addArc(Rect.fromCircle(center: centre, radius: radius), startAngle, sweep);
    final metric = full.computeMetrics().first;
    final length = metric.length * p;
    final head = metric.getTangentForOffset(length)!;

    // Tapered, fading trail built from short segments.
    const segments = 44;
    final unit = w / 200;
    for (var i = 0; i < segments; i++) {
      final a = length * i / segments;
      final b = length * (i + 1) / segments;
      final t = (i + 1) / segments;
      final segment = metric.extractPath(a, b + 0.5);
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = unit * (4 + 9 * t)
        ..color = const Color(0xFF3C8DFF).withValues(alpha: 0.5 * t * t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 4.5);
      canvas.drawPath(segment, glow);
      final core = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = unit * (0.9 + 2.3 * t)
        ..color = Color.lerp(const Color(0xFF3A7BFF), const Color(0xFFD9F1FF), t * t)!.withValues(alpha: math.pow(t, 1.4).toDouble());
      canvas.drawPath(segment, core);
    }

    final f = flare.clamp(0.0, 1.0);
    if (f < 1) _paintAircraft(canvas, head, unit, 1 - f);
    if (f > 0) _paintFlare(canvas, head.position, unit, f);
  }

  void _paintAircraft(Canvas canvas, Tangent head, double unit, double opacity) {
    final s = unit * 5.2;
    canvas.save();
    canvas.translate(head.position.dx, head.position.dy);
    canvas.rotate(-head.angle);
    final paint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity);
    final body = Path()
      ..moveTo(s * 1.25, 0)
      ..quadraticBezierTo(s * 0.9, -s * 0.2, s * 0.25, -s * 0.2)
      ..lineTo(-s * 0.45, -s * 1.05)
      ..lineTo(-s * 0.75, -s * 1.05)
      ..lineTo(-s * 0.4, -s * 0.2)
      ..lineTo(-s * 0.95, -s * 0.16)
      ..lineTo(-s * 1.2, -s * 0.52)
      ..lineTo(-s * 1.4, -s * 0.52)
      ..lineTo(-s * 1.25, 0)
      ..lineTo(-s * 1.4, s * 0.52)
      ..lineTo(-s * 1.2, s * 0.52)
      ..lineTo(-s * 0.95, s * 0.16)
      ..lineTo(-s * 0.4, s * 0.2)
      ..lineTo(-s * 0.75, s * 1.05)
      ..lineTo(-s * 0.45, s * 1.05)
      ..lineTo(s * 0.25, s * 0.2)
      ..quadraticBezierTo(s * 0.9, s * 0.2, s * 1.25, 0)
      ..close();
    canvas.drawPath(body, Paint()
      ..color = const Color(0xFF8CCBFF).withValues(alpha: 0.55 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 2.5));
    canvas.drawPath(body, paint);
    canvas.restore();
  }

  void _paintFlare(Canvas canvas, Offset at, double unit, double amount) {
    final scale = lerpDouble(0.4, 1, Curves.easeOutBack.transform(amount))!;
    final halo = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFBFE4FF).withValues(alpha: 0.75 * amount),
        const Color(0xFF4F9CFF).withValues(alpha: 0.25 * amount),
        const Color(0x004F9CFF),
      ], stops: const [0, 0.35, 1]).createShader(Rect.fromCircle(center: at, radius: unit * 20 * scale));
    canvas.drawCircle(at, unit * 20 * scale, halo);

    // Horizontal streak.
    final streak = Rect.fromCenter(center: at, width: unit * 84 * scale, height: unit * 2);
    canvas.drawRect(
      streak,
      Paint()
        ..shader = LinearGradient(colors: [
          const Color(0x00FFFFFF),
          const Color(0xFFFFFFFF).withValues(alpha: 0.9 * amount),
          const Color(0x00FFFFFF),
        ]).createShader(streak)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.8),
    );

    // Four-point star.
    final long = unit * 12 * scale;
    final short = unit * 2.2 * scale;
    final star = Path()
      ..moveTo(at.dx, at.dy - long)
      ..quadraticBezierTo(at.dx + short * 0.4, at.dy - short * 0.4, at.dx + long, at.dy)
      ..quadraticBezierTo(at.dx + short * 0.4, at.dy + short * 0.4, at.dx, at.dy + long)
      ..quadraticBezierTo(at.dx - short * 0.4, at.dy + short * 0.4, at.dx - long, at.dy)
      ..quadraticBezierTo(at.dx - short * 0.4, at.dy - short * 0.4, at.dx, at.dy - long)
      ..close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: amount));
    canvas.drawCircle(at, unit * 3 * scale, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: amount));
  }

  @override
  bool shouldRepaint(FlightTrailPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.flare != flare;
}
