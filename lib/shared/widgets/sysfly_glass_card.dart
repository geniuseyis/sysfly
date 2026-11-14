import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';

/// White rounded surface with the soft card shadow.
class SysflyCard extends StatelessWidget {
  const SysflyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SysflySpacing.lg),
    this.radius = SysflyRadius.card,
    this.color = SysflyColors.surface,
    this.border,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final BoxBorder? border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: const Color(0xFFF0F1F8)),
        boxShadow: shadow ? SysflyShadows.card : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Frosted translucent surface. The blur is clipped to the card so only the
/// pixels behind it are filtered.
class SysflyGlassCard extends StatelessWidget {
  const SysflyGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SysflySpacing.lg),
    this.radius = SysflyRadius.card,
    this.blur = 18,
    this.tint = const Color(0xCCFFFFFF),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: borderRadius,
            border: Border.all(color: const Color(0xE6FFFFFF), width: 1.2),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Inset field-coloured box, e.g. the From / To and date boxes.
class SysflyFieldBox extends StatelessWidget {
  const SysflyFieldBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.radius = SysflyRadius.lg,
    this.selected = false,
    this.color = SysflyColors.field,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SysflyMotion.normal,
      curve: SysflyMotion.standard,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: selected ? SysflyColors.selected : SysflyColors.fieldBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: child,
    );
  }
}
