import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysfly/core/design_system/design_system.dart';
import 'package:sysfly/shared/widgets/widgets.dart';

import '../support/harness.dart';

void main() {
  setUpAll(loadAppFonts);

  const items = [
    SysflyNavItem(label: 'Home', icon: SysflyIcons.home, activeIcon: SysflyIcons.homeFill),
    SysflyNavItem(label: 'Flights', icon: SysflyIcons.flights, activeIcon: SysflyIcons.flightsFill),
    SysflyNavItem(label: 'Status', icon: SysflyIcons.status, activeIcon: SysflyIcons.statusFill),
    SysflyNavItem(label: 'Profile', icon: SysflyIcons.profile, activeIcon: SysflyIcons.profileFill),
  ];

  late int selected;
  late int ticketTaps;

  Future<void> pumpBar(WidgetTester tester, {bool disableAnimations = false}) async {
    useReferenceDevice(tester);
    selected = 0;
    ticketTaps = 0;
    await pumpApp(
      tester,
      disableAnimations: disableAnimations,
      Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: StatefulBuilder(
            builder: (context, setState) => SysflyFloatingNavigationBar(
              items: items,
              currentIndex: selected,
              onSelected: (i) => setState(() => selected = i),
              onTicketTap: () => ticketTaps++,
            ),
          ),
        ),
      ),
    );
  }

  Rect indicator(WidgetTester tester) => tester.getRect(find.byKey(SysflyFloatingNavigationBar.indicatorKey));
  Rect bar(WidgetTester tester) => tester.getRect(find.byKey(SysflyFloatingNavigationBar.barKey));

  /// Centre of tab [index] on screen.
  Offset tab(WidgetTester tester, int index) {
    final b = bar(tester);
    const pad = SysflyFloatingNavigationBar.innerPadding;
    return Offset(b.left + pad + (b.width - pad * 2) * (index + 0.5) / 4, b.center.dy);
  }

  Future<void> settleBar(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  testWidgets('the capsule travels to the tapped tab instead of jumping', (tester) async {
    await pumpBar(tester);
    final start = indicator(tester).center.dx;
    expect(start, moreOrLessEquals(tab(tester, 0).dx, epsilon: 1));

    await tester.tapAt(tab(tester, 1));
    await tester.pump();
    final target = tab(tester, 1).dx;

    // Sample the flight: it must pass through intermediate positions,
    // overshoot slightly, and come to rest on the target.
    final samples = <double>[];
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      samples.add(indicator(tester).center.dx);
    }
    expect(samples.first, greaterThan(start));
    expect(samples.first, lessThan(target));
    expect(samples.reduce((a, b) => a > b ? a : b), greaterThan(target), reason: 'the spring should overshoot');
    final overshoot = (samples.reduce((a, b) => a > b ? a : b) - target) / (target - start);
    expect(overshoot, inInclusiveRange(0.02, 0.09));

    await settleBar(tester);
    expect(indicator(tester).center.dx, moreOrLessEquals(target, epsilon: 0.5));
    expect(selected, 1);
  });

  testWidgets('the capsule stretches while moving and returns to its resting width', (tester) async {
    await pumpBar(tester);
    final resting = indicator(tester).width;
    await tester.tapAt(tab(tester, 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(indicator(tester).width, greaterThan(resting + 2));
    await settleBar(tester);
    expect(indicator(tester).width, moreOrLessEquals(resting, epsilon: 0.5));
  });

  testWidgets('every transition lands on the right tab', (tester) async {
    await pumpBar(tester);
    for (final index in [1, 2, 3, 0, 2, 1]) {
      await tester.tapAt(tab(tester, index));
      await settleBar(tester);
      expect(selected, index);
      expect(indicator(tester).center.dx, moreOrLessEquals(tab(tester, index).dx, epsilon: 0.5));
    }
  });

  testWidgets('rapid taps do not break the animation', (tester) async {
    await pumpBar(tester);
    for (final index in [3, 1, 2, 0, 3]) {
      await tester.tapAt(tab(tester, index));
      await tester.pump(const Duration(milliseconds: 40));
      final rect = indicator(tester);
      final b = bar(tester);
      // The capsule always stays inside the bar.
      expect(rect.left, greaterThanOrEqualTo(b.left));
      expect(rect.right, lessThanOrEqualTo(b.right));
    }
    await settleBar(tester);
    expect(selected, 3);
    expect(indicator(tester).center.dx, moreOrLessEquals(tab(tester, 3).dx, epsilon: 0.5));
  });

  testWidgets('tapping the selected tab again keeps it selected and in place', (tester) async {
    await pumpBar(tester);
    final before = indicator(tester);
    await tester.tapAt(tab(tester, 0));
    await settleBar(tester);
    expect(selected, 0);
    expect(indicator(tester), before);
  });

  testWidgets('dragging the capsule follows the finger and selects on release', (tester) async {
    await pumpBar(tester);
    final gesture = await tester.startGesture(tab(tester, 0));
    await gesture.moveTo(Offset.lerp(tab(tester, 0), tab(tester, 2), 0.5)!);
    await gesture.moveTo(tab(tester, 2));
    await settleBar(tester);
    // While held it is a lens: larger than the resting capsule.
    expect(indicator(tester).height, greaterThan(SysflyFloatingNavigationBar.barHeight));
    await gesture.up();
    await settleBar(tester);
    expect(selected, 2);
    expect(indicator(tester).height, lessThan(SysflyFloatingNavigationBar.barHeight));
  });

  testWidgets('the ticket shortcut is independent of the tabs', (tester) async {
    await pumpBar(tester);
    await tester.tap(find.byType(SysflyTicketActionButton));
    await settleBar(tester);
    expect(ticketTaps, 1);
    expect(selected, 0);
  });

  testWidgets('with Reduce Motion the capsule moves at once', (tester) async {
    await pumpBar(tester, disableAnimations: true);
    await tester.tapAt(tab(tester, 3));
    await tester.pump();
    await tester.pump();
    expect(indicator(tester).center.dx, moreOrLessEquals(tab(tester, 3).dx, epsilon: 0.5));
  });

  testWidgets('tabs are exposed to assistive technology', (tester) async {
    await pumpBar(tester);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Home tab'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile tab'), findsOneWidget);
    expect(find.bySemanticsLabel('Boarding pass'), findsOneWidget);
    handle.dispose();
  });
}
