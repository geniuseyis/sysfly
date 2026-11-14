import 'package:flutter/material.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';

/// The primary navy-to-royal pill button.
class SysflyGradientButton extends StatelessWidget {
  const SysflyGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 54,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 28),
  });

  final String label;

  /// Null renders the faded, disabled state.
  final VoidCallback? onPressed;
  final SysflyIconData? icon;
  final bool loading;
  final double height;
  final bool expand;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        else if (icon != null)
          SysflyIcon(icon!, size: 20, color: Colors.white),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: TrText(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.button),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: SysflyPressable(
          onTap: enabled ? onPressed : null,
          haptic: PressHaptic.tap,
          child: AnimatedOpacity(
            opacity: onPressed == null ? 0.42 : 1,
            duration: SysflyMotion.normal,
            child: Container(
              height: height,
              width: expand ? double.infinity : null,
              padding: padding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: SysflyGradients.primary,
                borderRadius: SysflyRadius.pillAll,
                boxShadow: onPressed == null ? null : SysflyShadows.button,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// White pill button with a hairline border, e.g. "Edit profile", "Reset".
class SysflyOutlineButton extends StatelessWidget {
  const SysflyOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.height = 48,
    this.expand = false,
    this.radius = SysflyRadius.pill,
    this.dense = false,
    this.foreground = SysflyColors.textPrimary,
  });

  final String label;
  final VoidCallback? onPressed;
  final SysflyIconData? icon;

  /// Custom leading widget (brand marks); takes precedence over [icon].
  final Widget? leading;
  final double height;
  final bool expand;
  final double radius;

  /// Smaller text and padding, for inline pills.
  final bool dense;

  /// Colour of the label and icon.
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: ExcludeSemantics(
        child: SysflyPressable(
          onTap: onPressed,
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 20),
            decoration: BoxDecoration(
              color: SysflyColors.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: SysflyColors.fieldBorder, width: 1.2),
              boxShadow: SysflyShadows.soft,
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)] else if (icon != null) ...[
                  SysflyIcon(icon!, size: dense ? 15 : 18, color: foreground),
                  SizedBox(width: dense ? 6 : 8),
                ],
                Flexible(
                  child: TrText(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SysflyTypography.bodyStrong.copyWith(fontSize: dense ? 13 : null, color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
