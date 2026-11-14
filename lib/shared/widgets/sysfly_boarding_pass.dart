import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/utils/formatters.dart';
import '../models/models.dart';
import 'sysfly_flight_route_line.dart';
import 'sysfly_world_dots.dart';

/// Navy boarding pass with a barcode spine and a white tear-off stub.
class SysflyBoardingPass extends StatelessWidget {
  const SysflyBoardingPass({super.key, required this.leg, required this.passenger, this.traveller = 0});

  final TripLeg leg;
  final Passenger passenger;

  /// Index of [passenger] within the booking, used to look up the seat.
  final int traveller;

  static const double height = 236;

  @override
  Widget build(BuildContext context) {
    final flight = leg.flight;
    final (time, meridiem) = Fmt.timeParts(leg.boarding);
    final seat = leg.seatOf(traveller) ?? '—';
    return Semantics(
      label:
          'Boarding pass. ${flight.airline.name} ${flight.number}, ${flight.origin.city} to '
          '${flight.destination.city}. Boarding ${Fmt.time(leg.boarding)}, gate ${leg.gate}, seat $seat.',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(22)), boxShadow: SysflyShadows.card),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Main(leg: leg, passenger: passenger, time: time, meridiem: meridiem, seat: seat),
                ),
                Container(
                  width: 20,
                  color: SysflyColors.surface,
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 18),
                  child: SysflyBarcode(data: '${flight.number}${passenger.fullName}', vertical: true),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 96,
                  child: _Stub(leg: leg, passenger: passenger, seat: seat),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({required this.leg, required this.passenger, required this.time, required this.meridiem, required this.seat});

  final TripLeg leg;
  final Passenger passenger;
  final String time;
  final String meridiem;
  final String seat;

  static final _label = SysflyTypography.overline.copyWith(color: const Color(0x99FFFFFF), fontSize: 9);

  @override
  Widget build(BuildContext context) {
    final flight = leg.flight;
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: SysflyGradients.boardingPass),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(left: 70, bottom: 56),
                child: SysflyWorldDots(color: Color(0x14FFFFFF), zoom: 1.5, alignment: Alignment(0.5, -0.3)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Scaled down rather than wrapped when a translation is long.
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: TrText(
                                'BOARDING PASS',
                                maxLines: 1,
                                style: SysflyTypography.bodyStrong.copyWith(color: Colors.white, fontSize: 15, letterSpacing: 1.6),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const SysflyIcon(SysflyIcons.planeTilt, size: 13, color: Color(0xFF8FC8FF)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: TrText(
                                    flight.airline.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SysflyTypography.caption.copyWith(color: const Color(0xCCFFFFFF), fontSize: 11.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TrText('BOARDING', style: _label),
                          const SizedBox(height: 1),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              TrText(
                                time,
                                style: SysflyTypography.airportCode.copyWith(color: Colors.white, fontSize: 25, letterSpacing: -0.3),
                              ),
                              const SizedBox(width: 3),
                              TrText(
                                meridiem,
                                style: SysflyTypography.chip.copyWith(
                                  color: const Color(0xFF6FC3F5),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TrText('PASSENGER', style: _label),
                  const SizedBox(height: 3),
                  TrText(
                    passenger.fullName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SysflyTypography.bodyStrong.copyWith(color: Colors.white, fontSize: 13, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: TrText('FROM', style: _label),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: TrText('TO', style: _label),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TrText(flight.origin.code, style: SysflyTypography.airportCode.copyWith(color: Colors.white, fontSize: 25)),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: SysflyFlightRouteLine(
                            style: RouteLineStyle.straight,
                            height: 18,
                            startColor: Color(0xFFDDE3FF),
                            lineColor: Color(0xFFFFFFFF),
                            planeColor: Color(0xFFFFFFFF),
                            dottedColor: Color(0x80FFFFFF),
                            endColor: Color(0xFFDDE3FF),
                            endFilled: true,
                          ),
                        ),
                      ),
                      TrText(flight.destination.code, style: SysflyTypography.airportCode.copyWith(color: Colors.white, fontSize: 25)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TrText(flight.origin.city, style: SysflyTypography.caption.copyWith(color: const Color(0xB3FFFFFF), fontSize: 11)),
                      TrText(
                        flight.destination.city,
                        style: SysflyTypography.caption.copyWith(color: const Color(0xB3FFFFFF), fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    height: 46,
                    decoration: BoxDecoration(color: SysflyColors.surface, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _Cell(label: 'GATE', value: leg.gate),
                        const _CellDivider(),
                        _Cell(label: 'DATE', value: Fmt.dayMonth(flight.departure).toUpperCase()),
                        const _CellDivider(),
                        _Cell(label: 'FLIGHT', value: flight.number),
                        const _CellDivider(),
                        _Cell(label: 'SEAT', value: seat, highlight: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TrText(label, style: SysflyTypography.overline.copyWith(fontSize: 7.5, letterSpacing: 1)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: TrText(
              value,
              style: SysflyTypography.ticketValue.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: highlight ? SysflyColors.royalText : SysflyColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 24, child: VerticalDivider(width: 1, thickness: 1, color: SysflyColors.divider));
}

class _Stub extends StatelessWidget {
  const _Stub({required this.leg, required this.passenger, required this.seat});

  final TripLeg leg;
  final Passenger passenger;
  final String seat;

  static final _label = SysflyTypography.overline.copyWith(fontSize: 7.5, letterSpacing: 1);
  static final _value = SysflyTypography.ticketValue.copyWith(fontSize: 12, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final flight = leg.flight;
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10), right: Radius.circular(22)),
      child: ColoredBox(
        color: SysflyColors.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SysflyIcon(SysflyIcons.planeTilt, size: 14, color: SysflyColors.royalText),
              const SizedBox(height: 4),
              TrText(
                flight.airline.name.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SysflyTypography.overline.copyWith(
                  fontSize: 8,
                  color: SysflyColors.royalText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              TrText('PASSENGER', style: _label),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: TrText(passenger.shortName.toUpperCase(), style: _value),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TrText('FROM', style: _label),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TrText('TO', style: _label),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TrText(flight.origin.code, style: _value),
                  TrText(flight.destination.code, style: _value),
                ],
              ),
              const SizedBox(height: 8),
              TrText('BOARDING', style: _label),
              const SizedBox(height: 2),
              TrText(Fmt.time(leg.boarding), style: _value),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EAFC),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: SysflyColors.selected, width: 1.2),
                ),
                child: Column(
                  children: [
                    TrText('SEAT', style: _label.copyWith(color: SysflyColors.royalText)),
                    TrText(seat, style: SysflyTypography.cardTitle.copyWith(color: SysflyColors.royalText, fontSize: 17)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
