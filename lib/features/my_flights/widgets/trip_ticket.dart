import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

/// A held booking drawn as a ticket, with its status on the stub.
class TripTicket extends StatelessWidget {
  const TripTicket({super.key, required this.trip, required this.now, required this.onTap});

  final Trip trip;
  final DateTime now;
  final VoidCallback onTap;

  /// "FRI 4 SEP" for one flight, "12 – 14 SEP" for several.
  static String dateLabel(Trip trip) {
    final first = trip.firstLeg.flight.departure;
    final last = trip.lastLeg.flight.departure;
    if (trip.legs.length == 1 || Fmt.sameDay(first, last)) return Fmt.ticketDate(first);
    if (first.month == last.month) return '${first.day} – ${last.day} ${Fmt.month(last).toUpperCase()}';
    return '${Fmt.dayMonth(first)} – ${Fmt.dayMonth(last)}'.toUpperCase();
  }

  static (String, SysflyChipTone) statusOf(Trip trip, DateTime now) {
    return switch (trip.status) {
      TripStatus.cancelled => ('Cancelled', SysflyChipTone.danger),
      TripStatus.past => ('Completed', SysflyChipTone.neutral),
      TripStatus.upcoming => trip.checkedIn
          ? ('Checked in', SysflyChipTone.success)
          : trip.isCheckInOpen(now)
              ? ('Check-in open', SysflyChipTone.info)
              : ('Confirmed', SysflyChipTone.neutral),
    };
  }

  @override
  Widget build(BuildContext context) {
    final leg = trip.firstLeg;
    final (label, tone) = statusOf(trip, now);
    return SysflyFlightTicket(
      key: ValueKey('trip-${trip.reference}'),
      flight: leg.flight,
      stripDate: dateLabel(trip),
      details: [
        TicketDetail('FLIGHT', leg.flight.number),
        TicketDetail('CLASS', trip.cabin.label),
        TicketDetail('SEAT', leg.seat ?? 'At check-in'),
      ],
      stub: TicketBookingStub(
        chip: SysflyStatusChip(label: label, tone: tone),
        reference: trip.reference,
        note: trip.travellerLabel,
      ),
      semanticLabel: 'Booking ${trip.reference}, ${leg.flight.origin.city} to ${leg.flight.destination.city}, '
          '${Fmt.dayShort(leg.flight.departure)}, $label',
      onTap: onTap,
    );
  }
}
