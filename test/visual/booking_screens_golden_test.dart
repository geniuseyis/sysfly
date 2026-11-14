import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysfly/data/mock/demo_catalog.dart';
import 'package:sysfly/data/mock/demo_flights.dart';
import 'package:sysfly/data/mock/demo_seed.dart';
import 'package:sysfly/features/booking/booking_controller.dart';
import 'package:sysfly/features/booking/fare_screen.dart';
import 'package:sysfly/features/booking/passengers_screen.dart';
import 'package:sysfly/features/checkout/confirmation_screen.dart';
import 'package:sysfly/features/checkout/review_screen.dart';
import 'package:sysfly/features/flight_search/flight_results_screen.dart';
import 'package:sysfly/features/home/search_controller.dart';
import 'package:sysfly/features/my_flights/trip_details_screen.dart';
import 'package:sysfly/features/my_flights/trips_controller.dart';
import 'package:sysfly/features/notifications/notifications_screen.dart';
import 'package:sysfly/features/seats/seats_screen.dart';
import 'package:sysfly/features/shell/main_shell.dart';
import 'package:sysfly/features/shell/shell_controller.dart';
import 'package:sysfly/shared/models/models.dart';

import '../support/app_harness.dart';
import '../support/harness.dart';

// Renders every screen of the booking flow in the state shown in the
// reference images, for side-by-side comparison.
void main() {
  setUpAll(loadAppFonts);

  final sin = DemoCatalog.airport('SIN');
  final kul = DemoCatalog.airport('KUL');
  final date = DateTime(2026, 9, 4);
  Flight ak103() => DemoFlights.search(sin, kul, date).first;

  Future<ProviderContainer> boot(WidgetTester tester, {Duration bookingLatency = Duration.zero}) async {
    useReferenceDevice(tester);
    await pumpApp(tester, const SizedBox(key: ValueKey('root')), bookingLatency: bookingLatency);
    return ProviderScope.containerOf(tester.element(find.byKey(const ValueKey('root'))));
  }

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).push(
          PageRouteBuilder<void>(pageBuilder: (_, _, _) => screen, transitionDuration: Duration.zero),
        );
    await settle(tester, const Duration(milliseconds: 800));
  }

  Future<void> shot(String name) => expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

  void startBooking(ProviderContainer container, {bool seat = false, bool baggage = false, bool terms = false}) {
    final flight = ak103();
    final booking = container.read(bookingControllerProvider.notifier)..start(outbound: flight, passengers: 1);
    if (seat) booking.selectSeat(0, DemoSeed.seatMap(flight).seat(15, 'C')!, standardPrice: 6);
    if (baggage) booking.toggleExtra('baggage');
    if (terms) booking.setTerms(true);
  }

  testWidgets('airport sheet', (tester) async {
    await boot(tester);
    await show(tester, const MainShell());
    await tester.tap(find.text('DPS'));
    await settle(tester);
    await shot('airport_sheet');
  });

  testWidgets('airport picker by country', (tester) async {
    await boot(tester);
    await show(tester, const MainShell());
    await tester.tap(find.text('DPS'));
    await settle(tester);
    // Wait for the full catalogue, which loads from an asset.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await settle(tester, const Duration(milliseconds: 300));

    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.byKey(const ValueKey('airport-country-TR')), 400, scrollable: list);
    await settle(tester, const Duration(milliseconds: 300));
    await shot('airport_countries');

    await tester.tap(find.byKey(const ValueKey('airport-country-TR')));
    await settle(tester);
    expect(find.text('Istanbul Airport'), findsOneWidget);
    expect(find.text('Changi'), findsNothing);
    await shot('airport_country_tr');

    await tester.tap(find.byKey(const ValueKey('airport-country-back')));
    await settle(tester);
    expect(find.text('Changi'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'germ');
    await settle(tester);
    expect(find.byKey(const ValueKey('airport-country-DE')), findsOneWidget);
  });

  testWidgets('return date picker', (tester) async {
    final container = await boot(tester);
    container.read(searchControllerProvider.notifier)
      ..setRoute(origin: sin, destination: kul, date: date)
      ..setReturnDate(DateTime(2026, 9, 11));
    await show(tester, const MainShell());
    await tester.tap(find.text('Return'));
    await settle(tester);
    await shot('date_picker');
  });

  testWidgets('results', (tester) async {
    final container = await boot(tester);
    container.read(searchControllerProvider.notifier)
      ..setRoute(origin: sin, destination: kul, date: date)
      ..setReturnDate(DateTime(2026, 9, 11));
    await show(tester, const FlightResultsScreen());
    await shot('results');
  });

  testWidgets('filter sheet', (tester) async {
    final container = await boot(tester);
    container.read(searchControllerProvider.notifier).setRoute(
          origin: DemoCatalog.airport('DPS'),
          destination: DemoCatalog.airport('CGK'),
          date: date,
        );
    await show(tester, const FlightResultsScreen());
    await tester.tap(find.bySemanticsLabel('Filter and sort'));
    await settle(tester);
    await shot('filter_sheet');
  });

  testWidgets('fare', (tester) async {
    final container = await boot(tester);
    startBooking(container);
    await show(tester, const FareScreen());
    await shot('fare');
  });

  testWidgets('passengers', (tester) async {
    final container = await boot(tester);
    startBooking(container);
    await show(tester, const PassengersScreen());
    await shot('passengers');
  });

  testWidgets('seats', (tester) async {
    final container = await boot(tester);
    startBooking(container);
    await show(tester, const SeatsScreen());
    await shot('seats_top');

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -640));
    await settle(tester, const Duration(milliseconds: 600));
    await shot('seats_rows');
  });

  testWidgets('seats with extras', (tester) async {
    final container = await boot(tester);
    startBooking(container, seat: true, baggage: true);
    await show(tester, const SeatsScreen());
    await tester.scrollUntilVisible(find.text('Travel Insurance'), 300, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -70));
    await settle(tester, const Duration(milliseconds: 600));
    await shot('seats_extras');
  });

  testWidgets('review and pay', (tester) async {
    final container = await boot(tester);
    startBooking(container, seat: true, baggage: true);
    await show(tester, const ReviewScreen());
    await shot('review_top');

    await tester.tap(find.byKey(const ValueKey('change-payment')));
    await settle(tester);
    await shot('payment_sheet');
  });

  testWidgets('review and pay, terms accepted', (tester) async {
    final container = await boot(tester);
    startBooking(container, seat: true, baggage: true, terms: true);
    await show(tester, const ReviewScreen());
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await settle(tester, const Duration(milliseconds: 600));
    await shot('review_bottom');
  });

  testWidgets('booking loading', (tester) async {
    final container = await boot(tester, bookingLatency: const Duration(seconds: 3));
    startBooking(container, seat: true, baggage: true, terms: true);
    await show(tester, const ReviewScreen());
    await tester.tap(find.byKey(const ValueKey('booking-continue')));
    await settle(tester, const Duration(milliseconds: 900));
    await shot('booking_loading');
    await settle(tester, const Duration(seconds: 4));
  });

  testWidgets('confirmation and trip details', (tester) async {
    final container = await boot(tester);
    startBooking(container, seat: true, baggage: true, terms: true);
    // The repository waits on a real timer, so run it outside fake time.
    final trip = (await tester.runAsync(() => container.read(bookingControllerProvider.notifier).confirm()))!;
    await tester.runAsync(() => container.read(tripsControllerProvider.notifier).refresh());
    await tester.pump();
    await show(tester, ConfirmationScreen(reference: trip.reference));
    await settle(tester, const Duration(milliseconds: 1200));
    await shot('confirmation');

    await show(tester, TripDetailsScreen(reference: trip.reference));
    await shot('trip_details');
  });

  testWidgets('tracked flights', (tester) async {
    final container = await boot(tester);
    container.read(navigationProvider.notifier).select(AppTab.status);
    await show(tester, const MainShell());
    await tester.scrollUntilVisible(find.text('Tracked flights'), 300, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -330));
    await settle(tester, const Duration(milliseconds: 600));
    await shot('tracked_flights');
  });

  testWidgets('notifications', (tester) async {
    await boot(tester);
    await show(tester, const NotificationsScreen());
    await shot('notifications');
  });
}
