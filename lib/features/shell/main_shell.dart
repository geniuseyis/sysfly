import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../shared/widgets/widgets.dart';
import '../flight_status/flight_status_screen.dart';
import '../home/home_screen.dart';
import '../my_flights/my_flights_screen.dart';
import '../my_flights/trips_controller.dart';
import '../profile/profile_screen.dart';
import 'shell_controller.dart';

/// Hosts the four tab screens under the floating navigation bar.
///
/// Tabs stay alive once visited and cross-fade over 200 ms, which is what the
/// reference shows; the bar stays put and its capsule slides at the same time.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _items = [
    SysflyNavItem(label: 'Home', icon: SysflyIcons.home, activeIcon: SysflyIcons.homeFill),
    SysflyNavItem(label: 'Flights', icon: SysflyIcons.flights, activeIcon: SysflyIcons.flightsFill),
    SysflyNavItem(label: 'Status', icon: SysflyIcons.status, activeIcon: SysflyIcons.statusFill),
    SysflyNavItem(label: 'Profile', icon: SysflyIcons.profile, activeIcon: SysflyIcons.profileFill),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(navigationProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // The bar rests on the home indicator inset (34 pt on the reference
    // device) and never sits closer than 16 pt to the bottom edge.
    final barBottom = bottomInset > 16 ? bottomInset : 16.0;

    return Scaffold(
      backgroundColor: SysflyColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: TabSwitcher(
              index: tab.index,
              builders: [
                (_) => const HomeScreen(),
                (_) => const MyFlightsScreen(),
                (_) => const FlightStatusScreen(),
                (_) => const ProfileScreen(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: barBottom,
            child: SysflyFloatingNavigationBar(
              items: _items,
              currentIndex: tab.index,
              onSelected: (index) => ref.read(navigationProvider.notifier).select(AppTab.values[index]),
              onTicketTap: () {
                // Straight to the next boarding pass, or to My Flights when
                // there is no upcoming trip.
                final next = ref.read(nextTripProvider);
                if (next != null) {
                  context.push(Routes.tripDetails(next.reference));
                } else {
                  ref.read(navigationProvider.notifier).select(AppTab.flights);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cross-fades between lazily built, kept-alive children.
class TabSwitcher extends StatefulWidget {
  const TabSwitcher({super.key, required this.index, required this.builders});

  final int index;
  final List<WidgetBuilder> builders;

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: SysflyMotion.tabFade, value: 1);
  late final CurvedAnimation _fadeIn = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
  late final CurvedAnimation _fadeOutCurve = CurvedAnimation(parent: _fade, curve: Curves.easeIn);
  late final Animation<double> _fadeOut = ReverseAnimation(_fadeOutCurve);
  late int _current = widget.index;
  int? _previous;
  late final Set<int> _built = {widget.index};

  @override
  void initState() {
    super.initState();
    _fade.addStatusListener((status) {
      if (status == AnimationStatus.completed && _previous != null && mounted) {
        setState(() => _previous = null);
      }
    });
  }

  @override
  void didUpdateWidget(TabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _current) return;
    _previous = _current;
    _current = widget.index;
    _built.add(_current);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _previous = null;
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    _fadeOutCurve.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.builders.length; i++)
          if (_built.contains(i))
            Offstage(
              key: ValueKey('tab-$i'),
              offstage: i != _current && i != _previous,
              child: TickerMode(
                enabled: i == _current || i == _previous,
                child: IgnorePointer(
                  ignoring: i != _current,
                  child: FadeTransition(
                    opacity: i == _current
                        ? _fadeIn
                        : i == _previous
                            ? _fadeOut
                            : const AlwaysStoppedAnimation(1),
                    child: Builder(builder: widget.builders[i]),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
