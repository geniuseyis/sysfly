import 'package:flutter/widgets.dart';

import '../design_system/motion.dart';
import '../services/haptics.dart';

enum PressHaptic { none, selection, tap }

/// Scales its child down slightly while pressed. Used for every tappable
/// surface so press feedback is consistent.
class SysflyPressable extends StatefulWidget {
  const SysflyPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = SysflyMotion.pressScale,
    this.haptic = PressHaptic.selection,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;

  /// Null disables the control.
  final VoidCallback? onTap;
  final double pressedScale;
  final PressHaptic haptic;
  final HitTestBehavior behavior;

  @override
  State<SysflyPressable> createState() => _SysflyPressableState();
}

class _SysflyPressableState extends State<SysflyPressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTap: enabled
          ? () {
              switch (widget.haptic) {
                case PressHaptic.none:
                  break;
                case PressHaptic.selection:
                  SysflyHaptics.selection();
                case PressHaptic.tap:
                  SysflyHaptics.tap();
              }
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down && !reduce ? widget.pressedScale : 1,
        duration: _down ? SysflyMotion.fast : SysflyMotion.normal,
        curve: SysflyMotion.enter,
        child: widget.child,
      ),
    );
  }
}
