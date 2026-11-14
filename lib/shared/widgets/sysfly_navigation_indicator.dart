import 'package:flutter/widgets.dart';

import '../../core/design_system/design_system.dart';

/// The selected-tab capsule of [SysflyFloatingNavigationBar].
///
/// [lens] morphs it from the navy gradient capsule (0) into the clear glass
/// lens shown while the capsule is being dragged (1).
class SysflyNavigationIndicator extends StatelessWidget {
  const SysflyNavigationIndicator({super.key, this.lens = 0, this.paintLens = true});

  final double lens;

  /// Draw the painted stand-in for the lens. Off when real glass is used.
  final bool paintLens;

  @override
  Widget build(BuildContext context) {
    final t = lens.clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (t < 1)
          Opacity(
            opacity: 1 - t,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: SysflyGradients.indicator,
                borderRadius: SysflyRadius.pillAll,
                boxShadow: [BoxShadow(color: Color(0x33171E61), blurRadius: 10, offset: Offset(0, 4))],
              ),
            ),
          ),
        if (t > 0 && paintLens)
          Opacity(
            opacity: t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: SysflyRadius.pillAll,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFF4F4FC)],
                ),
                border: Border.all(color: const Color(0xFFFFFFFF), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x2E10133C), blurRadius: 18, offset: Offset(0, 6)),
                  BoxShadow(color: Color(0x1410133C), blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
