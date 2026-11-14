import 'package:flutter/foundation.dart';

import 'checkout.dart';
import 'flight.dart';
import 'passenger.dart';

enum TripStatus { upcoming, past, cancelled }

@immutable
class TripLeg {
  const TripLeg({
    required this.flight,
    required this.seats,
    required this.gate,
    required this.terminal,
    required this.boarding,
  });

  final Flight flight;

  /// Seat id for each traveller, in traveller order. An entry is null while
  /// that seat is still to be assigned at check-in.
  final List<String?> seats;
  final String gate;
  final String terminal;

  /// Local boarding time at the origin.
  final DateTime boarding;

  /// Seat of the lead traveller.
  String? get seat => seats.isEmpty ? null : seats.first;

  String? seatOf(int traveller) => traveller < seats.length ? seats[traveller] : null;

  TripLeg copyWith({List<String?>? seats}) =>
      TripLeg(flight: flight, seats: seats ?? this.seats, gate: gate, terminal: terminal, boarding: boarding);
}

/// A confirmed booking with one or more flights.
@immutable
class Trip {
  const Trip({
    required this.reference,
    required this.legs,
    required this.passengers,
    required this.fareName,
    required this.cabin,
    required this.totalPaid,
    required this.status,
    required this.extras,
    required this.bookedAt,
    this.checkedIn = false,
    this.paymentLabel = '',
    this.contactEmail = '',
  });

  /// Booking reference, e.g. "AK-VP5HBW".
  final String reference;
  final List<TripLeg> legs;
  final List<Passenger> passengers;
  final String fareName;
  final CabinClass cabin;
  final int totalPaid;
  final TripStatus status;
  final List<TripExtra> extras;
  final DateTime bookedAt;
  final bool checkedIn;
  final String paymentLabel;
  final String contactEmail;

  TripLeg get firstLeg => legs.first;
  TripLeg get lastLeg => legs.last;

  /// Lead traveller.
  Passenger get passenger => passengers.first;

  String get travellerLabel => passengers.length == 1 ? '1 traveller' : '${passengers.length} travellers';

  /// Online check-in opens 48 hours before departure and closes 60 minutes before.
  DateTime get checkInOpens => firstLeg.flight.departure.subtract(const Duration(hours: 48));
  DateTime get checkInCloses => firstLeg.flight.departure.subtract(const Duration(minutes: 60));

  bool isCheckInOpen(DateTime now) =>
      status == TripStatus.upcoming && !checkedIn && !now.isBefore(checkInOpens) && now.isBefore(checkInCloses);

  Trip copyWith({TripStatus? status, bool? checkedIn, List<TripLeg>? legs, List<TripExtra>? extras, int? totalPaid}) => Trip(
        reference: reference,
        legs: legs ?? this.legs,
        passengers: passengers,
        fareName: fareName,
        cabin: cabin,
        totalPaid: totalPaid ?? this.totalPaid,
        status: status ?? this.status,
        extras: extras ?? this.extras,
        bookedAt: bookedAt,
        checkedIn: checkedIn ?? this.checkedIn,
        paymentLabel: paymentLabel,
        contactEmail: contactEmail,
      );
}
