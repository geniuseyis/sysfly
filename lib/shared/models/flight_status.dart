import 'package:flutter/foundation.dart';

import 'flight.dart';

enum FlightPhase {
  scheduled('On time'),
  boarding('Boarding'),
  inAir('In the air'),
  landed('Landed'),
  delayed('Delayed'),
  cancelled('Cancelled');

  const FlightPhase(this.label);
  final String label;
}

/// Live status of one flight. Supplied by a [FlightStatusRepository].
@immutable
class FlightStatus {
  const FlightStatus({
    required this.flight,
    required this.phase,
    required this.terminal,
    required this.gate,
    required this.boarding,
    this.altitudeFeet,
    this.speedKmh,
    this.belt,
    this.delayMinutes = 0,
  });

  final Flight flight;
  final FlightPhase phase;
  final String terminal;
  final String gate;
  final DateTime boarding;
  final int? altitudeFeet;
  final int? speedKmh;
  final String? belt;
  final int delayMinutes;

  /// Fraction of the route flown, 0 to 1, at [now] (origin local time).
  double progressAt(DateTime now) {
    if (phase == FlightPhase.landed) return 1;
    if (phase != FlightPhase.inAir) return 0;
    final flown = now.difference(flight.departure).inSeconds;
    final total = flight.duration.inSeconds;
    if (total <= 0) return 0;
    return (flown / total).clamp(0.05, 0.95);
  }
}

enum NotificationKind { gate, boarding, landed, priceDrop, checkIn }

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.tag,
    required this.time,
    this.read = false,
    this.flightNumber,
    this.tripReference,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;

  /// Short context chip, e.g. "GA 159 · DPS–CGK".
  final String tag;
  final DateTime time;
  final bool read;
  final String? flightNumber;
  final String? tripReference;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        kind: kind,
        title: title,
        body: body,
        tag: tag,
        time: time,
        read: read ?? this.read,
        flightNumber: flightNumber,
        tripReference: tripReference,
      );
}
