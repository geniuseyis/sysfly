import '../../core/utils/clock.dart';
import '../../shared/models/models.dart';
import 'demo_catalog.dart';
import 'demo_flights.dart';

/// Seeded account data for the demo: seat map, trips, statuses, alerts.
abstract final class DemoSeed {
  // T = taken, A = available. Rows 1 to 16 mirror the reference cabin, which
  // has 41 of 64 seats free.
  static const _front = [
    'TTAA', 'TTAA', 'AATA', 'TAAT', 'ATAA', 'TATA', 'AAAT', 'ATAA', //
    'TATA', 'AAAT', 'ATAA', 'TATA', 'AAAT', 'ATAA', 'TAAT', 'AATA',
  ];
  static const _rear = [
    'AATA', 'TAAA', 'ATAT', 'AAAA', 'TTAA', 'AATA', 'ATAA', 'AAAT', //
    'TAAA', 'AATT', 'AAAA', 'ATAA', 'TAAT', 'AAAA', 'ATTA', 'AAAA',
  ];
  static const _letters = ['A', 'B', 'C', 'D'];
  static const _extraRows = {1, 8, 9, 24};

  /// Seat map for [flight]. [reserved] holds seats already booked in this
  /// session so they show as taken.
  static SeatMap seatMap(Flight flight, {Set<String> reserved = const {}}) {
    final seats = <String, Seat>{};
    final pattern = [..._front, ..._rear];
    for (var row = 1; row <= pattern.length; row++) {
      for (var i = 0; i < _letters.length; i++) {
        final id = '$row${_letters[i]}';
        final taken = pattern[row - 1][i] == 'T' || reserved.contains(id);
        seats[id] = Seat(
          row: row,
          letter: _letters[i],
          kind: _extraRows.contains(row) ? SeatKind.extraLegroom : SeatKind.standard,
          availability: taken ? SeatAvailability.occupied : SeatAvailability.available,
          surcharge: _extraRows.contains(row) ? 18 : 0,
        );
      }
    }
    return SeatMap(
      aircraft: flight.aircraft,
      rows: pattern.length,
      letters: _letters,
      seats: seats,
      exitRows: const {1, 8, 9, 24},
      extraLegroomPrice: 18,
      standardPrice: 6,
    );
  }

  static Flight _flight(String number, DateTime date) => DemoFlights.byNumber(number, date)!;

  static TripLeg _leg(String number, DateTime date, {String? seat, required String gate, required String terminal, int boardBefore = 35}) {
    final flight = _flight(number, date);
    return TripLeg(
      flight: flight,
      seats: [seat],
      gate: gate,
      terminal: terminal,
      boarding: flight.departure.subtract(Duration(minutes: boardBefore)),
    );
  }

  static List<Trip> trips() {
    final traveller = DemoCatalog.traveller;
    final booked = DemoClock.anchor.subtract(const Duration(days: 21));
    return [
      Trip(
        reference: 'GA-4F7CMH',
        legs: [_leg('GA 159', DateTime(2026, 9, 4), seat: '12A', gate: 'A9', terminal: '1')],
        passengers: [traveller],
        fareName: 'Classic',
        cabin: CabinClass.economy,
        totalPaid: 179,
        status: TripStatus.upcoming,
        extras: const [],
        bookedAt: booked,
        paymentLabel: 'Visa •••• 4242',
        contactEmail: DemoCatalog.user.email,
      ),
      Trip(
        reference: 'GA-9Z3JRQ',
        legs: [
          _leg('GA 128', DateTime(2026, 9, 12), seat: '7C', gate: 'F9', terminal: '3'),
          _leg('GA 103', DateTime(2026, 9, 14), seat: '7C', gate: 'B9', terminal: '1'),
        ],
        passengers: [traveller],
        fareName: 'Classic',
        cabin: CabinClass.economy,
        totalPaid: 248,
        status: TripStatus.upcoming,
        extras: const [],
        bookedAt: booked,
        paymentLabel: 'Visa •••• 4242',
        contactEmail: DemoCatalog.user.email,
      ),
      Trip(
        reference: 'SQ-K2M8TD',
        legs: [
          _leg('SQ 146', DateTime(2026, 9, 18), seat: '21D', gate: 'C7', terminal: 'I', boardBefore: 45),
          _leg('SQ 147', DateTime(2026, 9, 22), seat: '21D', gate: 'D8', terminal: '3', boardBefore: 45),
        ],
        passengers: [traveller],
        fareName: 'Flex',
        cabin: CabinClass.economy,
        totalPaid: 561,
        status: TripStatus.upcoming,
        extras: [DemoCatalog.extras[2]],
        bookedAt: booked,
        paymentLabel: 'Mastercard •••• 8812',
        contactEmail: DemoCatalog.user.email,
      ),
      Trip(
        reference: 'GA-7QW2LP',
        legs: [_leg('GA 402', DateTime(2026, 8, 21), seat: '9B', gate: 'E4', terminal: '3')],
        passengers: [traveller],
        fareName: 'Classic',
        cabin: CabinClass.economy,
        totalPaid: 174,
        status: TripStatus.past,
        extras: const [],
        bookedAt: DateTime(2026, 8, 2),
        checkedIn: true,
        paymentLabel: 'Visa •••• 4242',
        contactEmail: DemoCatalog.user.email,
      ),
      Trip(
        reference: 'TR-5HN4XA',
        legs: [_leg('TR 281', DateTime(2026, 7, 2), seat: '18A', gate: 'B2', terminal: 'I')],
        passengers: [traveller],
        fareName: 'Lite',
        cabin: CabinClass.economy,
        totalPaid: 104,
        status: TripStatus.past,
        extras: const [],
        bookedAt: DateTime(2026, 6, 11),
        checkedIn: true,
        paymentLabel: 'Visa •••• 4242',
        contactEmail: DemoCatalog.user.email,
      ),
      Trip(
        reference: 'QZ-3BV9KE',
        legs: [_leg('QZ 7511', DateTime(2026, 8, 28), seat: null, gate: '-', terminal: '1')],
        passengers: [traveller],
        fareName: 'Lite',
        cabin: CabinClass.economy,
        totalPaid: 99,
        status: TripStatus.cancelled,
        extras: const [],
        bookedAt: DateTime(2026, 8, 10),
        paymentLabel: 'Visa •••• 4242',
        contactEmail: DemoCatalog.user.email,
      ),
    ];
  }

  /// Flights the traveller follows without holding a ticket.
  static List<FlightStatus> tracked() {
    final tr145 = _flight('TR 145', DateTime(2026, 9, 3));
    final jq111 = _flight('JQ 111', DateTime(2026, 9, 3));
    return [
      FlightStatus(
        flight: tr145,
        phase: FlightPhase.inAir,
        terminal: '1',
        gate: 'F4',
        boarding: tr145.departure.subtract(const Duration(minutes: 40)),
        altitudeFeet: 37000,
        speedKmh: 860,
        belt: '5',
      ),
      FlightStatus(
        flight: jq111,
        phase: FlightPhase.landed,
        terminal: '2',
        gate: 'D11',
        boarding: jq111.departure.subtract(const Duration(minutes: 45)),
        belt: '7',
      ),
    ];
  }

  static List<AppNotification> notifications() {
    final now = DemoClock.anchor;
    return [
      AppNotification(
        id: 'n-gate',
        kind: NotificationKind.gate,
        title: 'Gate assigned',
        body: 'GA 159 leaves from Terminal 1, Gate A9. Boarding starts 5:30 AM.',
        tag: 'GA 159 · DPS–CGK',
        time: now.subtract(const Duration(minutes: 52)),
        flightNumber: 'GA 159',
        tripReference: 'GA-4F7CMH',
      ),
      AppNotification(
        id: 'n-boarding',
        kind: NotificationKind.boarding,
        title: 'Now boarding at F4',
        body: 'TR 145 from Singapore to Denpasar is boarding. The gate closes at 6:25 PM.',
        tag: 'TR 145 · SIN–DPS',
        time: now.subtract(const Duration(hours: 1)),
        read: true,
        flightNumber: 'TR 145',
      ),
      AppNotification(
        id: 'n-landed',
        kind: NotificationKind.landed,
        title: 'Landed in Denpasar',
        body: 'JQ 111 from Melbourne touched down at 3:30 PM. Bags are due on belt 7, Terminal 2.',
        tag: 'JQ 111 · MEL–DPS',
        time: now.subtract(const Duration(hours: 4)),
        read: true,
        flightNumber: 'JQ 111',
      ),
      AppNotification(
        id: 'n-price',
        kind: NotificationKind.priceDrop,
        title: 'CGK → SIN from \$79',
        body: 'Fares on Fri, 9 Oct are down \$17 since you started watching. Scoot has the lowest.',
        tag: 'Fri, 9 Oct · Economy',
        time: now.subtract(const Duration(hours: 11)),
      ),
      AppNotification(
        id: 'n-checkin',
        kind: NotificationKind.checkIn,
        title: 'Check-in is open',
        body: 'GA 159 to Jakarta leaves tomorrow at 6:05 AM. Check in now and pick your seat.',
        tag: 'GA 159 · DPS–CGK',
        time: now.subtract(const Duration(hours: 13)),
        read: true,
        flightNumber: 'GA 159',
        tripReference: 'GA-4F7CMH',
      ),
    ];
  }
}
