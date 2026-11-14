import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysfly/core/design_system/design_system.dart';
import 'package:sysfly/data/mock/demo_catalog.dart';
import 'package:sysfly/data/mock/demo_flights.dart';
import 'package:sysfly/features/booking/booking_controller.dart';
import 'package:sysfly/features/booking/fare_screen.dart';
import 'package:sysfly/features/booking/passengers_screen.dart';
import 'package:sysfly/features/profile/widgets/profile_sheets.dart';
import 'package:sysfly/features/shell/main_shell.dart';
import 'package:sysfly/features/shell/shell_controller.dart';
import 'package:sysfly/shared/widgets/widgets.dart';

import '../support/app_harness.dart';
import '../support/harness.dart';

// Screens used in the README that the other visual tests do not cover:
// Turkish Airlines data, the THY-style traveller form, other languages and
// the app icon artwork.
void main() {
  setUpAll(loadAppFonts);
  tearDown(() => L10n.use(AppLanguage.en));

  final date = DateTime(2026, 9, 4);

  Future<ProviderContainer> boot(WidgetTester tester) async {
    useReferenceDevice(tester);
    await pumpApp(tester, const SizedBox(key: ValueKey('root')));
    return ProviderScope.containerOf(tester.element(find.byKey(const ValueKey('root'))));
  }

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).push(
          PageRouteBuilder<void>(pageBuilder: (_, _, _) => screen, transitionDuration: Duration.zero),
        );
    await settle(tester, const Duration(milliseconds: 800));
  }

  Future<void> shot(String name) => expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/readme_$name.png'));

  void startTurkishBooking(ProviderContainer container) {
    final flight = DemoFlights.search(DemoCatalog.airport('IST'), DemoCatalog.airport('ESB'), date).first;
    container.read(bookingControllerProvider.notifier)
      ..start(outbound: flight, passengers: 2)
      ..setTraveller(1, DemoCatalog.savedTravellers.last);
  }

  testWidgets('Turkish Airlines fare families', (tester) async {
    final container = await boot(tester);
    startTurkishBooking(container);
    await show(tester, const FareScreen());
    await shot('fare_tk');
  });

  testWidgets('THY-style traveller details', (tester) async {
    final container = await boot(tester);
    startTurkishBooking(container);
    await show(tester, const PassengersScreen());
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await settle(tester, const Duration(milliseconds: 400));
    await shot('passengers_tk');

    await tester.tap(find.byKey(const ValueKey('traveller-edit-1')));
    await settle(tester);
    await shot('passenger_form_tk');
  });

  // Arabic is left out: the test fonts have no Arabic glyphs.
  for (final language in [AppLanguage.tr, AppLanguage.de]) {
    testWidgets('home in ${language.name}', (tester) async {
      final container = await boot(tester);
      await container.read(languageProvider.notifier).set(language);
      container.read(navigationProvider.notifier).select(AppTab.home);
      await show(tester, const MainShell());
      await shot('home_${language.name}');
    });
  }

  testWidgets('language picker in German', (tester) async {
    final container = await boot(tester);
    await container.read(languageProvider.notifier).set(AppLanguage.de);
    container.read(navigationProvider.notifier).select(AppTab.profile);
    await show(tester, const MainShell());
    showLanguageSheet(tester.element(find.byType(MainShell)));
    await settle(tester);
    await shot('language_de');
  });

  testWidgets('app icon artwork', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1024, 1024);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const Directionality(textDirection: TextDirection.ltr, child: AppIconArt()));
    await expectLater(find.byType(AppIconArt), matchesGoldenFile('goldens/readme_app_icon.png'));
  });
}

/// The launcher icon: the script "s" of the wordmark under its flight trail
/// on the splash gradient. Full bleed; each platform applies its own mask.
class AppIconArt extends StatelessWidget {
  const AppIconArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C0E2B), Color(0xFF141A52), Color(0xFF26389A)],
        ),
      ),
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The trail spans a box wider than the letter so it arcs over it.
            Positioned(
              left: 70,
              top: 120,
              width: 372,
              height: 250,
              child: CustomPaint(painter: FlightTrailPainter(progress: 1, flare: 1)),
            ),
            Positioned(
              top: 128,
              child: Text(
                's',
                textScaler: TextScaler.noScaling,
                style: TextStyle(fontFamily: SysflyTypography.brandFamily, fontSize: 340, color: Colors.white, height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
