import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysfly/data/repositories/providers.dart';
import 'package:sysfly/features/booking/booking_controller.dart';
import 'package:sysfly/features/booking/fare_screen.dart';
import 'package:sysfly/features/booking/passengers_screen.dart';
import 'package:sysfly/features/checkout/confirmation_screen.dart';
import 'package:sysfly/features/checkout/review_screen.dart';
import 'package:sysfly/features/flight_search/flight_results_screen.dart';
import 'package:sysfly/features/my_flights/trip_details_screen.dart';
import 'package:sysfly/features/my_flights/trips_controller.dart';
import 'package:sysfly/features/seats/seats_screen.dart';
import 'package:sysfly/features/shell/main_shell.dart';
import 'package:sysfly/shared/models/models.dart';
import 'package:sysfly/shared/widgets/widgets.dart';

import '../support/app_harness.dart';
import '../support/harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a traveller can search, book and find the trip in My Flights', (tester) async {
    useReferenceDevice(tester);
    await pumpWholeApp(tester);
    await signIn(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(MainShell)));
    // Trips load lazily the first time something asks for them.
    container.read(tripsControllerProvider);
    await tester.pump();
    expect(container.read(upcomingTripsProvider), hasLength(3));

    // Home -> results for the default route DPS -> CGK on 4 Sep.
    await tester.tap(find.byKey(const ValueKey('search-flight')));
    await settle(tester);
    expect(find.byType(FlightResultsScreen), findsOneWidget);
    expect(find.text('5 Airlines'), findsOneWidget);
    expect(find.byType(SysflyFlightTicket), findsWidgets);

    // Pick the 7:15 AM Citilink flight (base fare 68).
    await scrollToAndTap(tester, find.byKey(const ValueKey('flight-QG801-20260904')));
    expect(find.byType(FareScreen), findsOneWidget);
    // Classic is preselected: 68 + 14 fare + 23 taxes.
    expect(find.text('\$105.00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fare-flex')));
    await settle(tester, const Duration(milliseconds: 400));
    expect(find.text('\$124.00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fare-classic')));
    await settle(tester, const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const ValueKey('booking-continue')));
    await settle(tester);
    expect(find.byType(PassengersScreen), findsOneWidget);
    expect(find.text('Arya Pratama Wijaya'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('booking-continue')));
    await settle(tester);
    expect(find.byType(SeatsScreen), findsOneWidget);
    expect(find.text('Front cabin · 41 of 64 free'), findsOneWidget);

    // Continue stays disabled until a seat is chosen.
    expect(tester.widget<SysflyGradientButton>(find.byKey(const ValueKey('booking-continue'))).onPressed, isNull);
    await scrollToAndTap(tester, find.byKey(const ValueKey('seat-3A')));
    expect(container.read(bookingControllerProvider).seats[0]?.id, '3A');
    expect(find.text('1 seat · no seat fees'), findsOneWidget);

    // An extra-legroom seat replaces it and adds 18.
    await scrollToAndTap(tester, find.byKey(const ValueKey('seat-8A')));
    expect(container.read(bookingControllerProvider).seats, hasLength(1));
    expect(find.text('\$123.00'), findsOneWidget);
    await scrollToAndTap(tester, find.byKey(const ValueKey('seat-3A')));
    expect(find.text('\$105.00'), findsOneWidget);

    // Extra baggage adds 18 live.
    await scrollToAndTap(tester, find.byKey(const ValueKey('extra-baggage')));
    expect(find.text('\$123.00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('booking-continue')));
    await settle(tester);
    expect(find.byType(ReviewScreen), findsOneWidget);
    expect(find.text('Classic fare'), findsOneWidget);
    expect(find.text('Extra Baggage'), findsOneWidget);

    // Pay is disabled until the terms are accepted.
    expect(tester.widget<SysflyGradientButton>(find.byKey(const ValueKey('booking-continue'))).onPressed, isNull);
    await scrollToAndTap(tester, find.byKey(const ValueKey('accept-terms')));
    await tester.tap(find.byKey(const ValueKey('booking-continue')));
    await settle(tester, const Duration(milliseconds: 1500));

    expect(find.byType(ConfirmationScreen), findsOneWidget);
    final trips = container.read(upcomingTripsProvider);
    expect(trips, hasLength(4));
    final booked = container.read(tripsProvider).first;
    expect(booked.reference, startsWith('QG-'));
    expect(booked.totalPaid, 123);
    expect(booked.firstLeg.seat, '3A');
    expect(find.text(booked.reference), findsOneWidget);
    expect(find.text('You’re off to Jakarta'), findsOneWidget);

    // View trip opens the boarding pass for the new booking.
    await tester.tap(find.byKey(const ValueKey('view-trip')));
    await settle(tester);
    expect(find.byType(TripDetailsScreen), findsOneWidget);
    expect(find.byType(SysflyBoardingPass), findsOneWidget);

    // Back on My Flights the new booking is listed.
    await tester.tap(find.byKey(SysflyHeader.backKey));
    await settle(tester);
    expect(find.text('4 trips'), findsOneWidget);
    expect(find.byKey(ValueKey('trip-${booked.reference}')), findsOneWidget);

    // The seat is now taken for the next traveller on that flight.
    final map = (await tester.runAsync(() => container.read(flightRepositoryProvider).seatMap(booked.firstLeg.flight)))!;
    expect(map.seat(3, 'A')!.availability, SeatAvailability.occupied);
  });
}
