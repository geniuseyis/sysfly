import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../core/design_system/design_system.dart';
import '../../core/services/haptics.dart';
import 'sysfly_navigation_indicator.dart';
import 'sysfly_ticket_action_button.dart';

@immutable
class SysflyNavItem {
  const SysflyNavItem({required this.label, required this.icon, required this.activeIcon});
  final String label;
  final SysflyIconData icon;
  final SysflyIconData activeIcon;
}

/// The floating glass navigation capsule with a sliding selection indicator
/// and a separate round ticket shortcut.
///
/// Geometry (measured on a 440 pt wide canvas): 16 pt side margins, a 62 pt
/// tall bar, a 60 pt ticket button 14 pt to its right, an 84 x 54 pt capsule.
///
/// Motion (measured from the reference recording): one capsule travels
/// between tabs on an underdamped spring, stretches with its speed, overshoots
/// by about 5 % and squashes against the ends of the bar. Icons and labels are
/// recoloured by clipping a white, filled copy of the row to the capsule, so
/// they change exactly where the capsule covers them. Dragging the capsule
/// turns it into a glass lens that follows the finger and snaps to the nearest
/// tab on release.
class SysflyFloatingNavigationBar extends StatefulWidget {
  const SysflyFloatingNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    required this.onTicketTap,
    this.onReselected,
  });

  final List<SysflyNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int>? onReselected;
  final VoidCallback onTicketTap;

  static const double barHeight = 62;
  static const double ticketSize = 60;
  static const double gap = 14;
  static const double sideMargin = 16;

  /// Horizontal padding inside the bar before the first tab.
  static const double innerPadding = 8;

  /// Smallest distance between the capsule and the edge of the bar.
  static const double indicatorInset = 3.5;

  /// How much wider the capsule is than one tab.
  static const double indicatorOutset = 6;

  static const Key indicatorKey = ValueKey('sysfly-nav-indicator');
  static const Key barKey = ValueKey('sysfly-nav-bar');

  @override
  State<SysflyFloatingNavigationBar> createState() => _SysflyFloatingNavigationBarState();
}

class _SysflyFloatingNavigationBarState extends State<SysflyFloatingNavigationBar> with TickerProviderStateMixin {
  /// Indicator centre in tab units: 0 is the first tab, 1 the second.
  late final AnimationController _position;

  /// 0 = navy capsule, 1 = glass lens.
  late final AnimationController _lens;

  bool _dragging = false;
  int _dragTab = 0;
  double _barWidth = 0;

  int get _count => widget.items.length;
  double get _tabWidth => (_barWidth - SysflyFloatingNavigationBar.innerPadding * 2) / _count;
  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(vsync: this, value: widget.currentIndex.toDouble());
    _lens = AnimationController(vsync: this, duration: SysflyMotion.navLens);
  }

  @override
  void didUpdateWidget(SysflyFloatingNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_dragging) {
      _animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    _lens.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    final target = index.toDouble();
    if (_reduceMotion) {
      _position.value = target;
      return;
    }
    // Starting from the current value and velocity keeps rapid taps smooth.
    _position.animateWith(
      SpringSimulation(SysflyMotion.navSpring, _position.value, target, _position.velocity)
        ..tolerance = const Tolerance(distance: 0.001, velocity: 0.01),
    );
  }

  int _tabAt(double dx) {
    final x = dx - SysflyFloatingNavigationBar.innerPadding;
    return (x / _tabWidth).floor().clamp(0, _count - 1);
  }

  void _select(int index) {
    if (index == widget.currentIndex) {
      _animateTo(index);
      widget.onReselected?.call(index);
      return;
    }
    SysflyHaptics.selection();
    widget.onSelected(index);
    // The parent normally rebuilds with the new index, which animates in
    // didUpdateWidget; animate here too so the bar never waits on it.
    _animateTo(index);
  }

  void _onDragStart(DragStartDetails details) {
    _dragging = true;
    _dragTab = _position.value.round().clamp(0, _count - 1);
    _position.stop();
    if (_reduceMotion) {
      _lens.value = 1;
    } else {
      _lens.forward();
    }
    _follow(details.localPosition.dx);
  }

  void _follow(double dx) {
    final raw = (dx - SysflyFloatingNavigationBar.innerPadding) / _tabWidth - 0.5;
    _position.value = raw.clamp(0.0, (_count - 1).toDouble());
    final nearest = _position.value.round();
    if (nearest != _dragTab) {
      _dragTab = nearest;
      SysflyHaptics.selection();
    }
  }

  void _onDragEnd([DragEndDetails? details]) {
    if (!_dragging) return;
    _dragging = false;
    final target = _position.value.round().clamp(0, _count - 1);
    if (_reduceMotion) {
      _lens.value = 0;
    } else {
      _lens.reverse();
    }
    if (target != widget.currentIndex) widget.onSelected(target);
    _animateTo(target);
  }

  /// Capsule rectangle for the current position, velocity and lens amount.
  Rect _indicatorRect() {
    const barH = SysflyFloatingNavigationBar.barHeight;
    const inset = SysflyFloatingNavigationBar.indicatorInset;
    final tabW = _tabWidth;
    final centre = SysflyFloatingNavigationBar.innerPadding + tabW * (_position.value + 0.5);
    final speed = (_position.velocity * tabW).abs();
    final stretch = _dragging ? 0.0 : math.min(SysflyMotion.navMaxStretch, speed * SysflyMotion.navStretchPerVelocity);
    final lens = _lens.value;
    final scale = lerpDouble(1, SysflyMotion.navLensScale, Curves.easeOut.transform(lens))!;
    final width = (tabW + SysflyFloatingNavigationBar.indicatorOutset + stretch) * scale;
    final height = (barH - inset * 2) * scale;

    var left = centre - width / 2;
    var right = centre + width / 2;
    if (lens == 0) {
      // Squash against the ends of the bar instead of sliding past them.
      left = math.max(left, inset);
      right = math.min(right, _barWidth - inset);
      if (right - left < height) {
        if (left <= inset) {
          right = left + height;
        } else {
          left = right - height;
        }
      }
    }
    return Rect.fromLTRB(left, (barH - height) / 2, right, (barH + height) / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SysflyFloatingNavigationBar.sideMargin),
      child: SizedBox(
        height: SysflyFloatingNavigationBar.barHeight,
        child: Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _barWidth = constraints.maxWidth;
                  return _buildBar();
                },
              ),
            ),
            const SizedBox(width: SysflyFloatingNavigationBar.gap),
            SysflyTicketActionButton(onTap: widget.onTicketTap, size: SysflyFloatingNavigationBar.ticketSize),
          ],
        ),
      ),
    );
  }

  /// True where the engine can run the refraction shader (Impeller: iOS and
  /// Android). Elsewhere the bar falls back to a blurred, tinted backdrop.
  static bool get _realGlass => ImageFilter.isShaderFilterSupported;

  static const _barGlass = LiquidGlassSettings(
    thickness: 18,
    blur: 9,
    glassColor: Color(0xA8FFFFFF),
    lightIntensity: 0.7,
    ambientStrength: 0.25,
    saturation: 1.35,
  );

  Widget _buildBar() {
    const radius = BorderRadius.all(Radius.circular(SysflyFloatingNavigationBar.barHeight / 2));
    final bar = Stack(
      key: SysflyFloatingNavigationBar.barKey,
      clipBehavior: Clip.none,
      children: [
        // Shadow, kept outside the clip.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: radius, boxShadow: SysflyShadows.nav),
          ),
        ),
        // Glass: blur only what sits behind the bar.
        if (_realGlass)
          const Positioned.fill(
            child: LiquidGlass.withOwnLayer(
              settings: _barGlass,
              shape: LiquidRoundedRectangle(borderRadius: SysflyFloatingNavigationBar.barHeight / 2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.fromBorderSide(BorderSide(color: Color(0xCCFFFFFF), width: 1.2)),
                ),
                child: SizedBox.expand(),
              ),
            ),
          )
        else
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xF2FBFAFF), Color(0xD9F6F5FF), Color(0xB3E9EAFF)],
                      stops: [0.0, 0.62, 1.0],
                    ),
                    border: Border.all(color: const Color(0xE6FFFFFF), width: 1.4),
                  ),
                ),
              ),
            ),
          ),
        // Idle icons and labels.
        Positioned.fill(
          child: _TabRow(
            items: widget.items,
            active: false,
            currentIndex: widget.currentIndex,
            labelColor: SysflyColors.navInactiveLabel,
            onTap: _select,
          ),
        ),
        // Capsule plus the selected copy of the row, clipped to the capsule.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_position, _lens]),
              builder: (context, _) {
                final rect = _indicatorRect();
                final lens = _lens.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fromRect(
                      rect: rect,
                      child: SysflyNavigationIndicator(key: SysflyFloatingNavigationBar.indicatorKey, lens: lens, paintLens: !_realGlass),
                    ),
                    Positioned.fill(
                      child: ClipPath(
                        clipper: _CapsuleClipper(rect),
                        child: ExcludeSemantics(
                          child: _TabRow(
                            items: widget.items,
                            active: true,
                            currentIndex: widget.currentIndex,
                            color: Color.lerp(const Color(0xFFFFFFFF), SysflyColors.link, lens)!,
                            cutColor: Color.lerp(const Color(0xFF1F2A80), const Color(0xFFFFFFFF), lens),
                            scale: 1 + 0.1 * lens,
                          ),
                        ),
                      ),
                    ),
                    // Clear glass over the tabs: it bends what lies beneath it.
                    if (_realGlass && lens > 0)
                      Positioned.fromRect(
                        rect: rect,
                        child: LiquidGlass.withOwnLayer(
                          settings: LiquidGlassSettings(
                            visibility: lens,
                            thickness: 11,
                            blur: 0.3,
                            glassColor: const Color(0x1AFFFFFF),
                            lightIntensity: 0.9,
                            ambientStrength: 0.2,
                            refractiveIndex: 1.15,
                            saturation: 1.1,
                            chromaticAberration: 0.01,
                          ),
                          shape: LiquidRoundedRectangle(borderRadius: rect.height / 2),
                          child: const SizedBox.expand(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        // Dragging the capsule. Taps are handled per tab in the idle row.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) => _select(_tabAt(details.localPosition.dx)),
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: (details) => _follow(details.localPosition.dx),
            onHorizontalDragEnd: _onDragEnd,
            onHorizontalDragCancel: _onDragEnd,
          ),
        ),
      ],
    );

    // The whole bar swells slightly while the lens is out.
    return AnimatedBuilder(
      animation: _lens,
      builder: (context, child) => Transform.scale(scale: 1 + 0.03 * _lens.value, child: child),
      child: bar,
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.items,
    required this.active,
    required this.currentIndex,
    this.color = SysflyColors.navInactive,
    this.labelColor,
    this.cutColor,
    this.scale = 1,
    this.onTap,
  });

  final List<SysflyNavItem> items;
  final bool active;
  final int currentIndex;
  final Color color;

  /// Defaults to [color].
  final Color? labelColor;

  /// Colour of the cut-out details of filled icons (the capsule behind them).
  final Color? cutColor;
  final double scale;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SysflyFloatingNavigationBar.innerPadding),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == currentIndex,
                label: '${items[i].label} tab',
                onTap: onTap == null ? null : () => onTap!(i),
                child: ExcludeSemantics(
                  child: Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SysflyIcon(active ? items[i].activeIcon : items[i].icon, size: 24, color: color, cutColor: cutColor),
                        const SizedBox(height: 2),
                        TrText(
                          items[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: SysflyTypography.navLabel.copyWith(
                            color: labelColor ?? color,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CapsuleClipper extends CustomClipper<Path> {
  const _CapsuleClipper(this.rect);
  final Rect rect;

  @override
  Path getClip(Size size) => Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)));

  @override
  bool shouldReclip(_CapsuleClipper oldClipper) => oldClipper.rect != rect;
}
