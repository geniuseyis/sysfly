import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';

enum FlightSort {
  cheapest('Cheapest'),
  earliest('Earliest'),
  fastest('Fastest');

  const FlightSort(this.label);
  final String label;
}

/// Sort order and filters for a list of flights. Empty sets mean "any".
@immutable
class FlightFilter {
  const FlightFilter({this.sort = FlightSort.earliest, this.dayParts = const {}, this.airlines = const {}});

  final FlightSort sort;
  final Set<DayPart> dayParts;

  /// Airline codes.
  final Set<String> airlines;

  bool get isDefault => sort == FlightSort.earliest && dayParts.isEmpty && airlines.isEmpty;

  /// Number of active filters, not counting the sort order.
  int get activeCount => dayParts.length + airlines.length;

  FlightFilter copyWith({FlightSort? sort, Set<DayPart>? dayParts, Set<String>? airlines}) => FlightFilter(
        sort: sort ?? this.sort,
        dayParts: dayParts ?? this.dayParts,
        airlines: airlines ?? this.airlines,
      );

  FlightFilter toggleDayPart(DayPart part) {
    final next = {...dayParts};
    if (!next.remove(part)) next.add(part);
    return copyWith(dayParts: next);
  }

  FlightFilter toggleAirline(String code) {
    final next = {...airlines};
    if (!next.remove(code)) next.add(code);
    return copyWith(airlines: next);
  }

  List<Flight> apply(List<Flight> flights) {
    final result = flights.where((f) {
      if (dayParts.isNotEmpty && !dayParts.contains(f.dayPart)) return false;
      if (airlines.isNotEmpty && !airlines.contains(f.airline.code)) return false;
      return true;
    }).toList();
    switch (sort) {
      case FlightSort.cheapest:
        result.sort((a, b) {
          final byPrice = a.basePrice.compareTo(b.basePrice);
          return byPrice != 0 ? byPrice : a.departure.compareTo(b.departure);
        });
      case FlightSort.earliest:
        result.sort((a, b) => a.departure.compareTo(b.departure));
      case FlightSort.fastest:
        result.sort((a, b) {
          final byDuration = a.duration.compareTo(b.duration);
          return byDuration != 0 ? byDuration : a.departure.compareTo(b.departure);
        });
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is FlightFilter && other.sort == sort && setEquals(other.dayParts, dayParts) && setEquals(other.airlines, airlines);

  @override
  int get hashCode => Object.hash(sort, Object.hashAllUnordered(dayParts), Object.hashAllUnordered(airlines));
}

/// Lowest fare per airline, cheapest first, for the filter sheet.
List<(Airline, int)> airlineFloorPrices(List<Flight> flights) {
  final best = <Airline, int>{};
  for (final f in flights) {
    final current = best[f.airline];
    if (current == null || f.basePrice < current) best[f.airline] = f.basePrice;
  }
  final entries = best.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => a.$2.compareTo(b.$2));
  return entries;
}

class FlightFilterController extends Notifier<FlightFilter> {
  @override
  FlightFilter build() => const FlightFilter();

  void set(FlightFilter filter) => state = filter;
  void reset() => state = const FlightFilter();
}

final flightFilterProvider = NotifierProvider<FlightFilterController, FlightFilter>(FlightFilterController.new);
