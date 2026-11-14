import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sysfly/core/utils/formatters.dart';
import 'package:sysfly/core/utils/trip_documents.dart';
import 'package:sysfly/core/utils/validators.dart';
import 'package:sysfly/data/mock/demo_catalog.dart';
import 'package:sysfly/data/mock/demo_flights.dart';
import 'package:sysfly/data/mock/demo_seed.dart';
import 'package:sysfly/features/booking/booking_controller.dart';
import 'package:sysfly/features/flight_filters/flight_filter.dart';
import 'package:sysfly/shared/models/models.dart';

void main() {
  final date = DateTime(2026, 9, 4);
  final dps = DemoCatalog.airport('DPS');
  final cgk = DemoCatalog.airport('CGK');
  final sin = DemoCatalog.airport('SIN');
  final kul = DemoCatalog.airport('KUL');

  group('demo timetable', () {
    test('the same search always returns the same flights', () {
      final a = DemoFlights.search(dps, cgk, date);
      final b = DemoFlights.search(dps, cgk, date);
      expect(a.map((f) => '${f.id} ${f.basePrice}'), b.map((f) => '${f.id} ${f.basePrice}'));
      expect(a, hasLength(6));
    });

    test('routes without a seeded timetable still have flights, sorted by time', () {
      final flights = DemoFlights.search(DemoCatalog.airport('BKK'), DemoCatalog.airport('NRT'), date);
      expect(flights, isNotEmpty);
      for (var i = 1; i < flights.length; i++) {
        expect(flights[i].departure.isBefore(flights[i - 1].departure), isFalse);
      }
    });

    test('arrival accounts for the time zone difference', () {
      // Denpasar is an hour ahead of Jakarta: 6:05 + 1h50 - 1h = 6:55.
      final ga159 = DemoFlights.byNumber('GA 159', date)!;
      expect(Fmt.time(ga159.departure), '6:05 AM');
      expect(Fmt.time(ga159.arrival), '6:55 AM');
    });

    test('a search from an airport to itself is empty', () {
      expect(DemoFlights.search(dps, dps, date), isEmpty);
    });
  });

  group('filters', () {
    final flights = DemoFlights.search(dps, cgk, date);

    test('sorts by price, time and duration', () {
      expect(const FlightFilter(sort: FlightSort.cheapest).apply(flights).first.basePrice, 68);
      expect(const FlightFilter().apply(flights).first.number, 'GA 159');
      expect(const FlightFilter(sort: FlightSort.fastest).apply(flights).first.duration.inMinutes, 110);
    });

    test('day part and airline filters narrow the list', () {
      final morning = const FlightFilter(dayParts: {DayPart.morning}).apply(flights);
      expect(morning, hasLength(3));
      expect(morning.every((f) => f.dayPart == DayPart.morning), isTrue);

      final citilink = const FlightFilter(airlines: {'QG'}).apply(flights);
      expect(citilink.map((f) => f.number), ['QG 801', 'QG 815']);

      expect(const FlightFilter(dayParts: {DayPart.night}).apply(flights), isEmpty);
    });

    test('airline floor prices are listed cheapest first', () {
      final floors = airlineFloorPrices(flights);
      expect(floors.first.$1.name, 'Citilink');
      expect(floors.first.$2, 68);
      expect(floors.map((e) => e.$2).toList(), [68, 75, 80, 110, 132]);
    });
  });

  group('pricing', () {
    final flight = DemoFlights.search(sin, kul, date).first; // AK 103, base 88
    BookingDraft draft({FareType fare = FareType.classic, int travellers = 1}) => BookingDraft.empty.copyWith(
          outbound: flight,
          fareType: fare,
          travellers: List<Passenger?>.filled(travellers, DemoCatalog.traveller),
        );

    test('classic fare plus taxes matches the reference total', () {
      final price = priceOf(draft(), DemoCatalog.extras);
      expect(price.total, 128); // 102 fare + 26 taxes
      expect(price.taxes, 26);
    });

    test('a standard seat is free on Classic and charged on Lite', () {
      final seat = DemoSeed.seatMap(flight).seat(15, 'C')!;
      expect(priceOf(draft().copyWith(seats: {0: seat}), DemoCatalog.extras).total, 128);
      expect(priceOf(draft(fare: FareType.lite).copyWith(seats: {0: seat}), DemoCatalog.extras).total, 88 + 26 + 6);
    });

    test('extra legroom always costs its surcharge', () {
      final seat = DemoSeed.seatMap(flight).seat(8, 'A')!;
      expect(seat.kind, SeatKind.extraLegroom);
      expect(priceOf(draft().copyWith(seats: {0: seat}), DemoCatalog.extras).total, 128 + 18);
    });

    test('extras are charged per traveller and a promo takes 10% off the fare', () {
      final two = draft(travellers: 2).copyWith(extraIds: {'baggage'});
      expect(priceOf(two, DemoCatalog.extras).total, (102 + 26 + 18) * 2);

      final promo = draft().copyWith(promo: DemoCatalog.promoCodes.first);
      expect(priceOf(promo, DemoCatalog.extras).total, 128 - 10);
    });
  });

  group('seat map', () {
    test('the front cabin has 41 of 64 seats free, as in the reference', () {
      final map = DemoSeed.seatMap(DemoFlights.byNumber('AK 103', date)!);
      expect(map.totalIn(1, 16), 64);
      expect(map.freeIn(1, 16), 41);
    });

    test('reserved seats show as taken', () {
      final map = DemoSeed.seatMap(DemoFlights.byNumber('AK 103', date)!, reserved: {'3A'});
      expect(map.seat(3, 'A')!.isSelectable, isFalse);
    });
  });

  group('validators', () {
    test('email, password and names', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.fullName('Arya'), isNotNull);
      expect(Validators.fullName('Arya Pratama'), isNull);
    });

    test('card numbers are Luhn-checked and expiry must be in the future', () {
      expect(Validators.cardNumber('4242 4242 4242 4242'), isNull);
      expect(Validators.cardNumber('4242 4242 4242 4241'), isNotNull);
      final now = DateTime(2026, 9, 3);
      expect(Validators.cardExpiry('08/29', now), isNull);
      expect(Validators.cardExpiry('08/26', now), isNotNull);
      expect(Validators.cardExpiry('13/29', now), isNotNull);
    });
  });

  group('trip documents', () {
    final trip = DemoSeed.trips().first;

    test('the e-ticket is a structurally valid one-page PDF', () {
      final bytes = TripDocuments.eTicketPdf(trip);
      final text = ascii.decode(bytes);
      expect(text.startsWith('%PDF-1.4'), isTrue);
      expect(text.trimRight().endsWith('%%EOF'), isTrue);
      expect(text, contains(trip.reference));

      // The cross-reference table must point at each object.
      final xref = int.parse(RegExp(r'startxref\n(\d+)').firstMatch(text)!.group(1)!);
      expect(text.substring(xref, xref + 4), 'xref');
      final offsets = RegExp(r'(\d{10}) 00000 n').allMatches(text).map((m) => int.parse(m.group(1)!)).toList();
      expect(offsets, hasLength(6));
      for (var i = 0; i < offsets.length; i++) {
        expect(text.substring(offsets[i]).startsWith('${i + 1} 0 obj'), isTrue);
      }
    });

    test('the calendar file has one event per flight in UTC', () {
      final ics = TripDocuments.calendar(DemoSeed.trips()[1]);
      expect('BEGIN:VEVENT'.allMatches(ics), hasLength(2));
      // CGK 6:40 AM local (UTC+7) on 12 Sep is 23:40 UTC on 11 Sep.
      expect(ics, contains('DTSTART:20260911T234000Z'));
    });
  });


  group('Turkish Airlines sample data', () {
    final ist = DemoCatalog.airport('IST');
    final esb = DemoCatalog.airport('ESB');

    test('Istanbul routes are flown by Turkish carriers', () {
      final flights = DemoFlights.search(ist, esb, date);
      expect(flights.map((f) => f.airline.code).toSet(), {'TK', 'VF'});
      expect(DemoFlights.byNumber('TK 1', date)!.destination.code, 'JFK');
    });

    test('TK flights offer EcoFly, ExtraFly and PrimeFly; others keep their fares', () {
      final tk = DemoFlights.search(ist, esb, date).firstWhere((f) => f.airline.code == 'TK');
      expect(Fare.forFlight(tk).map((f) => f.name), ['EcoFly', 'ExtraFly', 'PrimeFly']);
      expect(Fare.forFlight(tk)[1].mostPopular, isTrue);
      final ak = DemoFlights.search(sin, kul, date).first;
      expect(Fare.forFlight(ak).map((f) => f.name), ['Lite', 'Classic', 'Flex']);
    });

    test('generated routes to Türkiye use Turkish carriers', () {
      final flights = DemoFlights.search(DemoCatalog.airport('AYT'), DemoCatalog.airport('ADB'), date);
      expect(flights, isNotEmpty);
      expect(flights.every((f) => {'TK', 'VF', 'PC'}.contains(f.airline.code)), isTrue);
    });
  });

  group('Turkish passenger details', () {
    test('T.C. identity numbers are checked with the official algorithm', () {
      expect(Validators.turkishId('10000000146'), isNull);
      expect(Validators.turkishId('10000000147'), isNotNull);
      expect(Validators.turkishId('01234567890'), isNotNull);
      expect(Validators.turkishId('1234'), isNotNull);
    });

    test('Miles&Smiles numbers are optional but must look right', () {
      expect(Validators.milesSmiles(''), isNull);
      expect(Validators.milesSmiles('tk 123456789'), isNull);
      expect(Validators.milesSmiles('TK12345'), isNotNull);
    });

    test('nationality spellings of Türkiye are recognised', () {
      for (final v in ['Türkiye', 'turkey', 'TR', 'Turquie']) {
        expect(Validators.isTurkish(v), isTrue, reason: v);
      }
      expect(Validators.isTurkish('Indonesia'), isFalse);
    });

    test('names may use Turkish letters', () {
      expect(Validators.fullName('Elif Yılmaz'), isNull);
      expect(Validators.fullName('Çağrı Öztürk'), isNull);
      expect(Validators.fullName('Arya 7'), isNotNull);
    });

    test('a traveller without a passport is masked safely', () {
      final p = DemoCatalog.savedTravellers.last.copyWith();
      expect(p.maskedNationalId, '•• 0146');
      expect(p.hasPassport, isTrue);
    });
  });

  test('formatters', () {
    expect(Fmt.money(1234), '\$1,234.00');
    expect(Fmt.dayShort(date), 'Fri, 4 Sep');
    expect(Fmt.countdown(const Duration(hours: 10, minutes: 35)), '10h 35m');
    expect(Fmt.countdown(const Duration(days: 8, hours: 2)), '8 days');
    expect(Fmt.duration(const Duration(minutes: 110)), '1h 50m');
  });
}
