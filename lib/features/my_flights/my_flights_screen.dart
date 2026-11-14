import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../shell/shell_controller.dart';
import 'trips_controller.dart';
import 'widgets/trip_ticket.dart';

/// My Flights tab: the next boarding pass, check-in, and every booking
/// grouped into upcoming, past and cancelled.
class MyFlightsScreen extends ConsumerStatefulWidget {
  const MyFlightsScreen({super.key});

  @override
  ConsumerState<MyFlightsScreen> createState() => _MyFlightsScreenState();
}

class _MyFlightsScreenState extends ConsumerState<MyFlightsScreen> {
  TripStatus _tab = TripStatus.upcoming;
  bool _checkingIn = false;

  Future<void> _checkIn(Trip trip) async {
    setState(() => _checkingIn = true);
    try {
      await ref.read(tripsControllerProvider.notifier).checkIn(trip);
      SysflyHaptics.success();
      if (mounted) showSysflyToast(context, 'You are checked in. Your boarding pass is ready.', icon: SysflyIcons.check);
    } catch (error) {
      if (mounted) showSysflyToast(context, describeError(error), error: true);
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider).now();
    final next = ref.watch(nextTripProvider);
    final upcoming = ref.watch(upcomingTripsProvider);
    final past = ref.watch(pastTripsProvider);
    final cancelled = ref.watch(cancelledTripsProvider);
    final shown = switch (_tab) {
      TripStatus.upcoming => upcoming,
      TripStatus.past => past,
      TripStatus.cancelled => cancelled,
    };

    return ColoredBox(
      color: SysflyColors.background,
      child: Column(
        children: [
          SysflyHeader.brand(
            title: 'My Flights',
            trailing: SysflyCircleButton(
              icon: SysflyIcons.search,
              semanticLabel: 'Find a booking',
              onTap: () => showSysflySheet<void>(context, expand: true, builder: (_) => const _FindBookingSheet()),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 20, SysflySpacing.page, SysflySpacing.navClearance),
              children: [
                if (next != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TrText(
                          'NEXT TRIP',
                          style: SysflyTypography.overline.copyWith(fontSize: 11, color: SysflyColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SysflyStatusChip(
                        label: 'Departs in ${Fmt.countdown(next.firstLeg.flight.departure.difference(now))}',
                        tone: SysflyChipTone.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  SysflyPressable(
                    onTap: () => context.push(Routes.tripDetails(next.reference)),
                    pressedScale: 0.985,
                    child: SysflyBoardingPass(leg: next.firstLeg, passenger: next.passenger),
                  ),
                  const SizedBox(height: 16),
                  _checkInButton(next, now),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SysflyIcon(SysflyIcons.clock, size: 14, color: SysflyColors.textTertiary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: TrText(
                          next.checkedIn
                              ? 'Checked in · boarding ${Fmt.time(next.firstLeg.boarding)}'
                              : next.isCheckInOpen(now)
                                  ? 'Online check-in closes ${Fmt.dayMonth(next.checkInCloses)}, ${Fmt.time(next.checkInCloses)}'
                                  : 'Online check-in opens ${Fmt.dayMonth(next.checkInOpens)}, ${Fmt.time(next.checkInOpens)}',
                          style: SysflyTypography.caption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],
                _TripTabs(
                  selected: _tab,
                  counts: {
                    TripStatus.upcoming: upcoming.length,
                    TripStatus.past: past.length,
                    TripStatus.cancelled: cancelled.length,
                  },
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: SysflyMotion.normal,
                  layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                  child: Column(
                    key: ValueKey(_tab),
                    children: [
                      if (shown.isEmpty)
                        _EmptyTrips(
                          status: _tab,
                          onSearch: () => ref.read(navigationProvider.notifier).select(AppTab.home),
                        ),
                      for (final trip in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TripTicket(trip: trip, now: now, onTap: () => context.push(Routes.tripDetails(trip.reference))),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkInButton(Trip trip, DateTime now) {
    if (trip.checkedIn) {
      return SysflyGradientButton(
        label: 'View boarding pass',
        icon: SysflyIcons.boardingPass,
        height: 52,
        onPressed: () => context.push(Routes.tripDetails(trip.reference)),
      );
    }
    final open = trip.isCheckInOpen(now);
    return SysflyGradientButton(
      key: const ValueKey('check-in-now'),
      label: open ? 'Check in now' : 'Check-in not open yet',
      icon: SysflyIcons.checkIn,
      height: 52,
      loading: _checkingIn,
      onPressed: open ? () => _checkIn(trip) : null,
    );
  }
}

class _TripTabs extends StatelessWidget {
  const _TripTabs({required this.selected, required this.counts, required this.onChanged});

  final TripStatus selected;
  final Map<TripStatus, int> counts;
  final ValueChanged<TripStatus> onChanged;

  static const _labels = {TripStatus.upcoming: 'Upcoming', TripStatus.past: 'Past', TripStatus.cancelled: 'Cancelled'};

  @override
  Widget build(BuildContext context) {
    final tabs = TripStatus.values;
    return Container(
      height: 66,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: SysflyColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F1F8)),
        boxShadow: SysflyShadows.soft,
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(-1 + 2 * tabs.indexOf(selected) / (tabs.length - 1), 0),
            duration: SysflyMotion.normal,
            curve: SysflyMotion.emphasized,
            child: FractionallySizedBox(
              widthFactor: 1 / tabs.length,
              heightFactor: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: SysflyGradients.indicator,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final tab in tabs)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: tab == selected,
                    label: '${_labels[tab]}, ${_count(tab)}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (tab != selected) {
                          SysflyHaptics.selection();
                          onChanged(tab);
                        }
                      },
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: SysflyMotion.normal,
                              style: SysflyTypography.bodyStrong.copyWith(
                                fontSize: 14,
                                color: tab == selected ? Colors.white : SysflyColors.textPrimary,
                              ),
                              child: TrText(_labels[tab]!),
                            ),
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: SysflyMotion.normal,
                              style: SysflyTypography.caption.copyWith(
                                fontSize: 11.5,
                                color: tab == selected ? const Color(0xBFFFFFFF) : SysflyColors.textTertiary,
                              ),
                              child: TrText(_count(tab)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _count(TripStatus tab) {
    final n = counts[tab] ?? 0;
    return n == 1 ? '1 trip' : '$n trips';
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.status, required this.onSearch});

  final TripStatus status;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      TripStatus.upcoming => 'No upcoming trips yet',
      TripStatus.past => 'Trips you have flown will show here',
      TripStatus.cancelled => 'No cancelled trips',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const SysflyIconTile(icon: SysflyIcons.planeOutline, size: 56),
          const SizedBox(height: 14),
          TrText(message, style: SysflyTypography.bodySecondary),
          if (status == TripStatus.upcoming) ...[
            const SizedBox(height: 16),
            SysflyOutlineButton(label: 'Search flights', icon: SysflyIcons.search, onPressed: onSearch),
          ],
        ],
      ),
    );
  }
}

class _FindBookingSheet extends ConsumerStatefulWidget {
  const _FindBookingSheet();

  @override
  ConsumerState<_FindBookingSheet> createState() => _FindBookingSheetState();
}

class _FindBookingSheetState extends ConsumerState<_FindBookingSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(Trip trip, String q) {
    if (q.isEmpty) return true;
    final haystack = [
      trip.reference,
      for (final leg in trip.legs) ...[
        leg.flight.number,
        leg.flight.airline.name,
        leg.flight.origin.code,
        leg.flight.origin.city,
        leg.flight.destination.code,
        leg.flight.destination.city,
      ],
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider).now();
    final q = _query.text.trim().toLowerCase();
    final trips = ref.watch(tripsProvider).where((t) => _matches(t, q)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SysflySheetTitle(title: 'Find a booking'),
              const SizedBox(height: 14),
              SysflyTextField(
                controller: _query,
                hint: 'Booking reference, city or flight',
                icon: SysflyIcons.search,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        Expanded(
          child: trips.isEmpty
              ? Center(child: TrText('No bookings match your search', style: SysflyTypography.bodySecondary))
              : ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 16, SysflySpacing.page, 24),
                  children: [
                    for (final trip in trips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TripTicket(
                          trip: trip,
                          now: now,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(Routes.tripDetails(trip.reference));
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
