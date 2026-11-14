import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';
import 'sysfly_logo.dart';
import 'sysfly_world_dots.dart';

/// Round translucent button used in headers.
class SysflyCircleButton extends StatelessWidget {
  const SysflyCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.badge = false,
    this.size = 42,
  });

  final SysflyIconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  /// Shows the small amber dot.
  final bool badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SysflyPressable(
        onTap: onTap,
        pressedScale: 0.9,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SysflyColors.bubbleHighlight, SysflyColors.bubble],
            ),
            border: Border.all(color: SysflyColors.bubbleBorder),
            boxShadow: const [BoxShadow(color: Color(0x2E0B0E33), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SysflyIcon(icon, size: size * 0.48, color: Colors.white),
              if (badge)
                Positioned(
                  top: size * 0.24,
                  right: size * 0.26,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: SysflyColors.warning, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navy gradient backdrop with rounded bottom corners.
class SysflyHeaderBackground extends StatelessWidget {
  const SysflyHeaderBackground({super.key, this.child, this.showMap = false, this.gradient = SysflyGradients.header});

  final Widget? child;
  final bool showMap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ClipRRect(
        borderRadius: SysflyRadius.headerBottom,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: Stack(
            children: [
              if (showMap)
                const Positioned.fill(
                  child: SysflyWorldDots(color: Color(0x1FFFFFFF), zoom: 1.5, alignment: Alignment(0.8, -0.6)),
                ),
              ?child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact header: a leading widget, a centred title and a trailing action.
///
/// Tab screens pass the logo as [leading]; flow screens get a back button.
class SysflyHeader extends StatelessWidget {
  const SysflyHeader({super.key, required this.title, this.leading, this.trailing, this.onBack});

  /// Tab header with the brand logo on the left.
  const SysflyHeader.brand({super.key, required this.title, this.trailing})
      : leading = const SysflyLogo(fontSize: 27),
        onBack = null;

  final String title;
  final Widget? leading;
  final Widget? trailing;

  /// When set (and [leading] is null) a back button is shown.
  final VoidCallback? onBack;

  /// Height of the content row below the status bar.
  static const double contentHeight = 68;

  static const Key backKey = ValueKey('header-back');

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final lead = leading ??
        (onBack != null
            ? SysflyCircleButton(key: backKey, icon: SysflyIcons.back, onTap: onBack, semanticLabel: 'Back')
            : const SizedBox(width: 42));
    return SizedBox(
      height: top + contentHeight,
      child: SysflyHeaderBackground(
        child: Padding(
          padding: EdgeInsets.fromLTRB(SysflySpacing.page, top, SysflySpacing.page, 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(alignment: Alignment.centerLeft, child: lead),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 96),
                child: Semantics(
                  header: true,
                  child: TrText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: SysflyTypography.headerTitle,
                  ),
                ),
              ),
              if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text action in a header, e.g. "Skip".
class SysflyHeaderTextAction extends StatelessWidget {
  const SysflyHeaderTextAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SysflyPressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: ExcludeSemantics(
            child: TrText(label, style: SysflyTypography.bodyStrong.copyWith(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
