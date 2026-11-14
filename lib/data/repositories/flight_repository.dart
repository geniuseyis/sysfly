import '../../shared/models/models.dart';
import '../datasources/airport_catalog.dart';
import '../mock/demo_flights.dart';
import '../mock/demo_seed.dart';

/// Timetable, fares and seat maps. Replace [DemoFlightRepository] to connect
/// a flight booking API.
abstract interface class FlightRepository {
  Future<List<Airport>> airports();

  Future<List<Flight>> search({
    required Airport origin,
    required Airport destination,
    required DateTime date,
    CabinClass cabin = CabinClass.economy,
  });

  Future<List<Flight>> popularRoutes(DateTime date);

  List<Fare> fares(Flight flight);

  Future<SeatMap> seatMap(Flight flight);

  /// Marks [seats] as taken on [flight] once a booking is confirmed.
  Future<void> holdSeats(Flight flight, Iterable<String> seats);
}

class DemoFlightRepository implements FlightRepository {
  DemoFlightRepository({this.latency = const Duration(milliseconds: 450)});

  final Duration latency;
  final Map<String, Set<String>> _held = {};

  @override
  Future<List<Airport>> airports() => AirportCatalog.load();

  @override
  Future<List<Flight>> search({
    required Airport origin,
    required Airport destination,
    required DateTime date,
    CabinClass cabin = CabinClass.economy,
  }) async {
    await Future<void>.delayed(latency);
    return DemoFlights.search(origin, destination, date, cabin: cabin);
  }

  @override
  Future<List<Flight>> popularRoutes(DateTime date) async => DemoFlights.popular(date);

  @override
  List<Fare> fares(Flight flight) => Fare.forFlight(flight);

  @override
  Future<SeatMap> seatMap(Flight flight) async {
    await Future<void>.delayed(Duration(milliseconds: latency.inMilliseconds ~/ 2));
    return DemoSeed.seatMap(flight, reserved: _held[flight.id] ?? const {});
  }

  @override
  Future<void> holdSeats(Flight flight, Iterable<String> seats) async {
    _held.putIfAbsent(flight.id, () => {}).addAll(seats);
  }
}
