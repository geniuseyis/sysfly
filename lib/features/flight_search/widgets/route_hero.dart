import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

/// Tall header of the results screen: the route drawn as a glowing arc with
/// an aircraft, the date in the middle and the two airports beneath.
class RouteHero extends StatelessWidget {
  const RouteHero({
    super.key,
    required this.title,
    required this.origin,
    required this.destination,
    required this.date,
    required this.duration,
    required this.onBack,
    required this.onFilter,
    this.filterBadge = false,
  });

  final String title;
  final Airport origin;
  final Airport destination;
  final DateTime date;
  final Duration? duration;
  final VoidCallback onBack;
  final VoidCallback? onFilter;
  final bool filterBadge;

  /// Height below the status bar.
  static const double contentHeight = 273;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + contentHeight,
      child: SysflyHeaderBackground(
        gradient: SysflyGradients.hero,
        child: Padding(
          padding: EdgeInsets.fromLTRB(SysflySpacing.page, top, SysflySpacing.page, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SysflyCircleButton(icon: SysflyIcons.back, onTap: onBack, semanticLabel: 'Back'),
                    ),
                    Semantics(header: true, child: TrText(title, style: SysflyTypography.headerTitle)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SysflyCircleButton(
                        icon: SysflyIcons.filter,
                        onTap: onFilter,
                        badge: filterBadge,
                        semanticLabel: filterBadge ? 'Filter and sort, filters active' : 'Filter and sort',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _ArcPainter()))),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (duration != null)
                            TrText(Fmt.duration(duration!), style: SysflyTypography.caption.copyWith(color: const Color(0xB3FFFFFF))),
                          const SizedBox(height: 5),
                          TrText(Fmt.full(date), style: SysflyTypography.bodyStrong.copyWith(color: Colors.white, fontSize: 15.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _End(airport: origin, alignEnd: false)),
                  Expanded(child: _End(airport: destination, alignEnd: true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _End extends StatelessWidget {
  const _End({required this.airport, required this.alignEnd});

  final Airport airport;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        TrText(airport.city, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.caption.copyWith(color: const Color(0xB3FFFFFF))),
        const SizedBox(height: 2),
        TrText(airport.code, style: SysflyTypography.airportCode.copyWith(color: Colors.white, fontSize: 27)),
      ],
    );
  }
}

/// A shallow arc between two dots: bright and solid up to the aircraft,
/// dotted beyond it.
class _ArcPainter extends CustomPainter {
  const _ArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Measured: the end points sit 10 pt in from each side, 36 pt above the
    // airport names, and the arc rises 73 pt between them.
    final base = size.height - 36;
    final start = Offset(10, base);
    final end = Offset(size.width - 10, base);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(size.width / 2, base - 146, end.dx, end.dy);
    final metric = path.computeMetrics().first;
    final planeAt = metric.length * 0.72;
    final tangent = metric.getTangentForOffset(planeAt)!;

    // Flown part with a soft glow that brightens towards the aircraft.
    const segments = 36;
    for (var i = 0; i < segments; i++) {
      final t = (i + 1) / segments;
      final segment = metric.extractPath(planeAt * i / segments, planeAt * (i + 1) / segments + 0.5);
      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3 + 9 * t
          ..color = const Color(0xFF4D9BFF).withValues(alpha: 0.5 * t)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.9 + 1.3 * t
          ..color = Color.lerp(const Color(0xFF5B7BE0), const Color(0xFFE2F2FF), t)!.withValues(alpha: 0.35 + 0.65 * t),
      );
    }

    // Remaining part, dotted.
    final dotted = Paint()
      ..color = const Color(0x80FFFFFF)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var d = planeAt + 14; d < metric.length - 6; d += 6) {
      final a = metric.getTangentForOffset(d)!.position;
      final b = metric.getTangentForOffset(math.min(d + 2, metric.length))!.position;
      canvas.drawLine(a, b, dotted);
    }

    // End points with a faint halo.
    for (final p in [start, end]) {
      canvas.drawCircle(p, 6, Paint()..color = const Color(0x33FFFFFF));
      canvas.drawCircle(p, 3, Paint()..color = const Color(0xFFFFFFFF));
    }

    // Aircraft.
    const s = 9.5;
    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    canvas.rotate(-tangent.angle);
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
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0x998CCBFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(body, Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
