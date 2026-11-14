import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/demo_catalog.dart';
import '../../data/repositories/providers.dart';
import '../../shared/models/models.dart';
import '../authentication/auth_controller.dart';

/// Everything chosen so far in the booking flow. One instance lives for the
/// whole flow, so going back never loses a selection.
@immutable
class BookingDraft {
  const BookingDraft({
    required this.outbound,
    required this.inbound,
    required this.fareType,
    required this.travellers,
    required this.contact,
    required this.seats,
    required this.standardSeatPrice,
    required this.extraIds,
    required this.payment,
    required this.promo,
    required this.termsAccepted,
  });

  final Flight? outbound;
  final Flight? inbound;
  final FareType fareType;

  /// One entry per traveller; null until their details are entered.
  final List<Passenger?> travellers;
  final ContactDetails contact;

  /// Outbound seat per traveller index.
  final Map<int, Seat> seats;

  /// Fee for a standard seat when the fare does not include seat choice.
  final int standardSeatPrice;
  final Set<String> extraIds;
  final PaymentMethod payment;
  final PromoCode? promo;
  final bool termsAccepted;

  static const empty = BookingDraft(
    outbound: null,
    inbound: null,
    fareType: FareType.classic,
    travellers: [null],
    contact: ContactDetails(email: '', phone: ''),
    seats: {},
    standardSeatPrice: 6,
    extraIds: {},
    payment: PaymentMethod(id: 'none', brand: PaymentBrand.visa),
    promo: null,
    termsAccepted: false,
  );

  bool get isStarted => outbound != null;
  int get travellerCount => travellers.length;
  bool get travellersComplete => travellers.every((t) => t != null);
  bool get allSeated => seats.length == travellerCount;

  List<Fare> get fares => outbound == null ? const [] : Fare.forFlight(outbound!);
  Fare? get fare => outbound == null ? null : fares.firstWhere((f) => f.type == fareType);

  /// Price of [type] per traveller across every flight of the trip.
  int farePrice(FareType type) {
    var total = 0;
    for (final flight in [outbound, inbound].whereType<Flight>()) {
      total += Fare.forFlight(flight).firstWhere((f) => f.type == type).price;
    }
    return total;
  }

  int get taxesPerTraveller => [outbound, inbound].whereType<Flight>().fold(0, (sum, f) => sum + f.taxes);

  /// Index of the first traveller without a seat, or null when all are seated.
  int? get nextUnseated {
    for (var i = 0; i < travellerCount; i++) {
      if (!seats.containsKey(i)) return i;
    }
    return null;
  }

  BookingDraft copyWith({
    Flight? outbound,
    Flight? inbound,
    bool clearInbound = false,
    FareType? fareType,
    List<Passenger?>? travellers,
    ContactDetails? contact,
    Map<int, Seat>? seats,
    int? standardSeatPrice,
    Set<String>? extraIds,
    PaymentMethod? payment,
    PromoCode? promo,
    bool clearPromo = false,
    bool? termsAccepted,
  }) =>
      BookingDraft(
        outbound: outbound ?? this.outbound,
        inbound: clearInbound ? null : (inbound ?? this.inbound),
        fareType: fareType ?? this.fareType,
        travellers: travellers ?? this.travellers,
        contact: contact ?? this.contact,
        seats: seats ?? this.seats,
        standardSeatPrice: standardSeatPrice ?? this.standardSeatPrice,
        extraIds: extraIds ?? this.extraIds,
        payment: payment ?? this.payment,
        promo: clearPromo ? null : (promo ?? this.promo),
        termsAccepted: termsAccepted ?? this.termsAccepted,
      );
}

/// Works out what a draft costs. Every screen reads prices from here.
PriceBreakdown priceOf(BookingDraft draft, List<TripExtra> catalog) {
  final fare = draft.fare;
  if (fare == null) return PriceBreakdown.empty;
  final n = draft.travellerCount;
  final fareTotal = draft.farePrice(draft.fareType) * n;
  final taxes = draft.taxesPerTraveller * n;

  var seatFees = 0;
  for (final seat in draft.seats.values) {
    seatFees += seat.surcharge > 0 ? seat.surcharge : (fare.includesStandardSeat ? 0 : draft.standardSeatPrice);
  }

  final lines = <PriceLine>[
    PriceLine(n == 1 ? '${fare.name} fare' : '${fare.name} fare × $n', fareTotal),
    PriceLine('Taxes & airport fees', taxes),
    if (draft.seats.isEmpty)
      const PriceLine('Seats', 0, note: 'At check-in')
    else if (seatFees == 0)
      const PriceLine('Seats', 0, note: 'Included')
    else
      PriceLine('Seats', seatFees),
  ];
  var total = fareTotal + taxes + seatFees;

  for (final extra in catalog) {
    if (!draft.extraIds.contains(extra.id)) continue;
    lines.add(PriceLine(n == 1 ? extra.title : '${extra.title} × $n', extra.price * n));
    total += extra.price * n;
  }

  final promo = draft.promo;
  if (promo != null) {
    final discount = (fareTotal * promo.percentOff / 100).round();
    lines.add(PriceLine('Promo ${promo.code}', -discount));
    total -= discount;
  }

  return PriceBreakdown(lines: lines, total: total, travellers: n, taxes: taxes);
}

class BookingController extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => BookingDraft.empty;

  /// Begins a new booking for the chosen flights.
  void start({required Flight outbound, Flight? inbound, required int passengers}) {
    final user = ref.read(currentUserProvider);
    state = BookingDraft(
      outbound: outbound,
      inbound: inbound,
      fareType: FareType.classic,
      travellers: [user.traveller, ...List<Passenger?>.filled(passengers - 1, null)],
      contact: ContactDetails(email: user.email, phone: user.phone),
      seats: const {},
      standardSeatPrice: 6,
      extraIds: const {},
      payment: DemoCatalog.cards.firstWhere((c) => c.isDefault, orElse: () => DemoCatalog.cards.first),
      promo: null,
      termsAccepted: false,
    );
  }

  void selectFare(FareType type) => state = state.copyWith(fareType: type);

  void setTraveller(int index, Passenger passenger) {
    final next = [...state.travellers];
    next[index] = passenger;
    state = state.copyWith(travellers: next);
  }

  void setContact(ContactDetails contact) => state = state.copyWith(contact: contact);

  /// Gives [seat] to [traveller], releasing their previous seat. A seat held
  /// by another traveller in this booking is taken over.
  void selectSeat(int traveller, Seat seat, {required int standardPrice}) {
    final next = {...state.seats}..removeWhere((_, s) => s.id == seat.id);
    next[traveller] = seat;
    state = state.copyWith(seats: next, standardSeatPrice: standardPrice);
  }

  void clearSeat(int traveller) => state = state.copyWith(seats: {...state.seats}..remove(traveller));

  void clearSeats() => state = state.copyWith(seats: const {});

  void toggleExtra(String id) {
    final next = {...state.extraIds};
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(extraIds: next);
  }

  void setPayment(PaymentMethod method) => state = state.copyWith(payment: method);

  /// Returns false when the code is not recognised.
  bool applyPromo(String code) {
    final promo = ref.read(bookingRepositoryProvider).promo(code);
    if (promo == null) return false;
    state = state.copyWith(promo: promo);
    return true;
  }

  void removePromo() => state = state.copyWith(clearPromo: true);

  void setTerms(bool accepted) => state = state.copyWith(termsAccepted: accepted);

  void reset() => state = BookingDraft.empty;

  /// Pays (simulated) and creates the trip. Throws on failure.
  Future<Trip> confirm() async {
    final draft = state;
    final repository = ref.read(bookingRepositoryProvider);
    final price = priceOf(draft, repository.extras());
    return repository.book(
      BookingRequest(
        outbound: draft.outbound!,
        inbound: draft.inbound,
        fare: draft.fare!,
        travellers: draft.travellers.whereType<Passenger>().toList(),
        contact: draft.contact,
        seats: [for (var i = 0; i < draft.travellerCount; i++) draft.seats[i]?.id],
        extras: repository.extras().where((e) => draft.extraIds.contains(e.id)).toList(),
        payment: draft.payment,
        price: price,
      ),
    );
  }
}

final bookingControllerProvider = NotifierProvider<BookingController, BookingDraft>(BookingController.new);

final tripExtrasProvider = Provider<List<TripExtra>>((ref) => ref.watch(bookingRepositoryProvider).extras());

/// The live price of the booking in progress.
final bookingPriceProvider = Provider<PriceBreakdown>(
  (ref) => priceOf(ref.watch(bookingControllerProvider), ref.watch(tripExtrasProvider)),
);

final seatMapProvider = FutureProvider.autoDispose.family<SeatMap, Flight>(
  (ref, flight) => ref.watch(flightRepositoryProvider).seatMap(flight),
);

/// Saved cards, refreshed after one is added or removed.
class PaymentMethodsController extends AsyncNotifier<List<PaymentMethod>> {
  @override
  Future<List<PaymentMethod>> build() => ref.watch(bookingRepositoryProvider).paymentMethods();

  Future<PaymentMethod> addCard({required String number, required String expiry}) async {
    final repository = ref.read(bookingRepositoryProvider);
    final method = await repository.addCard(number: number, expiry: expiry);
    state = AsyncData(await repository.paymentMethods());
    return method;
  }

  Future<void> remove(PaymentMethod method) async {
    final repository = ref.read(bookingRepositoryProvider);
    await repository.removeCard(method);
    state = AsyncData(await repository.paymentMethods());
  }
}

final paymentMethodsProvider =
    AsyncNotifierProvider<PaymentMethodsController, List<PaymentMethod>>(PaymentMethodsController.new);
