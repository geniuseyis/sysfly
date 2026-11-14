import 'dart:math' as math;

import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import 'demo_catalog.dart';

/// Builds the demo timetable. Routes that appear in the reference designs are
/// written out by hand; every other route is generated deterministically from
/// the route and date so the same search always returns the same flights.
abstract final class DemoFlights {
  static final DateTime referenceDate = DateTime(2026, 9, 4);

  /// (airline, number, hour, minute, duration minutes, price, seats left)
  static const _timetable = <String, List<(String, int, int, int, int, int, int)>>{
    'SIN-KUL': [
      ('AK', 103, 6, 20, 60, 88, 7),
      ('MH', 602, 10, 10, 60, 125, 5),
      ('TR', 452, 13, 45, 65, 96, 9),
      ('SQ', 114, 18, 30, 60, 168, 4),
    ],
    'KUL-SIN': [
      ('AK', 104, 8, 5, 60, 84, 6),
      ('MH', 603, 12, 40, 60, 119, 8),
      ('TR', 453, 16, 15, 65, 92, 5),
      ('SQ', 115, 20, 45, 60, 161, 3),
    ],
    'DPS-CGK': [
      ('GA', 159, 6, 5, 110, 132, 6),
      ('QG', 801, 7, 15, 115, 68, 9),
      ('QZ', 7511, 9, 40, 115, 75, 4),
      ('IU', 733, 12, 30, 115, 80, 8),
      ('ID', 6501, 15, 20, 110, 110, 5),
      ('QG', 815, 18, 10, 115, 72, 7),
    ],
    'CGK-DPS': [
      ('GA', 402, 7, 0, 110, 128, 5),
      ('QG', 800, 8, 30, 115, 66, 8),
      ('QZ', 7510, 11, 5, 115, 74, 6),
      ('IU', 732, 14, 10, 115, 79, 9),
      ('ID', 6500, 17, 45, 110, 108, 4),
    ],
    'HLP-BTH': [
      ('IU', 853, 11, 50, 100, 52, 6),
      ('QG', 942, 14, 25, 100, 58, 8),
      ('ID', 6862, 17, 5, 100, 74, 5),
    ],
    'CGK-SUB': [
      ('GA', 128, 6, 40, 90, 86, 7),
      ('QG', 716, 9, 15, 90, 48, 9),
      ('ID', 6370, 13, 0, 90, 71, 6),
      ('IU', 612, 16, 35, 90, 55, 8),
    ],
    'SUB-DPS': [
      ('GA', 103, 6, 30, 60, 78, 6),
      ('QG', 690, 10, 20, 60, 44, 9),
      ('IU', 388, 15, 40, 60, 49, 7),
    ],
    'DPS-SIN': [
      ('SQ', 146, 15, 55, 160, 214, 5),
      ('TR', 281, 9, 35, 160, 79, 8),
      ('QZ', 504, 12, 15, 165, 92, 6),
      ('GA', 842, 18, 50, 160, 186, 4),
    ],
    'MEL-DPS': [
      ('JQ', 111, 11, 40, 350, 189, 5),
      ('QF', 43, 9, 15, 345, 268, 6),
    ],
    'CGK-SIN': [
      ('SQ', 951, 7, 45, 105, 148, 5),
      ('TR', 279, 10, 30, 110, 79, 6),
      ('GA', 824, 13, 20, 110, 121, 7),
      ('QZ', 262, 17, 0, 110, 86, 8),
    ],
    // Sample Turkish routes. Flight numbers follow the patterns the carriers
    // use; times and fares are invented.
    'IST-ESB': [
      ('TK', 2120, 7, 0, 70, 52, 9),
      ('TK', 2126, 11, 30, 70, 46, 6),
      ('VF', 3020, 15, 10, 70, 34, 8),
      ('TK', 2140, 19, 45, 70, 58, 5),
    ],
    'ESB-IST': [
      ('TK', 2121, 9, 0, 70, 50, 7),
      ('TK', 2133, 14, 20, 70, 48, 5),
      ('VF', 3021, 17, 30, 70, 35, 9),
    ],
    'IST-AYT': [
      ('TK', 2412, 8, 15, 75, 55, 7),
      ('VF', 3040, 12, 40, 75, 39, 8),
      ('TK', 2418, 18, 5, 75, 61, 4),
    ],
    'IST-ADB': [
      ('TK', 2310, 7, 30, 65, 49, 6),
      ('VF', 3060, 13, 15, 65, 33, 9),
      ('TK', 2322, 20, 10, 65, 54, 5),
    ],
    'SAW-ESB': [
      ('PC', 2660, 8, 20, 65, 31, 8),
      ('VF', 3120, 12, 0, 65, 34, 6),
      ('PC', 2674, 18, 40, 65, 29, 9),
    ],
    'SAW-AYT': [
      ('PC', 2014, 9, 10, 75, 36, 7),
      ('VF', 3160, 16, 30, 75, 38, 5),
    ],
    'IST-LHR': [
      ('TK', 1979, 7, 40, 255, 214, 6),
      ('TK', 1971, 13, 10, 255, 236, 4),
      ('TK', 1985, 17, 45, 255, 198, 8),
    ],
    'LHR-IST': [
      ('TK', 1980, 11, 50, 235, 221, 5),
      ('TK', 1972, 17, 10, 235, 205, 7),
    ],
    'IST-JFK': [
      ('TK', 3, 8, 10, 665, 742, 5),
      ('TK', 1, 13, 55, 660, 689, 6),
    ],
    'JFK-IST': [
      ('TK', 4, 13, 40, 600, 668, 6),
      ('TK', 2, 23, 10, 600, 701, 4),
    ],
    'IST-SIN': [('TK', 54, 1, 55, 625, 612, 5)],
    'IST-CGK': [('TK', 56, 1, 45, 680, 598, 6)],
    'IST-DPS': [('TK', 66, 2, 5, 735, 655, 4)],
    'IST-KUL': [('TK', 60, 1, 20, 610, 574, 5)],
    'SIN-DPS': [
      ('SQ', 147, 15, 55, 160, 209, 6),
      ('TR', 145, 18, 40, 160, 82, 7),
      ('QZ', 505, 8, 25, 165, 89, 5),
      ('GA', 843, 11, 30, 160, 181, 4),
    ],
  };

  static double _distanceKm(Airport a, Airport b) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLon = rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  static int _hash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  static Flight build({
    required String airlineCode,
    required int number,
    required Airport origin,
    required Airport destination,
    required DateTime date,
    required int hour,
    required int minute,
    required int durationMinutes,
    required int price,
    int seatsLeft = 6,
    CabinClass cabin = CabinClass.economy,
  }) {
    final departure = DateTime(date.year, date.month, date.day, hour, minute);
    final shift = ((destination.utcOffsetHours - origin.utcOffsetHours) * 60).round();
    final arrival = departure.add(Duration(minutes: durationMinutes + shift));
    return Flight(
      id: '$airlineCode$number-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}',
      airline: DemoCatalog.airline(airlineCode),
      number: '$airlineCode $number',
      origin: origin,
      destination: destination,
      departure: departure,
      arrival: arrival,
      duration: Duration(minutes: durationMinutes),
      basePrice: (price * cabin.multiplier).round(),
      seatsLeft: seatsLeft,
      aircraft: durationMinutes > 240 ? 'Airbus A330-300' : 'Airbus A320neo',
      cabin: cabin,
    );
  }

  /// Price swing for a date: none on the reference date, otherwise a stable
  /// -9 % to +9 % with weekends a little dearer.
  static double _dateFactor(String route, DateTime date) {
    if (Fmt.sameDay(date, referenceDate)) return 1;
    // The price-drop alert quotes this fare, so it is pinned too.
    if (route == 'CGK-SIN' && Fmt.sameDay(date, DateTime(2026, 10, 9))) return 1;
    final swing = ((_hash('${date.year}-${date.month}-${date.day}') % 7) - 3) * 0.03;
    final weekend = date.weekday >= DateTime.saturday ? 0.06 : 0.0;
    return 1 + swing + weekend;
  }

  static List<Flight> search(Airport origin, Airport destination, DateTime date, {CabinClass cabin = CabinClass.economy}) {
    if (origin == destination) return const [];
    final key = '${origin.code}-${destination.code}';
    final factor = _dateFactor(key, date);
    final seeded = _timetable[key];
    if (seeded != null) {
      return [
        for (final (code, number, h, m, dur, price, seats) in seeded)
          build(
            airlineCode: code,
            number: number,
            origin: origin,
            destination: destination,
            date: date,
            hour: h,
            minute: m,
            durationMinutes: dur,
            price: (price * factor).round(),
            seatsLeft: Fmt.sameDay(date, referenceDate) ? seats : 2 + _hash('$key$number${date.day}') % 8,
            cabin: cabin,
          ),
      ]..sort((a, b) => a.departure.compareTo(b.departure));
    }

    final km = _distanceKm(origin, destination);
    final duration = ((30 + km / 780 * 60) / 5).round() * 5;
    final carriers = <String>{
      ...?DemoCatalog.carriersByCountry[origin.countryCode],
      ...?DemoCatalog.carriersByCountry[destination.countryCode],
    }.toList();
    // Countries without a home carrier in the demo get airlines from the pool.
    if (carriers.isEmpty) carriers.addAll(DemoCatalog.airlines.keys);
    final seed = _hash(key);
    final count = 4 + seed % 3;
    final basePrice = 38 + km * 0.085;
    const slots = [(6, 15), (8, 50), (11, 25), (14, 5), (17, 40), (20, 30)];
    final flights = <Flight>[];
    for (var i = 0; i < count; i++) {
      final code = carriers[(seed + i * 3) % carriers.length];
      final (h, m) = slots[(seed + i) % slots.length];
      final tier = 0.82 + ((_hash('$key$code$i') % 60) / 100);
      flights.add(build(
        airlineCode: code,
        number: 100 + _hash('$key$i') % 880,
        origin: origin,
        destination: destination,
        date: date,
        hour: h,
        minute: m,
        durationMinutes: duration,
        price: (basePrice * tier * factor).round(),
        seatsLeft: 2 + _hash('$key$i${date.day}') % 8,
        cabin: cabin,
      ));
    }
    final seen = <String>{};
    flights.retainWhere((f) => seen.add('${f.departure.hour}:${f.departure.minute}'));
    flights.sort((a, b) => a.departure.compareTo(b.departure));
    return flights;
  }

  static int _flightSeed(Flight flight) => flight.id.codeUnits.fold<int>(11, (a, b) => (a * 31 + b) & 0xffff);

  /// Departure gate for a flight; stable for the same flight and date.
  static String gateFor(Flight flight) {
    final seed = _flightSeed(flight);
    return '${'ABCDEF'[seed % 6]}${1 + seed % 14}';
  }

  static String terminalFor(Flight flight) => '${1 + _flightSeed(flight) % 3}';

  /// One flight by number on a date, searched across the whole timetable.
  static Flight? byNumber(String number, DateTime date) {
    final wanted = number.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    for (final entry in _timetable.entries) {
      final codes = entry.key.split('-');
      for (final (code, n, h, m, dur, price, seats) in entry.value) {
        if ('$code$n' == wanted) {
          return build(
            airlineCode: code,
            number: n,
            origin: DemoCatalog.airport(codes[0]),
            destination: DemoCatalog.airport(codes[1]),
            date: date,
            hour: h,
            minute: m,
            durationMinutes: dur,
            price: price,
            seatsLeft: seats,
          );
        }
      }
    }
    return null;
  }

  /// Routes featured on the home screen for [date].
  static List<Flight> popular(DateTime date) {
    Flight first(String from, String to) => search(DemoCatalog.airport(from), DemoCatalog.airport(to), date).first;
    Flight cheapest(String from, String to) {
      final all = search(DemoCatalog.airport(from), DemoCatalog.airport(to), date);
      return all.reduce((a, b) => a.basePrice <= b.basePrice ? a : b);
    }

    return [
      first('HLP', 'BTH'),
      cheapest('CGK', 'SUB'),
      cheapest('DPS', 'SIN'),
      first('SIN', 'KUL'),
      first('IST', 'ESB'),
      cheapest('IST', 'LHR'),
    ];
  }
}
