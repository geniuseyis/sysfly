import 'package:flutter/animation.dart';

/// Motion tokens. "measured" values come from frame-by-frame analysis of the
/// 30 fps reference recording (±1 frame = ±33 ms); "estimated" values follow
/// the same design language where the recording shows no interaction.
/// See docs/ANIMATION_SPEC.md.
abstract final class SysflyMotion {
  // ---- Navigation indicator (measured) -------------------------------
  /// Underdamped spring fitted to the indicator: first reaches the target in
  /// about 165 ms, peaks about 5 % past it near 215 ms, settles by 350 ms.
  static const SpringDescription navSpring = SpringDescription(mass: 1, stiffness: 400, damping: 28);

  /// Extra capsule width per unit of velocity (logical px per px/s).
  static const double navStretchPerVelocity = 0.02;

  /// Largest velocity stretch, about 17 % of the capsule width.
  static const double navMaxStretch = 15;

  /// Capsule to glass lens and back while dragging.
  static const Duration navLens = Duration(milliseconds: 150);

  /// Lens size relative to the resting capsule.
  static const double navLensScale = 1.32;

  // ---- Tab pages (measured) -------------------------------------------
  static const Duration tabFade = Duration(milliseconds: 200);

  // ---- Splash (measured) ----------------------------------------------
  static const Duration splashTotal = Duration(milliseconds: 3100);
  static const Interval splashLogo = Interval(0.03, 0.15, curve: Curves.easeOut);
  static const Interval splashArc = Interval(0.15, 0.52, curve: Curves.easeInOutCubic);
  static const Interval splashFlare = Interval(0.50, 0.60, curve: Curves.easeOut);
  static const Interval splashSlogan = Interval(0.56, 0.66, curve: Curves.easeOut);
  static const Duration splashToLogin = Duration(milliseconds: 500);

  // ---- Loading overlay (measured) -------------------------------------
  static const Duration loaderFadeIn = Duration(milliseconds: 170);
  static const Duration loaderFadeOut = Duration(milliseconds: 260);
  static const Duration loaderOrbit = Duration(milliseconds: 2400);

  /// Shortest time the loader stays up so it never flashes.
  static const Duration loaderMinimum = Duration(milliseconds: 1400);

  // ---- General (estimated) --------------------------------------------
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration sheet = Duration(milliseconds: 380);
  static const Duration page = Duration(milliseconds: 320);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Cubic(0.2, 0.9, 0.2, 1.0);

  /// Scale applied to pressed controls.
  static const double pressScale = 0.97;
}
