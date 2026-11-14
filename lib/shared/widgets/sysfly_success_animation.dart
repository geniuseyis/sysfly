import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';

/// Green scalloped seal with a check that pops in and throws a ring of
/// small sparks once.
class SysflySuccessAnimation extends StatefulWidget {
  const SysflySuccessAnimation({super.key, this.size = 84});

  final double size;

  @override
  State<SysflySuccessAnimation> createState() => _SysflySuccessAnimationState();
}

class _SysflySuccessAnimationState extends State<SysflySuccessAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _pop = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.55, curve: Curves.easeOutBack));
  late final Animation<double> _sparks = CurvedAnimation(parent: _controller, curve: const Interval(0.25, 1, curve: Curves.easeOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.status == AnimationStatus.dismissed) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.size * 1.36;
    return Semantics(
      label: 'Booking confirmed',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: box,
          height: box,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _SparkPainter(_sparks.value),
              child: Center(
                child: Transform.scale(
                  scale: _pop.value,
                  child: SysflyIcon(SysflyIcons.sealCheck, size: widget.size, color: SysflyColors.success),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final centre = size.center(Offset.zero);
    final paint = Paint()..color = SysflyColors.success.withValues(alpha: 0.28 + 0.2 * (1 - t));
    const count = 12;
    for (var i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + 0.2;
      final distance = size.width * (0.34 + 0.13 * t);
      canvas.drawCircle(centre + Offset(math.cos(angle), math.sin(angle)) * distance, i.isEven ? 1.6 : 1.1, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) => oldDelegate.t != t;
}
