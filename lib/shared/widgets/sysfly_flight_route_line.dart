import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../core/design_system/design_system.dart';

enum RouteLineStyle {
  /// Rises from the origin to the aircraft, then falls as a dotted line.
  /// Used on ticket cards.
  arched,

  /// Level line. Used on boarding passes, status cards and summaries.
  straight,
}

/// Origin dot, flown line, aircraft, dotted remainder and destination ring.
class SysflyFlightRouteLine extends StatelessWidget {
  const SysflyFlightRouteLine({
    super.key,
    this.style = RouteLineStyle.arched,
    this.progress = 0.5,
    this.height = 26,
    this.startColor = SysflyColors.info,
    this.lineColor = SysflyColors.royalText,
    this.planeColor = SysflyColors.royalText,
    this.dottedColor = const Color(0xFFC3C7D6),
    this.endColor = const Color(0xFFB6BACB),
    this.endFilled = false,
    this.dotColor,
  });

  final RouteLineStyle style;

  /// Position of the aircraft along the route, 0 to 1.
  final double progress;
  final double height;
  final Color startColor;
  final Color lineColor;
  final Color planeColor;
  final Color dottedColor;
  final Color endColor;
  final bool endFilled;

  /// Colour of the origin dot; defaults to [startColor].
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(double.infinity, height),
          painter: _RouteLinePainter(
            style: style,
            progress: progress.clamp(0.0, 1.0),
            startColor: startColor,
            lineColor: lineColor,
            planeColor: planeColor,
            dottedColor: dottedColor,
            endColor: endColor,
            endFilled: endFilled,
            dotColor: dotColor ?? startColor,
          ),
        ),
      ),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  const _RouteLinePainter({
    required this.style,
    required this.progress,
    required this.startColor,
    required this.lineColor,
    required this.planeColor,
    required this.dottedColor,
    required this.endColor,
    required this.endFilled,
    required this.dotColor,
  });

  final RouteLineStyle style;
  final double progress;
  final Color startColor;
  final Color lineColor;
  final Color planeColor;
  final Color dottedColor;
  final Color endColor;
  final bool endFilled;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    const dot = 2.6;
    final arched = style == RouteLineStyle.arched;
    final baseY = arched ? size.height * 0.74 : size.height / 2;
    final start = Offset(dot + 1, baseY);
    final end = Offset(size.width - dot - 1, baseY);

    final path = Path()..moveTo(start.dx, start.dy);
    if (arched) {
      path.quadraticBezierTo(size.width * 0.5, baseY - size.height * 1.05, end.dx, end.dy);
    } else {
      path.lineTo(end.dx, end.dy);
    }
    final metric = path.computeMetrics().first;
    final planeAt = metric.length * progress;
    final tangent = metric.getTangentForOffset(planeAt)!;
    const planeHalf = 8.0;

    // Flown part.
    final flownEnd = math.max(0.0, planeAt - planeHalf);
    if (flownEnd > 0) {
      final flown = metric.extractPath(dot, flownEnd);
      canvas.drawPath(
        flown,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(colors: [startColor, lineColor]).createShader(Rect.fromPoints(start, tangent.position)),
      );
    }

    // Remaining part, dotted.
    final dotted = Paint()
      ..color = dottedColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var d = planeAt + planeHalf + 2; d < metric.length - dot - 2; d += 4.5) {
      final a = metric.getTangentForOffset(d)!.position;
      final b = metric.getTangentForOffset(math.min(d + 1.6, metric.length))!.position;
      canvas.drawLine(a, b, dotted);
    }

    // Ends.
    canvas.drawCircle(start, dot, Paint()..color = dotColor);
    if (endFilled) {
      canvas.drawCircle(end, dot, Paint()..color = endColor);
    } else {
      canvas.drawCircle(end, dot + 0.4, Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawCircle(
        end,
        dot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = endColor,
      );
    }

    _paintPlane(canvas, tangent, planeColor);
  }

  /// Small aircraft silhouette pointing along the route.
  static void _paintPlane(Canvas canvas, Tangent at, Color color) {
    const s = 6.2;
    canvas.save();
    canvas.translate(at.position.dx, at.position.dy);
    canvas.rotate(-at.angle);
    final body = Path()
      ..moveTo(s * 1.3, 0)
      ..quadraticBezierTo(s * 0.95, -s * 0.22, s * 0.3, -s * 0.22)
      ..lineTo(-s * 0.35, -s * 1.1)
      ..lineTo(-s * 0.7, -s * 1.1)
      ..lineTo(-s * 0.35, -s * 0.22)
      ..lineTo(-s * 0.9, -s * 0.18)
      ..lineTo(-s * 1.15, -s * 0.55)
      ..lineTo(-s * 1.38, -s * 0.55)
      ..lineTo(-s * 1.2, 0)
      ..lineTo(-s * 1.38, s * 0.55)
      ..lineTo(-s * 1.15, s * 0.55)
      ..lineTo(-s * 0.9, s * 0.18)
      ..lineTo(-s * 0.35, s * 0.22)
      ..lineTo(-s * 0.7, s * 1.1)
      ..lineTo(-s * 0.35, s * 1.1)
      ..lineTo(s * 0.3, s * 0.22)
      ..quadraticBezierTo(s * 0.95, s * 0.22, s * 1.3, 0)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RouteLinePainter old) =>
      old.progress != progress ||
      old.style != style ||
      old.startColor != startColor ||
      old.lineColor != lineColor ||
      old.planeColor != planeColor ||
      old.dottedColor != dottedColor ||
      old.endColor != endColor ||
      old.endFilled != endFilled ||
      old.dotColor != dotColor;
}

/// Deterministic barcode drawn from a seed string.
class SysflyBarcode extends StatelessWidget {
  const SysflyBarcode({super.key, required this.data, this.vertical = false, this.color = SysflyColors.textPrimary});

  final String data;

  /// Bars stacked top to bottom instead of left to right.
  final bool vertical;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(painter: _BarcodePainter(data, vertical, color), child: const SizedBox.expand()),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter(this.data, this.vertical, this.color);

  final String data;
  final bool vertical;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var seed = 0x2545F491;
    for (final c in data.codeUnits) {
      seed = (seed * 31 + c) & 0x7fffffff;
    }
    int next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed >> 8;
    }

    final paint = Paint()..color = color;
    final extent = vertical ? size.height : size.width;
    final thickness = vertical ? size.width : size.height;
    var offset = 0.0;
    while (offset < extent) {
      final bar = lerpDouble(0.9, 2.6, (next() % 100) / 100)!;
      final gap = lerpDouble(0.9, 2.2, (next() % 100) / 100)!;
      final length = math.min(bar, extent - offset);
      canvas.drawRect(
        vertical ? Rect.fromLTWH(0, offset, thickness, length) : Rect.fromLTWH(offset, 0, length, thickness),
        paint,
      );
      offset += bar + gap;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.data != data || old.vertical != vertical || old.color != color;
}
