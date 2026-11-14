import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/clock.dart';
import '../../data/repositories/providers.dart';
import '../../shared/models/models.dart';

/// The traveller's bookings. A booking confirmed in the checkout flow is
/// added here, which is how it appears on My Flights and Flight Status.
class TripsController extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() => ref.watch(bookingRepositoryProvider).trips();

  Future<void> _refresh() async => state = AsyncData(await ref.read(bookingRepositoryProvider).trips());

  /// Call after the booking repository has created a trip.
  Future<void> refresh() => _refresh();

  Future<Trip> checkIn(Trip trip) async {
    final updated = await ref.read(bookingRepositoryProvider).checkIn(trip);
    await _refresh();
    return updated;
  }

  Future<Trip> cancel(Trip trip) async {
    final updated = await ref.read(bookingRepositoryProvider).cancel(trip);
    await _refresh();
    return updated;
  }

  Future<Trip> addBaggage(Trip trip) async {
    final updated = await ref.read(bookingRepositoryProvider).addBaggage(trip);
    await _refresh();
    return updated;
  }

  Future<Trip> changeSeat(Trip trip, {required int leg, required int traveller, required String seat}) async {
    final updated = await ref.read(bookingRepositoryProvider).changeSeat(trip, leg: leg, traveller: traveller, seat: seat);
    await _refresh();
    return updated;
  }
}

final tripsControllerProvider = AsyncNotifierProvider<TripsController, List<Trip>>(TripsController.new);

final tripsProvider = Provider<List<Trip>>((ref) => ref.watch(tripsControllerProvider).valueOrNull ?? const []);

List<Trip> _sorted(Iterable<Trip> trips, {bool descending = false}) {
  final list = trips.toList()
    ..sort((a, b) => a.firstLeg.flight.departure.compareTo(b.firstLeg.flight.departure));
  return descending ? list.reversed.toList() : list;
}

final upcomingTripsProvider = Provider<List<Trip>>(
  (ref) => _sorted(ref.watch(tripsProvider).where((t) => t.status == TripStatus.upcoming)),
);

final pastTripsProvider = Provider<List<Trip>>(
  (ref) => _sorted(ref.watch(tripsProvider).where((t) => t.status == TripStatus.past), descending: true),
);

final cancelledTripsProvider = Provider<List<Trip>>(
  (ref) => _sorted(ref.watch(tripsProvider).where((t) => t.status == TripStatus.cancelled), descending: true),
);

/// The next trip that has not departed yet.
final nextTripProvider = Provider<Trip?>((ref) {
  final now = ref.watch(clockProvider).now();
  for (final trip in ref.watch(upcomingTripsProvider)) {
    if (trip.firstLeg.flight.departure.isAfter(now)) return trip;
  }
  return null;
});

final tripByReferenceProvider = Provider.family<Trip?, String>((ref, reference) {
  for (final trip in ref.watch(tripsProvider)) {
    if (trip.reference == reference) return trip;
  }
  return null;
});

/// Distinct cities visited on completed trips.
final citiesVisitedProvider = Provider<int>((ref) {
  final cities = <String>{};
  for (final trip in ref.watch(pastTripsProvider)) {
    for (final leg in trip.legs) {
      cities
        ..add(leg.flight.origin.city)
        ..add(leg.flight.destination.city);
    }
  }
  return cities.length;
});
