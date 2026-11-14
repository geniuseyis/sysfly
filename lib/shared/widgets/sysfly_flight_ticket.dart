import 'package:flutter/material.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/formatters.dart';
import '../models/models.dart';
import 'sysfly_flight_route_line.dart';
import 'sysfly_world_dots.dart';

/// One labelled value in the bottom row of a ticket, e.g. FLIGHT / GA 159.
@immutable
class TicketDetail {
  const TicketDetail(this.label, this.value);
  final String label;
  final String value;
}

/// Ticket-shaped flight card: a navy strip with the airline, the route with
/// its flight line, a row of details, and a perforated stub on the right.
class SysflyFlightTicket extends StatelessWidget {
  const SysflyFlightTicket({
    super.key,
    required this.flight,
    required this.details,
    required this.stub,
    this.stripTitle,
    this.stripDate,
    this.onTap,
    this.semanticLabel,
  });

  final Flight flight;
  final List<TicketDetail> details;

  /// Content of the tear-off stub below the date strip.
  final Widget stub;

  /// Defaults to the airline name.
  final String? stripTitle;

  /// Defaults to the departure date, e.g. "FRI 4 SEP".
  final String? stripDate;
  final VoidCallback? onTap;
  final String? semanticLabel;

  static const double stubWidth = 112;
  static const double stripHeight = 32;
  static const double _outer = 18;
  static const double _inner = 10;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(_outer)),
        boxShadow: SysflyShadows.card,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _TicketPart(
                radius: const BorderRadius.horizontal(left: Radius.circular(_outer), right: Radius.circular(_inner)),
                strip: Align(
                  alignment: Alignment.centerLeft,
                  child: TrText(
                    stripTitle ?? flight.airline.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SysflyTypography.captionStrong.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                body: _TicketBody(flight: flight, details: details),
              ),
            ),
            const _Perforation(),
            SizedBox(
              width: stubWidth,
              child: _TicketPart(
                radius: const BorderRadius.horizontal(left: Radius.circular(_inner), right: Radius.circular(_outer)),
                strip: Center(
                  child: TrText(
                    stripDate ?? Fmt.ticketDate(flight.departure),
                    maxLines: 1,
                    style: SysflyTypography.overline.copyWith(color: const Color(0xD9FFFFFF), fontWeight: FontWeight.w600),
                  ),
                ),
                body: Padding(padding: const EdgeInsets.fromLTRB(10, 12, 10, 12), child: stub),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel ??
          '${flight.airline.name} ${flight.number}, ${flight.origin.city} to ${flight.destination.city}, '
              '${Fmt.time(flight.departure)}',
      child: SysflyPressable(onTap: onTap, pressedScale: 0.985, child: ExcludeSemantics(child: card)),
    );
  }
}

class _TicketPart extends StatelessWidget {
  const _TicketPart({required this.radius, required this.strip, required this.body});

  final BorderRadius radius;
  final Widget strip;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: SysflyColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: SysflyFlightTicket.stripHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(gradient: SysflyGradients.ticketStrip),
              child: strip,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// The gap between ticket and stub, with a dotted tear line.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 3,
      child: Padding(
        padding: const EdgeInsets.only(top: SysflyFlightTicket.stripHeight + 8, bottom: 8),
        child: CustomPaint(painter: _DashPainter()),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD3D7E3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var y = 0.0; y < size.height; y += 5) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TicketBody extends StatelessWidget {
  const _TicketBody({required this.flight, required this.details});

  final Flight flight;
  final List<TicketDetail> details;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(60, 4, 60, 40),
            child: SysflyWorldDots(color: Color(0x0D1A266E), zoom: 1.25, alignment: Alignment(0.55, -0.2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 14, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Endpoint(label: 'FROM', airport: flight.origin, time: flight.departure, alignEnd: false),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                      child: Column(
                        children: [
                          TrText(
                            Fmt.duration(flight.duration),
                            style: SysflyTypography.chip.copyWith(fontSize: 11, color: SysflyColors.link, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          const SysflyFlightRouteLine(height: 24),
                        ],
                      ),
                    ),
                  ),
                  _Endpoint(label: 'TO', airport: flight.destination, time: flight.arrival, alignEnd: true),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < details.length; i++)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: i == 0
                            ? CrossAxisAlignment.start
                            : i == details.length - 1
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.center,
                        children: [
                          TrText(details[i].label, style: SysflyTypography.overline),
                          const SizedBox(height: 5),
                          TrText(details[i].value, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.ticketValue),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.label, required this.airport, required this.time, required this.alignEnd});

  final String label;
  final Airport airport;
  final DateTime time;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TrText(label, style: SysflyTypography.overline),
        const SizedBox(height: 3),
        TrText(airport.code, style: SysflyTypography.airportCode),
        const SizedBox(height: 1),
        TrText(
          airport.city,
          style: SysflyTypography.caption.copyWith(color: SysflyColors.royalText, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 9),
        TrText(Fmt.time(time), style: SysflyTypography.ticketValue.copyWith(fontSize: 14)),
      ],
    );
  }
}

/// Stub content showing a fare, e.g. BEST FARE / $52 / per person.
class TicketFareStub extends StatelessWidget {
  const TicketFareStub({super.key, required this.label, required this.price, required this.barcode});

  final String label;
  final int price;
  final String barcode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 2),
        TrText(label, style: SysflyTypography.overline),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, child: TrText(Fmt.moneyShort(price), style: SysflyTypography.price)),
        const SizedBox(height: 2),
        TrText('per person', style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
        const Spacer(),
        SizedBox(height: 30, child: SysflyBarcode(data: barcode)),
      ],
    );
  }
}

/// Stub content for a held booking: status chip, reference, travellers.
class TicketBookingStub extends StatelessWidget {
  const TicketBookingStub({super.key, required this.chip, required this.reference, required this.note});

  final Widget chip;
  final String reference;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(fit: BoxFit.scaleDown, child: chip),
        const SizedBox(height: 10),
        TrText('BOOKING', style: SysflyTypography.overline),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: TrText(reference, style: SysflyTypography.ticketValue.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 3),
        TrText(note, style: SysflyTypography.caption.copyWith(fontSize: 11)),
        const Spacer(),
        SizedBox(height: 30, child: SysflyBarcode(data: reference)),
      ],
    );
  }
}
