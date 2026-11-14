import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of "now" for everything that depends on dates.
abstract interface class Clock {
  /// The moment trips, countdowns and statuses are measured against.
  DateTime now();

  /// Hour of the day on the device, used only for the greeting.
  int deviceHour();
}

/// The demo data set is anchored to Thursday 3 September 2026, 7:30 PM, which
/// is the moment the reference designs were captured at ("Departs in 10h 35m"
/// for the 6:05 AM flight on 4 September). Swap in [SystemClock] together
/// with a live flight data source.
class DemoClock implements Clock {
  const DemoClock();

  static final DateTime anchor = DateTime(2026, 9, 3, 19, 30);

  @override
  DateTime now() => anchor;

  @override
  int deviceHour() => DateTime.now().hour;
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  int deviceHour() => DateTime.now().hour;
}

final clockProvider = Provider<Clock>((ref) => const DemoClock());
