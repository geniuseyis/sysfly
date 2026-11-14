import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/providers.dart';
import '../../shared/models/models.dart';
import '../home/search_controller.dart';

/// Which flight of the trip is being chosen.
enum SearchLeg { outbound, inbound }

/// Flights for one leg of the current search, unfiltered.
final flightResultsProvider = FutureProvider.autoDispose.family<List<Flight>, SearchLeg>((ref, leg) {
  final query = ref.watch(searchControllerProvider);
  final repository = ref.watch(flightRepositoryProvider);
  if (leg == SearchLeg.outbound) {
    return repository.search(
      origin: query.origin,
      destination: query.destination,
      date: query.departDate,
      cabin: query.cabin,
    );
  }
  return repository.search(
    origin: query.destination,
    destination: query.origin,
    date: query.returnDate ?? query.departDate,
    cabin: query.cabin,
  );
});

/// The outbound flight picked on a round trip, held while the return flight
/// is being chosen.
class OutboundSelection extends Notifier<Flight?> {
  @override
  Flight? build() => null;

  void set(Flight? flight) => state = flight;
}

final outboundSelectionProvider = NotifierProvider<OutboundSelection, Flight?>(OutboundSelection.new);
