import 'package:flutter/foundation.dart';

import 'airport.dart';

enum CabinClass {
  economy('Economy'),
  premiumEconomy('Premium Economy'),
  business('Business');

  const CabinClass(this.label);
  final String label;

  /// Price multiplier applied to the economy base fare.
  double get multiplier => switch (this) {
        CabinClass.economy => 1.0,
        CabinClass.premiumEconomy => 1.6,
        CabinClass.business => 2.8,
      };
}

enum TripType {
  oneWay('One way'),
  roundTrip('Round trip'),
  multiCity('Multi-city');

  const TripType(this.label);
  final String label;
}

/// Part of the day a flight departs in, used by the filter sheet.
enum DayPart {
  morning('Morning', '5 AM - 12 PM', 5, 12),
  afternoon('Afternoon', '12 - 5 PM', 12, 17),
  evening('Evening', '5 - 9 PM', 17, 21),
  night('Night', '9 PM - 5 AM', 21, 29);

  const DayPart(this.label, this.range, this.startHour, this.endHour);
  final String label;
  final String range;
  final int startHour;
  final int endHour;

  static DayPart of(DateTime time) {
    final h = time.hour;
    if (h >= 5 && h < 12) return DayPart.morning;
    if (h >= 12 && h < 17) return DayPart.afternoon;
    if (h >= 17 && h < 21) return DayPart.evening;
    return DayPart.night;
  }
}

@immutable
class Flight {
  const Flight({
    required this.id,
    required this.airline,
    required this.number,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.basePrice,
    required this.seatsLeft,
    required this.aircraft,
    this.cabin = CabinClass.economy,
  });

  final String id;
  final Airline airline;

  /// Flight number including designator, e.g. "AK 103".
  final String number;
  final Airport origin;
  final Airport destination;

  /// Local time at the origin.
  final DateTime departure;

  /// Local time at the destination.
  final DateTime arrival;
  final Duration duration;

  /// Lowest fare per traveller in whole US dollars, before taxes.
  final int basePrice;
  final int seatsLeft;
  final String aircraft;
  final CabinClass cabin;

  DayPart get dayPart => DayPart.of(departure);

  /// Taxes and airport fees per traveller.
  int get taxes => (12 + basePrice * 0.16).round();

  @override
  bool operator ==(Object other) => other is Flight && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
