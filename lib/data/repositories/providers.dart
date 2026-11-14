import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/clock.dart';
import 'auth_repository.dart';
import 'booking_repository.dart';
import 'flight_repository.dart';
import 'flight_status_repository.dart';

export 'auth_repository.dart';
export 'booking_repository.dart';
export 'flight_repository.dart';
export 'flight_status_repository.dart';

// Every data dependency of the app is resolved here. Override these
// providers to swap the demo implementations for real services.

final authRepositoryProvider = Provider<AuthRepository>((ref) => DemoAuthRepository());

final flightRepositoryProvider = Provider<FlightRepository>((ref) => DemoFlightRepository());

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => DemoBookingRepository(flights: ref.watch(flightRepositoryProvider), clock: ref.watch(clockProvider)),
);

final flightStatusRepositoryProvider = Provider<FlightStatusRepository>(
  (ref) => DemoFlightStatusRepository(clock: ref.watch(clockProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => DemoNotificationRepository());
