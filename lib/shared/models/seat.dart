import 'package:flutter/foundation.dart';

enum SeatKind { standard, extraLegroom }

enum SeatAvailability { available, occupied, unavailable }

@immutable
class Seat {
  const Seat({
    required this.row,
    required this.letter,
    required this.kind,
    required this.availability,
    this.surcharge = 0,
  });

  final int row;
  final String letter;
  final SeatKind kind;
  final SeatAvailability availability;

  /// Fee charged for this seat on every fare, e.g. extra legroom.
  final int surcharge;

  String get id => '$row$letter';

  bool get isSelectable => availability == SeatAvailability.available;

  Seat copyWith({SeatAvailability? availability}) =>
      Seat(row: row, letter: letter, kind: kind, availability: availability ?? this.availability, surcharge: surcharge);
}

@immutable
class SeatMap {
  const SeatMap({
    required this.aircraft,
    required this.rows,
    required this.letters,
    required this.seats,
    required this.exitRows,
    required this.extraLegroomPrice,
    required this.standardPrice,
  });

  final String aircraft;
  final int rows;

  /// Seat letters left to right; the aisle sits in the middle.
  final List<String> letters;
  final Map<String, Seat> seats;

  /// Rows that have an emergency exit directly in front of them.
  final Set<int> exitRows;
  final int extraLegroomPrice;

  /// Charged for a standard seat when the fare does not include one.
  final int standardPrice;

  Seat? seat(int row, String letter) => seats['$row$letter'];

  Iterable<Seat> inRows(int from, int to) => seats.values.where((s) => s.row >= from && s.row <= to);

  int freeIn(int from, int to) => inRows(from, to).where((s) => s.isSelectable).length;

  int totalIn(int from, int to) => inRows(from, to).length;
}
