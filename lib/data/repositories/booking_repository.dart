import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/clock.dart';
import '../../shared/models/models.dart';
import '../mock/demo_catalog.dart';
import '../mock/demo_flights.dart';
import '../mock/demo_seed.dart';
import 'flight_repository.dart';

/// Everything needed to turn a finished booking flow into a [Trip].
@immutable
class BookingRequest {
  const BookingRequest({
    required this.outbound,
    required this.inbound,
    required this.fare,
    required this.travellers,
    required this.contact,
    required this.seats,
    required this.extras,
    required this.payment,
    required this.price,
  });

  final Flight outbound;
  final Flight? inbound;
  final Fare fare;
  final List<Passenger> travellers;
  final ContactDetails contact;

  /// Seat for each traveller on the outbound flight; null entries are
  /// assigned at check-in.
  final List<String?> seats;
  final List<TripExtra> extras;
  final PaymentMethod payment;
  final PriceBreakdown price;
}

/// Bookings and payments. Replace [DemoBookingRepository] to connect real
/// reservation and payment services.
abstract interface class BookingRepository {
  Future<List<Trip>> trips();
  Future<Trip> book(BookingRequest request);
  Future<Trip> checkIn(Trip trip);
  Future<Trip> cancel(Trip trip);
  Future<Trip> addBaggage(Trip trip);
  Future<Trip> changeSeat(Trip trip, {required int leg, required int traveller, required String seat});

  List<TripExtra> extras();
  PromoCode? promo(String code);

  Future<List<PaymentMethod>> paymentMethods();

  /// Saves a card. Only the brand, last four digits and expiry are kept.
  Future<PaymentMethod> addCard({required String number, required String expiry});
  Future<void> removeCard(PaymentMethod method);
}

/// In-memory bookings with a simulated payment. No money moves and no real
/// reservation is made.
class DemoBookingRepository implements BookingRepository {
  DemoBookingRepository({
    required this.flights,
    required this.clock,
    this.latency = const Duration(milliseconds: 2400),
    Random? random,
  }) : _random = random ?? Random();

  final FlightRepository flights;
  final Clock clock;
  final Duration latency;
  final Random _random;

  late final List<Trip> _trips = DemoSeed.trips();
  final List<PaymentMethod> _cards = [...DemoCatalog.cards];

  /// Card numbers ending in this are declined, so the failure path can be
  /// exercised (for example 4000 0000 0000 0002).
  static const declinedSuffix = '0002';

  @override
  Future<List<Trip>> trips() async => List.unmodifiable(_trips);

  String _reference(String airline) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(6, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
    return '$airline-$code';
  }

  TripLeg _leg(Flight flight, List<String?> seats) {
    return TripLeg(
      flight: flight,
      seats: seats,
      gate: DemoFlights.gateFor(flight),
      terminal: DemoFlights.terminalFor(flight),
      boarding: flight.departure.subtract(const Duration(minutes: 35)),
    );
  }

  @override
  Future<Trip> book(BookingRequest request) async {
    await Future<void>.delayed(latency);
    if (request.payment.last4 == declinedSuffix) {
      throw const PaymentException('The demo card ending 0002 is always declined. Choose another payment method.');
    }
    final trip = Trip(
      reference: _reference(request.outbound.airline.code),
      legs: [
        _leg(request.outbound, request.seats),
        if (request.inbound != null) _leg(request.inbound!, List<String?>.filled(request.travellers.length, null)),
      ],
      passengers: request.travellers,
      fareName: request.fare.name,
      cabin: request.outbound.cabin,
      totalPaid: request.price.total,
      status: TripStatus.upcoming,
      extras: request.extras,
      bookedAt: clock.now(),
      paymentLabel: request.payment.title,
      contactEmail: request.contact.email,
    );
    await flights.holdSeats(request.outbound, request.seats.whereType<String>());
    _trips.insert(0, trip);
    return trip;
  }

  Trip _replace(Trip updated) {
    final index = _trips.indexWhere((t) => t.reference == updated.reference);
    if (index < 0) throw const NotFoundException('This booking could not be found');
    _trips[index] = updated;
    return updated;
  }

  @override
  Future<Trip> checkIn(Trip trip) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!trip.isCheckInOpen(clock.now())) {
      throw const AppException('Online check-in is not open for this flight');
    }
    // Travellers without a seat get the first free ones.
    final legs = <TripLeg>[];
    for (final leg in trip.legs) {
      if (!leg.seats.contains(null)) {
        legs.add(leg);
        continue;
      }
      final map = await flights.seatMap(leg.flight);
      final free = map.seats.values
          .where((s) => s.isSelectable && s.kind == SeatKind.standard && !leg.seats.contains(s.id))
          .map((s) => s.id)
          .toList();
      var next = 0;
      final seats = [for (final seat in leg.seats) seat ?? (next < free.length ? free[next++] : null)];
      await flights.holdSeats(leg.flight, seats.whereType<String>());
      legs.add(leg.copyWith(seats: seats));
    }
    return _replace(trip.copyWith(checkedIn: true, legs: legs));
  }

  @override
  Future<Trip> cancel(Trip trip) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return _replace(trip.copyWith(status: TripStatus.cancelled));
  }

  @override
  Future<Trip> addBaggage(Trip trip) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final bag = DemoCatalog.extras.first;
    if (trip.extras.contains(bag)) throw const AppException('Extra baggage is already on this booking');
    return _replace(trip.copyWith(
      extras: [...trip.extras, bag],
      totalPaid: trip.totalPaid + bag.price * trip.passengers.length,
    ));
  }

  @override
  Future<Trip> changeSeat(Trip trip, {required int leg, required int traveller, required String seat}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final legs = [...trip.legs];
    final seats = [...legs[leg].seats];
    while (seats.length <= traveller) {
      seats.add(null);
    }
    seats[traveller] = seat;
    legs[leg] = legs[leg].copyWith(seats: seats);
    await flights.holdSeats(legs[leg].flight, [seat]);
    return _replace(trip.copyWith(legs: legs));
  }

  @override
  List<TripExtra> extras() => DemoCatalog.extras;

  @override
  PromoCode? promo(String code) {
    final wanted = code.trim().toUpperCase();
    for (final promo in DemoCatalog.promoCodes) {
      if (promo.code == wanted) return promo;
    }
    return null;
  }

  @override
  Future<List<PaymentMethod>> paymentMethods() async => List.unmodifiable(_cards);

  static PaymentBrand brandOf(String digits) {
    if (digits.startsWith('4')) return PaymentBrand.visa;
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) return PaymentBrand.mastercard;
    if (RegExp(r'^3[47]').hasMatch(digits)) return PaymentBrand.amex;
    if (digits.startsWith('35')) return PaymentBrand.jcb;
    return PaymentBrand.visa;
  }

  @override
  Future<PaymentMethod> addCard({required String number, required String expiry}) async {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.substring(digits.length - 4);
    final method = PaymentMethod(
      id: 'card-$last4-${_cards.length}',
      brand: brandOf(digits),
      last4: last4,
      expiry: expiry,
    );
    _cards.add(method);
    return method;
  }

  @override
  Future<void> removeCard(PaymentMethod method) async => _cards.remove(method);
}
