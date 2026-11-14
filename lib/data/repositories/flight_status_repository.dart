import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../mock/demo_flights.dart';
import '../mock/demo_seed.dart';

/// Live flight status. Replace [DemoFlightStatusRepository] with a real-time
/// provider; the UI only depends on this interface.
abstract interface class FlightStatusRepository {
  /// Status of one flight on [date], or null when the number is unknown.
  Future<FlightStatus?> byNumber(String number, DateTime date);

  Future<List<FlightStatus>> byRoute(Airport origin, Airport destination, DateTime date);

  /// Status of a flight the traveller holds a ticket for.
  FlightStatus forLeg(TripLeg leg);

  Future<List<FlightStatus>> tracked();
  Future<void> track(FlightStatus status);
  Future<void> untrack(FlightStatus status);
}

/// Statuses derived from the demo timetable and the app clock. This is sample
/// data, not a live feed.
class DemoFlightStatusRepository implements FlightStatusRepository {
  DemoFlightStatusRepository({required this.clock, this.latency = const Duration(milliseconds: 700)});

  final Clock clock;
  final Duration latency;
  late final List<FlightStatus> _tracked = DemoSeed.tracked();

  FlightStatus _derive(Flight flight, {String? gate, String? terminal, DateTime? boarding}) {
    final now = clock.now();
    final seed = flight.id.codeUnits.fold<int>(11, (a, b) => (a * 31 + b) & 0xffff);
    final arrivalAtOrigin = flight.departure.add(flight.duration);
    final phase = now.isAfter(arrivalAtOrigin)
        ? FlightPhase.landed
        : now.isAfter(flight.departure)
            ? FlightPhase.inAir
            : now.isAfter(flight.departure.subtract(const Duration(minutes: 40)))
                ? FlightPhase.boarding
                : FlightPhase.scheduled;
    return FlightStatus(
      flight: flight,
      phase: phase,
      terminal: terminal ?? DemoFlights.terminalFor(flight),
      gate: gate ?? DemoFlights.gateFor(flight),
      boarding: boarding ?? flight.departure.subtract(const Duration(minutes: 35)),
      altitudeFeet: phase == FlightPhase.inAir ? 34000 + (seed % 5) * 1000 : null,
      speedKmh: phase == FlightPhase.inAir ? 800 + seed % 90 : null,
      belt: phase == FlightPhase.landed || phase == FlightPhase.inAir ? '${1 + seed % 9}' : null,
    );
  }

  FlightStatus? _known(Flight flight) {
    for (final status in _tracked) {
      if (status.flight.id == flight.id) return status;
    }
    for (final trip in DemoSeed.trips()) {
      for (final leg in trip.legs) {
        if (leg.flight.id == flight.id) return forLeg(leg);
      }
    }
    return null;
  }

  @override
  Future<FlightStatus?> byNumber(String number, DateTime date) async {
    await Future<void>.delayed(latency);
    final flight = DemoFlights.byNumber(number, Fmt.dateOnly(date));
    if (flight == null) return null;
    return _known(flight) ?? _derive(flight);
  }

  @override
  Future<List<FlightStatus>> byRoute(Airport origin, Airport destination, DateTime date) async {
    await Future<void>.delayed(latency);
    return [
      for (final flight in DemoFlights.search(origin, destination, Fmt.dateOnly(date))) _known(flight) ?? _derive(flight),
    ];
  }

  @override
  FlightStatus forLeg(TripLeg leg) => _derive(leg.flight, gate: leg.gate, terminal: leg.terminal, boarding: leg.boarding);

  @override
  Future<List<FlightStatus>> tracked() async => List.unmodifiable(_tracked);

  @override
  Future<void> track(FlightStatus status) async {
    if (_tracked.every((s) => s.flight.id != status.flight.id)) _tracked.add(status);
  }

  @override
  Future<void> untrack(FlightStatus status) async => _tracked.removeWhere((s) => s.flight.id == status.flight.id);
}

/// Alerts feed. Replace [DemoNotificationRepository] with push or polling.
abstract interface class NotificationRepository {
  Future<List<AppNotification>> fetch();
}

class DemoNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> fetch() async => DemoSeed.notifications();
}
