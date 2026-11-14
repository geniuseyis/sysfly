import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock/demo_catalog.dart';
import '../../data/repositories/providers.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../flight_status/widgets/flight_status_sheet.dart';
import 'trip_actions.dart';
import 'trips_controller.dart';
import 'widgets/trip_sheets.dart';

/// One booking: its boarding pass, reference, every action available for it
/// and a check-in bar.
class TripDetailsScreen extends ConsumerStatefulWidget {
  const TripDetailsScreen({super.key, required this.reference});

  final String reference;

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  int _leg = 0;
  int _traveller = 0;
  bool _busy = false;

  /// Runs a trip mutation, showing its result or error as a toast.
  Future<void> _run(Future<void> Function() action, {String? done}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (done != null && mounted) showSysflyToast(context, done, icon: SysflyIcons.check);
    } catch (error) {
      if (mounted) showSysflyToast(context, describeError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkIn(Trip trip) => _run(
        () async {
          await ref.read(tripsControllerProvider.notifier).checkIn(trip);
          SysflyHaptics.success();
        },
        done: 'You are checked in. Your boarding pass is ready.',
      );

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripByReferenceProvider(widget.reference));
    final now = ref.watch(clockProvider).now();
    if (trip == null) {
      return Scaffold(
        backgroundColor: SysflyColors.background,
        body: Column(
          children: [
            SysflyHeader(title: 'Trip Details', onBack: () => context.pop()),
            Expanded(child: Center(child: TrText('This booking could not be found', style: SysflyTypography.bodySecondary))),
          ],
        ),
      );
    }

    final legIndex = _leg.clamp(0, trip.legs.length - 1);
    final travellerIndex = _traveller.clamp(0, trip.passengers.length - 1);
    final leg = trip.legs[legIndex];
    final upcoming = trip.status == TripStatus.upcoming;
    final checkInOpen = trip.isCheckInOpen(now);
    final hasBaggage = trip.extras.contains(DemoCatalog.extras.first);
    final (statusLabel, statusTone) = switch (trip.status) {
      TripStatus.upcoming => (trip.checkedIn ? 'Checked in' : 'Confirmed', SysflyChipTone.neutral),
      TripStatus.past => ('Completed', SysflyChipTone.neutral),
      TripStatus.cancelled => ('Cancelled', SysflyChipTone.danger),
    };

    return Scaffold(
      backgroundColor: SysflyColors.background,
      body: Column(
        children: [
          SysflyHeader(
            title: 'Trip Details',
            onBack: () => context.pop(),
            trailing: Builder(
              builder: (buttonContext) => SysflyCircleButton(
                icon: SysflyIcons.share,
                semanticLabel: 'Share trip',
                onTap: () => TripActions.share(buttonContext, ref, trip),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 18, SysflySpacing.page, 24),
              children: [
                Row(
                  children: [
                    SysflyStatusChip(
                      label: statusLabel,
                      tone: statusTone,
                      icon: trip.status == TripStatus.cancelled ? null : SysflyIcons.lightning,
                    ),
                    const Spacer(),
                    if (upcoming && leg.flight.departure.isAfter(now))
                      SysflyStatusChip(
                        label: 'Departs in ${Fmt.countdown(leg.flight.departure.difference(now))}',
                        tone: SysflyChipTone.neutral,
                      )
                    else
                      SysflyStatusChip(label: Fmt.dayShort(leg.flight.departure), tone: SysflyChipTone.neutral, dot: false),
                  ],
                ),
                if (trip.legs.length > 1) ...[
                  const SizedBox(height: 14),
                  SysflySegmentedControl(
                    labels: [for (final l in trip.legs) '${l.flight.origin.code} → ${l.flight.destination.code}'],
                    index: legIndex,
                    onChanged: (i) => setState(() => _leg = i),
                  ),
                ],
                if (trip.passengers.length > 1) ...[
                  const SizedBox(height: 10),
                  SysflySegmentedControl(
                    labels: [for (final p in trip.passengers) p.firstName],
                    index: travellerIndex,
                    onChanged: (i) => setState(() => _traveller = i),
                  ),
                ],
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: SysflyMotion.normal,
                  child: Opacity(
                    key: ValueKey('pass-$legIndex-$travellerIndex-${leg.seatOf(travellerIndex)}'),
                    opacity: trip.status == TripStatus.cancelled ? 0.55 : 1,
                    child: SysflyBoardingPass(leg: leg, passenger: trip.passengers[travellerIndex], traveller: travellerIndex),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrText('BOOKING REFERENCE', style: SysflyTypography.overline),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              TrText(trip.reference, style: SysflyTypography.cardTitle.copyWith(fontSize: 19, letterSpacing: 0.8)),
                              const SizedBox(width: 6),
                              Semantics(
                                button: true,
                                label: 'Copy booking reference',
                                child: SysflyPressable(
                                  onTap: () => TripActions.copyReference(context, trip),
                                  child: const SysflyIconTile(icon: SysflyIcons.copy, size: 30),
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
                        TrText(trip.travellerLabel.toUpperCase(), style: SysflyTypography.overline),
                        const SizedBox(height: 7),
                        TrText(trip.cabin.label, style: SysflyTypography.bodyStrong),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SysflyCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Action(
                            key: const ValueKey('action-check-in'),
                            icon: SysflyIcons.checkIn,
                            title: 'Check in',
                            subtitle: trip.checkedIn ? 'Done' : (checkInOpen ? 'Open now' : 'Not open yet'),
                            emphasised: checkInOpen,
                            enabled: checkInOpen,
                            onTap: () => _checkIn(trip),
                          ),
                          _Action(
                            key: const ValueKey('action-boarding-pass'),
                            icon: SysflyIcons.boardingPass,
                            title: 'Boarding pass',
                            subtitle: trip.checkedIn ? 'Ready' : 'After check-in',
                            enabled: trip.checkedIn && trip.status != TripStatus.cancelled,
                            onTap: () => showBoardingPassSheet(context, trip: trip, leg: legIndex, traveller: travellerIndex),
                          ),
                          _Action(
                            key: const ValueKey('action-status'),
                            icon: SysflyIcons.target,
                            title: 'Flight status',
                            subtitle: leg.flight.number,
                            enabled: trip.status != TripStatus.cancelled,
                            onTap: () => showFlightStatusSheet(context, [ref.read(flightStatusRepositoryProvider).forLeg(leg)]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Action(
                            key: const ValueKey('action-baggage'),
                            icon: SysflyIcons.bag,
                            title: 'Add baggage',
                            subtitle: hasBaggage ? 'Added' : 'From ${Fmt.moneyShort(DemoCatalog.extras.first.price)}',
                            enabled: upcoming && !hasBaggage,
                            onTap: () async {
                              final ok = await showAddBaggageSheet(context, trip: trip);
                              if (ok == true) {
                                await _run(
                                  () => ref.read(tripsControllerProvider.notifier).addBaggage(trip),
                                  done: 'Extra baggage added to ${trip.reference}',
                                );
                              }
                            },
                          ),
                          _Action(
                            key: const ValueKey('action-seats'),
                            icon: SysflyIcons.cabin,
                            title: 'Change seats',
                            subtitle: 'Free',
                            enabled: upcoming,
                            onTap: () async {
                              final seat = await showChangeSeatSheet(context, leg: leg, current: leg.seatOf(travellerIndex));
                              if (seat != null) {
                                await _run(
                                  () => ref
                                      .read(tripsControllerProvider.notifier)
                                      .changeSeat(trip, leg: legIndex, traveller: travellerIndex, seat: seat),
                                  done: 'Seat changed to $seat',
                                );
                              }
                            },
                          ),
                          Builder(
                            builder: (buttonContext) => _Action(
                              key: const ValueKey('action-eticket'),
                              icon: SysflyIcons.eTicket,
                              title: 'E-ticket',
                              subtitle: 'PDF',
                              enabled: trip.status != TripStatus.cancelled,
                              onTap: () => TripActions.eTicket(buttonContext, ref, trip),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (buttonContext) => _Action(
                              key: const ValueKey('action-calendar'),
                              icon: SysflyIcons.calendarAdd,
                              title: 'Add to calendar',
                              subtitle: trip.legs.length == 1 ? '1 flight' : '${trip.legs.length} flights',
                              enabled: upcoming,
                              onTap: () => TripActions.addToCalendar(buttonContext, ref, trip),
                            ),
                          ),
                          Builder(
                            builder: (buttonContext) => _Action(
                              key: const ValueKey('action-share'),
                              icon: SysflyIcons.share,
                              title: 'Share trip',
                              subtitle: 'Itinerary',
                              onTap: () => TripActions.share(buttonContext, ref, trip),
                            ),
                          ),
                          _Action(
                            key: const ValueKey('action-cancel'),
                            icon: SysflyIcons.cancel,
                            title: 'Cancel',
                            subtitle: upcoming ? 'Small fee' : 'Not available',
                            danger: true,
                            enabled: upcoming,
                            onTap: () async {
                              final ok = await showCancelTripSheet(context, trip: trip);
                              if (ok == true) {
                                await _run(
                                  () => ref.read(tripsControllerProvider.notifier).cancel(trip),
                                  done: 'Booking ${trip.reference} cancelled',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (upcoming) _bottomBar(trip, now, checkInOpen),
        ],
      ),
    );
  }

  Widget _bottomBar(Trip trip, DateTime now, bool checkInOpen) {
    final String title;
    final String subtitle;
    final Widget action;
    if (trip.checkedIn) {
      title = 'You are checked in';
      subtitle = 'Boarding ${Fmt.time(trip.firstLeg.boarding)} · Gate ${trip.firstLeg.gate}';
      action = SysflyGradientButton(
        label: 'Boarding pass',
        icon: SysflyIcons.boardingPass,
        expand: false,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        onPressed: () => showBoardingPassSheet(context, trip: trip, leg: 0, traveller: 0),
      );
    } else if (checkInOpen) {
      title = 'Check-in is open';
      subtitle = 'Closes ${Fmt.dayMonth(trip.checkInCloses)}, ${Fmt.time(trip.checkInCloses)}';
      action = SysflyGradientButton(
        key: const ValueKey('trip-check-in'),
        label: 'Check in',
        icon: SysflyIcons.checkIn,
        expand: false,
        loading: _busy,
        onPressed: () => _checkIn(trip),
      );
    } else {
      title = 'Check-in opens soon';
      subtitle = 'Opens ${Fmt.dayMonth(trip.checkInOpens)}, ${Fmt.time(trip.checkInOpens)}';
      action = const SysflyGradientButton(label: 'Check in', icon: SysflyIcons.checkIn, expand: false, onPressed: null);
    }
    return SysflyBottomBar(title: title, subtitle: subtitle, action: action, compact: true);
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.emphasised = false,
    this.danger = false,
  });

  final SysflyIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final bool emphasised;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = danger
        ? (SysflyColors.errorBg, SysflyColors.error)
        : emphasised
            ? (SysflyColors.selected, Colors.white)
            : (SysflyColors.tile, SysflyColors.link);
    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: '$title, $subtitle',
        child: SysflyPressable(
          onTap: enabled ? onTap : null,
          pressedScale: 0.94,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: Column(
                children: [
                  SysflyIconTile(icon: icon, size: 48, background: background, foreground: foreground),
                  const SizedBox(height: 9),
                  TrText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SysflyTypography.bodyStrong.copyWith(fontSize: 13.5, color: danger ? SysflyColors.error : SysflyColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  TrText(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SysflyTypography.caption.copyWith(
                      fontSize: 11.5,
                      color: emphasised ? SysflyColors.royalText : SysflyColors.textTertiary,
                      fontWeight: emphasised ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
