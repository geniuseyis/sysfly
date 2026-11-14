import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

SysflyChipTone toneOf(FlightPhase phase) => switch (phase) {
      FlightPhase.scheduled || FlightPhase.landed => SysflyChipTone.success,
      FlightPhase.boarding || FlightPhase.inAir => SysflyChipTone.info,
      FlightPhase.delayed || FlightPhase.cancelled => SysflyChipTone.danger,
    };

/// "Departs in" / "Lands in" / "Landed" caption and value for a status.
(String, String) countdownOf(FlightStatus status, DateTime now) {
  final flight = status.flight;
  final landing = flight.departure.add(flight.duration);
  return switch (status.phase) {
    FlightPhase.inAir => ('Lands in', Fmt.countdown(landing.difference(now))),
    FlightPhase.landed => ('Landed', Fmt.time(flight.arrival)),
    FlightPhase.cancelled => ('Status', 'Cancelled'),
    _ => ('Departs in', Fmt.countdown(flight.departure.difference(now))),
  };
}

/// Full status card: navy strip, route, three facts and a countdown footer.
class FlightStatusCard extends StatelessWidget {
  const FlightStatusCard({super.key, required this.status, required this.now, this.onTap});

  final FlightStatus status;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final flight = status.flight;
    final airborne = status.phase == FlightPhase.inAir || status.phase == FlightPhase.landed;
    final facts = airborne
        ? [
            ('ALTITUDE', status.altitudeFeet == null ? '—' : '${Fmt.number(status.altitudeFeet!)} ft'),
            ('SPEED', status.speedKmh == null ? '—' : '${status.speedKmh} km/h'),
            ('BELT', status.belt ?? '—'),
          ]
        : [('TERMINAL', status.terminal), ('GATE', status.gate), ('BOARDING', Fmt.time(status.boarding))];
    final (caption, value) = countdownOf(status, now);

    // Two stacked sections with a sliver of background between them, like a
    // ticket and its counterfoil.
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Section(
          radius: const BorderRadius.vertical(top: Radius.circular(22), bottom: Radius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 31,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(gradient: SysflyGradients.ticketStrip),
                child: Row(
                  children: [
                    TrText(flight.number, style: SysflyTypography.captionStrong.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: TrText(
                        '  ·  ${flight.airline.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SysflyTypography.caption.copyWith(color: const Color(0xCCFFFFFF)),
                      ),
                    ),
                    TrText(
                      Fmt.ticketDate(flight.departure),
                      style: SysflyTypography.overline.copyWith(color: const Color(0xD9FFFFFF), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TrText(flight.origin.code, style: SysflyTypography.airportCode.copyWith(fontSize: 27)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TrText(
                                  Fmt.duration(flight.duration),
                                  style: SysflyTypography.chip.copyWith(fontSize: 11, color: SysflyColors.link, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                SysflyFlightRouteLine(
                                  style: RouteLineStyle.straight,
                                  height: 16,
                                  progress: status.phase == FlightPhase.landed
                                      ? 0.94
                                      : status.phase == FlightPhase.inAir
                                          ? status.progressAt(now)
                                          : 0.08,
                                  startColor: SysflyColors.selected,
                                ),
                              ],
                            ),
                          ),
                        ),
                        TrText(flight.destination.code, style: SysflyTypography.airportCode.copyWith(fontSize: 27)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TrText(flight.origin.city, style: SysflyTypography.caption.copyWith(color: SysflyColors.royalText, fontWeight: FontWeight.w500)),
                        TrText(flight.destination.city, style: SysflyTypography.caption.copyWith(color: SysflyColors.royalText, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TrText(Fmt.time(flight.departure), style: SysflyTypography.ticketValue.copyWith(fontSize: 14.5)),
                        TrText(Fmt.time(flight.arrival), style: SysflyTypography.ticketValue.copyWith(fontSize: 14.5)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var i = 0; i < facts.length; i++)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: i == 0
                                  ? CrossAxisAlignment.start
                                  : i == facts.length - 1
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.center,
                              children: [
                                TrText(facts[i].$1, style: SysflyTypography.overline),
                                const SizedBox(height: 5),
                                TrText(facts[i].$2, style: SysflyTypography.ticketValue),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _Section(
          radius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SysflyIcon(SysflyIcons.clock, size: 13, color: SysflyColors.textSecondary),
                          const SizedBox(width: 5),
                          TrText(caption, style: SysflyTypography.caption.copyWith(color: SysflyColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      TrText(value, style: SysflyTypography.total.copyWith(fontSize: 21)),
                    ],
                  ),
                ),
                SysflyStatusChip(label: status.phase.label, tone: toneOf(status.phase)),
              ],
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: '${flight.number} ${flight.origin.city} to ${flight.destination.city}, ${status.phase.label}, $caption $value',
      child: SysflyPressable(onTap: onTap, pressedScale: 0.985, child: ExcludeSemantics(child: card)),
    );
  }
}

/// One white, softly shadowed part of a status card.
class _Section extends StatelessWidget {
  const _Section({required this.radius, required this.child});

  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: SysflyShadows.soft),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(color: SysflyColors.surface, child: child),
      ),
    );
  }
}

/// Compact row for a later flight: date tile, route, times and status.
class FlightStatusRow extends StatelessWidget {
  const FlightStatusRow({super.key, required this.status, required this.now, required this.onTap});

  final FlightStatus status;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final flight = status.flight;
    final (caption, value) = countdownOf(status, now);
    return Semantics(
      button: true,
      label: '${flight.origin.code} to ${flight.destination.code}, ${Fmt.dayShort(flight.departure)}, '
          '${Fmt.time(flight.departure)}, ${status.phase.label}',
      child: SysflyPressable(
        onTap: onTap,
        pressedScale: 0.985,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: SysflyColors.field,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SysflyColors.fieldBorder),
                  ),
                  child: Column(
                    children: [
                      TrText(
                        Fmt.weekday(flight.departure).toUpperCase(),
                        style: SysflyTypography.overline.copyWith(fontSize: 8.5, color: SysflyColors.royalText, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 1),
                      TrText('${flight.departure.day}', style: SysflyTypography.cardTitle.copyWith(fontSize: 17)),
                      TrText(Fmt.month(flight.departure), style: SysflyTypography.caption.copyWith(fontSize: 9.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TrText(
                              '${flight.origin.code} → ${flight.destination.code}',
                              style: SysflyTypography.bodyStrong.copyWith(fontSize: 15.5),
                            ),
                          ),
                          SysflyStatusChip(label: status.phase.label, tone: toneOf(status.phase)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      TrText(
                        '${Fmt.time(flight.departure)}  →  ${Fmt.time(flight.arrival)}',
                        style: SysflyTypography.ticketValue.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: tr('$caption $value'),
                              style: SysflyTypography.captionStrong.copyWith(fontSize: 12, color: SysflyColors.royalText, fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: '  ·  ${tr('Gate ${status.gate}')}  ·  ${flight.number}'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SysflyTypography.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
