import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';

/// Frosts [child] and shows the orbiting aircraft while [visible] is true.
///
/// Drive [visible] from the real loading state of the screen. The blur is
/// only in the tree while the overlay is shown or fading.
class SysflyLoadingOverlay extends StatelessWidget {
  const SysflyLoadingOverlay({
    super.key,
    required this.visible,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final bool visible;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: SysflyMotion.loaderFadeIn,
            reverseDuration: SysflyMotion.loaderFadeOut,
            child: visible
                ? _Frost(key: const ValueKey('sysfly-loading'), title: title, subtitle: subtitle)
                : const SizedBox.shrink(key: ValueKey('sysfly-loading-off')),
          ),
        ),
      ],
    );
  }
}

class _Frost extends StatelessWidget {
  const _Frost({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          // Material gives the labels a text style when the overlay sits above
          // a Scaffold rather than inside one.
          child: Material(
            color: const Color(0xB8FFFFFF),
            child: Center(
              child: Semantics(
                liveRegion: true,
                label: subtitle == null ? title : '$title. $subtitle',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SysflyPlaneSpinner(),
                      const SizedBox(height: 6),
                      TrText(title, style: SysflyTypography.cardTitle.copyWith(fontSize: 16.5)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        TrText(subtitle!, style: SysflyTypography.caption),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small aircraft circling clockwise with a tapering trail of dots.
/// One revolution takes 2.4 s (measured from the reference).
class SysflyPlaneSpinner extends StatefulWidget {
  const SysflyPlaneSpinner({super.key, this.size = 124, this.color = SysflyColors.selected});

  final double size;
  final Color color;

  @override
  State<SysflyPlaneSpinner> createState() => _SysflyPlaneSpinnerState();
}

class _SysflyPlaneSpinnerState extends State<SysflyPlaneSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: SysflyMotion.loaderOrbit)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _SpinnerPainter(_controller, widget.color),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.turn, this.color) : super(repaint: turn);

  final Animation<double> turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width * 0.4;
    final angle = turn.value * math.pi * 2 - math.pi / 2;

    // Trail: seven dots behind the aircraft, shrinking with distance.
    const dots = 7;
    final paint = Paint()..color = color;
    for (var i = 1; i <= dots; i++) {
      final a = angle - i * 0.27 - 0.12;
      final t = 1 - (i - 1) / dots;
      canvas.drawCircle(
        centre + Offset(math.cos(a), math.sin(a)) * radius,
        size.width * 0.032 * t + 0.6,
        paint..color = color.withValues(alpha: 0.35 + 0.65 * t),
      );
    }

    // Aircraft, nose along the direction of travel.
    final at = centre + Offset(math.cos(angle), math.sin(angle)) * radius;
    final s = size.width * 0.085;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle + math.pi / 2);
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
  bool shouldRepaint(_SpinnerPainter oldDelegate) => oldDelegate.color != color;
}
