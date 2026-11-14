import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock/demo_catalog.dart';
import '../../data/repositories/providers.dart';
import '../../shared/models/models.dart';

/// What the traveller is searching for. Shared by the home form, the results
/// screen and the booking flow.
@immutable
class SearchQuery {
  const SearchQuery({
    required this.tripType,
    required this.origin,
    required this.destination,
    required this.departDate,
    required this.returnDate,
    required this.passengers,
    required this.cabin,
  });

  final TripType tripType;
  final Airport origin;
  final Airport destination;
  final DateTime departDate;
  final DateTime? returnDate;
  final int passengers;
  final CabinClass cabin;

  static const int maxPassengers = 4;

  bool get isRoundTrip => tripType == TripType.roundTrip;

  String get passengerLabel => passengers == 1 ? '1 Adult' : '$passengers Adults';

  /// Null when the form can be searched, otherwise what is missing.
  String? get problem {
    if (origin == destination) return 'Choose two different airports';
    if (isRoundTrip && returnDate == null) return 'Add a return date';
    return null;
  }

  SearchQuery copyWith({
    TripType? tripType,
    Airport? origin,
    Airport? destination,
    DateTime? departDate,
    DateTime? returnDate,
    bool clearReturn = false,
    int? passengers,
    CabinClass? cabin,
  }) =>
      SearchQuery(
        tripType: tripType ?? this.tripType,
        origin: origin ?? this.origin,
        destination: destination ?? this.destination,
        departDate: departDate ?? this.departDate,
        returnDate: clearReturn ? null : (returnDate ?? this.returnDate),
        passengers: passengers ?? this.passengers,
        cabin: cabin ?? this.cabin,
      );
}

class FlightSearchController extends Notifier<SearchQuery> {
  @override
  SearchQuery build() {
    final today = Fmt.dateOnly(ref.watch(clockProvider).now());
    return SearchQuery(
      tripType: TripType.oneWay,
      origin: DemoCatalog.airport('DPS'),
      destination: DemoCatalog.airport('CGK'),
      departDate: today.add(const Duration(days: 1)),
      returnDate: null,
      passengers: 1,
      cabin: CabinClass.economy,
    );
  }

  void setTripType(TripType type) {
    if (type == TripType.multiCity) return;
    state = state.copyWith(tripType: type, clearReturn: type == TripType.oneWay);
  }

  void setOrigin(Airport airport) {
    // Picking the current destination swaps the two instead of clashing.
    state = airport == state.destination
        ? state.copyWith(origin: airport, destination: state.origin)
        : state.copyWith(origin: airport);
  }

  void setDestination(Airport airport) {
    state = airport == state.origin
        ? state.copyWith(destination: airport, origin: state.destination)
        : state.copyWith(destination: airport);
  }

  void swap() => state = state.copyWith(origin: state.destination, destination: state.origin);

  void setDepartDate(DateTime date) {
    final day = Fmt.dateOnly(date);
    final keepReturn = state.returnDate != null && !state.returnDate!.isBefore(day);
    state = state.copyWith(departDate: day, clearReturn: !keepReturn);
  }

  /// Setting a return date turns the search into a round trip.
  void setReturnDate(DateTime date) =>
      state = state.copyWith(returnDate: Fmt.dateOnly(date), tripType: TripType.roundTrip);

  void setPassengers(int count) => state = state.copyWith(passengers: count.clamp(1, SearchQuery.maxPassengers));

  void setCabin(CabinClass cabin) => state = state.copyWith(cabin: cabin);

  /// Jump straight to a route, e.g. from a popular route or a price alert.
  void setRoute({required Airport origin, required Airport destination, DateTime? date}) {
    state = state.copyWith(
      origin: origin,
      destination: destination,
      departDate: date == null ? null : Fmt.dateOnly(date),
      tripType: TripType.oneWay,
      clearReturn: true,
    );
  }
}

final searchControllerProvider = NotifierProvider<FlightSearchController, SearchQuery>(FlightSearchController.new);

final airportsProvider = FutureProvider<List<Airport>>((ref) => ref.watch(flightRepositoryProvider).airports());

/// Routes featured on the home screen, priced for tomorrow.
final popularRoutesProvider = FutureProvider<List<Flight>>((ref) {
  final tomorrow = Fmt.dateOnly(ref.watch(clockProvider).now()).add(const Duration(days: 1));
  return ref.watch(flightRepositoryProvider).popularRoutes(tomorrow);
});
