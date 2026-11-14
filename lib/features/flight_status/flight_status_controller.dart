import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/clock.dart';
import '../../data/repositories/providers.dart';
import '../../shared/models/models.dart';
import '../my_flights/trips_controller.dart';

/// Flights followed without a ticket.
class TrackedFlightsController extends AsyncNotifier<List<FlightStatus>> {
  @override
  Future<List<FlightStatus>> build() => ref.watch(flightStatusRepositoryProvider).tracked();

  Future<void> track(FlightStatus status) async {
    final repository = ref.read(flightStatusRepositoryProvider);
    await repository.track(status);
    state = AsyncData(await repository.tracked());
  }

  Future<void> untrack(FlightStatus status) async {
    final repository = ref.read(flightStatusRepositoryProvider);
    await repository.untrack(status);
    state = AsyncData(await repository.tracked());
  }
}

final trackedFlightsProvider =
    AsyncNotifierProvider<TrackedFlightsController, List<FlightStatus>>(TrackedFlightsController.new);

/// Status of every upcoming flight the traveller holds, soonest first.
final heldFlightStatusesProvider = Provider<List<FlightStatus>>((ref) {
  final repository = ref.watch(flightStatusRepositoryProvider);
  final now = ref.watch(clockProvider).now();
  final statuses = <FlightStatus>[
    for (final trip in ref.watch(upcomingTripsProvider))
      for (final leg in trip.legs)
        if (leg.flight.arrival.isAfter(now.subtract(const Duration(hours: 12)))) repository.forLeg(leg),
  ]..sort((a, b) => a.flight.departure.compareTo(b.flight.departure));
  return statuses;
});

enum StatusSearchMode { flightNumber, route }

@immutable
class StatusLookupState {
  const StatusLookupState({this.loading = false, this.results, this.error});

  final bool loading;

  /// Null before the first search.
  final List<FlightStatus>? results;
  final String? error;
}

/// Runs "Check Status" searches.
class StatusLookupController extends Notifier<StatusLookupState> {
  @override
  StatusLookupState build() => const StatusLookupState();

  Future<List<FlightStatus>?> byNumber(String number, DateTime date) async {
    if (number.trim().isEmpty) {
      state = const StatusLookupState(error: 'Enter a flight number, e.g. GA 159');
      return null;
    }
    state = const StatusLookupState(loading: true);
    try {
      final status = await ref.read(flightStatusRepositoryProvider).byNumber(number, date);
      if (status == null) {
        state = StatusLookupState(error: 'No flight ${number.trim().toUpperCase()} on that day in the demo timetable');
        return null;
      }
      state = StatusLookupState(results: [status]);
      return [status];
    } catch (error) {
      state = StatusLookupState(error: describeError(error));
      return null;
    }
  }

  Future<List<FlightStatus>?> byRoute(Airport origin, Airport destination, DateTime date) async {
    if (origin == destination) {
      state = const StatusLookupState(error: 'Choose two different airports');
      return null;
    }
    state = const StatusLookupState(loading: true);
    try {
      final statuses = await ref.read(flightStatusRepositoryProvider).byRoute(origin, destination, date);
      if (statuses.isEmpty) {
        state = StatusLookupState(error: 'No flights from ${origin.code} to ${destination.code} on that day');
        return null;
      }
      state = StatusLookupState(results: statuses);
      return statuses;
    } catch (error) {
      state = StatusLookupState(error: describeError(error));
      return null;
    }
  }

  void clearError() {
    if (state.error != null) state = StatusLookupState(results: state.results);
  }
}

final statusLookupProvider = NotifierProvider<StatusLookupController, StatusLookupState>(StatusLookupController.new);
