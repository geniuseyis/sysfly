import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../my_flights/trips_controller.dart';
import '../flight_status_controller.dart';
import 'flight_status_card.dart';

/// Opens the detail sheet for one or more flight statuses.
Future<void> showFlightStatusSheet(BuildContext context, List<FlightStatus> statuses) {
  return showSysflySheet<void>(
    context,
    expand: statuses.length > 1,
    builder: (_) => _FlightStatusSheet(statuses: statuses),
  );
}

class _FlightStatusSheet extends ConsumerWidget {
  const _FlightStatusSheet({required this.statuses});

  final List<FlightStatus> statuses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).now();
    final tracked = ref.watch(trackedFlightsProvider).valueOrNull ?? const <FlightStatus>[];
    final held = {
      for (final trip in ref.watch(tripsProvider))
        for (final leg in trip.legs) leg.flight.id,
    };

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      children: [
        SysflySheetTitle(
          title: statuses.length == 1 ? 'Flight ${statuses.first.flight.number}' : '${statuses.length} flights',
          subtitle: statuses.length == 1
              ? '${statuses.first.flight.airline.name} · ${Fmt.dayShort(statuses.first.flight.departure)}'
              : '${statuses.first.flight.origin.code} → ${statuses.first.flight.destination.code} · '
                  '${Fmt.dayShort(statuses.first.flight.departure)}',
        ),
        const SizedBox(height: 16),
        for (final status in statuses) ...[
          FlightStatusCard(status: status, now: now),
          const SizedBox(height: 14),
          if (statuses.length == 1) ...[
            _Timeline(status: status, now: now),
            const SizedBox(height: 14),
            _Facts(status: status),
            const SizedBox(height: 16),
          ],
          if (!held.contains(status.flight.id)) ...[
            if (tracked.any((t) => t.flight.id == status.flight.id))
              SysflyOutlineButton(
                label: 'Stop tracking ${status.flight.number}',
                icon: SysflyIcons.close,
                expand: true,
                height: 52,
                onPressed: () async {
                  await ref.read(trackedFlightsProvider.notifier).untrack(status);
                  if (context.mounted) showSysflyToast(context, '${status.flight.number} removed from tracked flights');
                },
              )
            else
              SysflyGradientButton(
                label: 'Track ${status.flight.number}',
                icon: SysflyIcons.target,
                onPressed: () async {
                  await ref.read(trackedFlightsProvider.notifier).track(status);
                  if (context.mounted) showSysflyToast(context, 'Tracking ${status.flight.number}', icon: SysflyIcons.check);
                },
              ),
            const SizedBox(height: 14),
          ],
        ],
        TrText(
          'Sample data · this demo build is not connected to a live flight feed',
          textAlign: TextAlign.center,
          style: SysflyTypography.caption.copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status, required this.now});

  final FlightStatus status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final flight = status.flight;
    final reached = switch (status.phase) {
      FlightPhase.scheduled || FlightPhase.delayed || FlightPhase.cancelled => 0,
      FlightPhase.boarding => 1,
      FlightPhase.inAir => 2,
      FlightPhase.landed => 3,
    };
    final steps = [
      ('Gate ${status.gate} assigned', 'Terminal ${status.terminal}'),
      ('Boarding', Fmt.time(status.boarding)),
      ('Departs ${flight.origin.city}', Fmt.time(flight.departure)),
      ('Arrives ${flight.destination.city}', Fmt.time(flight.arrival)),
    ];
    return SysflyCard(
      radius: SysflyRadius.xl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrText('Timeline', style: SysflyTypography.cardTitle.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= reached ? SysflyColors.selected : SysflyColors.surface,
                            border: Border.all(color: i <= reached ? SysflyColors.selected : const Color(0xFFCDD1DE), width: 1.6),
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: i < reached ? SysflyColors.selected : const Color(0xFFE2E5EF),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: TrText(
                              steps[i].$1,
                              style: SysflyTypography.body.copyWith(
                                fontSize: 14,
                                fontWeight: i == reached ? FontWeight.w700 : FontWeight.w500,
                                color: i <= reached ? SysflyColors.textPrimary : SysflyColors.textSecondary,
                              ),
                            ),
                          ),
                          TrText(steps[i].$2, style: SysflyTypography.captionStrong),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.status});

  final FlightStatus status;

  @override
  Widget build(BuildContext context) {
    final flight = status.flight;
    final facts = [
      ('Aircraft', flight.aircraft),
      ('Duration', Fmt.duration(flight.duration)),
      ('From', '${flight.origin.name} (${flight.origin.code})'),
      ('To', '${flight.destination.name} (${flight.destination.code})'),
      if (status.altitudeFeet != null) ('Altitude', '${Fmt.number(status.altitudeFeet!)} ft'),
      if (status.speedKmh != null) ('Speed', '${status.speedKmh} km/h'),
      if (status.belt != null) ('Baggage belt', status.belt!),
    ];
    return SysflyCard(
      radius: SysflyRadius.xl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrText('Flight details', style: SysflyTypography.cardTitle.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          for (final (label, value) in facts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  TrText(label, style: SysflyTypography.bodySecondary.copyWith(fontSize: 13.5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TrText(
                      value,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SysflyTypography.bodyStrong.copyWith(fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
