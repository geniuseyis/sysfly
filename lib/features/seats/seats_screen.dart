import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../booking/booking_controller.dart';
import '../booking/fare_screen.dart';
import '../booking/widgets/booking_scaffold.dart';

/// Step 3 of booking: pick a seat for each traveller on the cabin map, then
/// add any extras. Totals update as selections change.
class SeatsScreen extends ConsumerStatefulWidget {
  const SeatsScreen({super.key});

  @override
  ConsumerState<SeatsScreen> createState() => _SeatsScreenState();
}

class _SeatsScreenState extends ConsumerState<SeatsScreen> {
  static const _rowsPerPage = 16;
  int _page = 0;
  int _activeTraveller = 0;

  void _onSeat(Seat seat, SeatMap map, BookingDraft draft) {
    final controller = ref.read(bookingControllerProvider.notifier);
    final holder = draft.seats.entries.where((e) => e.value.id == seat.id).map((e) => e.key).firstOrNull;
    if (holder != null) {
      // Tapping a seat already chosen in this booking releases it.
      controller.clearSeat(holder);
      setState(() => _activeTraveller = holder);
      return;
    }
    controller.selectSeat(_activeTraveller, seat, standardPrice: map.standardPrice);
    // Move on to the next traveller who still needs a seat.
    final next = ref.read(bookingControllerProvider).nextUnseated;
    if (next != null) setState(() => _activeTraveller = next);
  }

  String _subtitle(BookingDraft draft, PriceBreakdown price) {
    final seated = draft.seats.length;
    if (seated < draft.travellerCount) {
      final name = draft.travellers[draft.nextUnseated!]?.firstName ?? 'traveller ${draft.nextUnseated! + 1}';
      return 'Pick a seat for $name · or skip';
    }
    final fees = price.lines.where((l) => l.label == 'Seats' && l.note == null).fold(0, (sum, l) => sum + l.amount);
    final seats = seated == 1 ? '1 seat' : '$seated seats';
    return fees == 0 ? '$seats · no seat fees' : '$seats · ${Fmt.moneyShort(fees)} seat fees';
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingControllerProvider);
    final price = ref.watch(bookingPriceProvider);
    final extras = ref.watch(tripExtrasProvider);
    final flight = draft.outbound;
    final fare = draft.fare;
    if (flight == null || fare == null) return const NoBookingInProgress();
    final seatMap = ref.watch(seatMapProvider(flight));
    final travellers = draft.travellers.whereType<Passenger>().toList();
    final active = _activeTraveller.clamp(0, draft.travellerCount - 1);

    return BookingScaffold(
      title: 'Choose Seats',
      step: 2,
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      trailing: SysflyHeaderTextAction(
        label: 'Skip',
        onTap: () {
          // Seats are then assigned at check-in.
          ref.read(bookingControllerProvider.notifier).clearSeats();
          context.push(Routes.review);
        },
      ),
      bottomBar: SysflyBottomBar(
        title: Fmt.money(price.total),
        subtitle: _subtitle(draft, price),
        action: BookingContinueButton(onPressed: draft.allSeated ? () => context.push(Routes.review) : null),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SysflySpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrText(
                'Your flight · ${Fmt.dayMonth(flight.departure)}, ${Fmt.time(flight.departure)} · ${flight.number}',
                style: SysflyTypography.caption.copyWith(fontSize: 11.5),
              ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: TrText('${flight.origin.code}–${flight.destination.code}', style: SysflyTypography.headline),
              ),
              const SizedBox(height: 4),
              TrText('${flight.aircraft} · ${flight.cabin.label}', style: SysflyTypography.bodySecondary),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < travellers.length; i++)
                    _TravellerChip(
                      passenger: travellers[i],
                      seat: draft.seats[i]?.id,
                      active: i == active,
                      onTap: () => setState(() => _activeTraveller = i),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: SysflyColors.chip, borderRadius: BorderRadius.circular(SysflyRadius.md)),
                child: Row(
                  children: [
                    const SysflyIcon(SysflyIcons.info, size: 16, color: SysflyColors.link),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TrText(
                        fare.includesStandardSeat
                            ? 'Standard seats are included with ${fare.name}. Extra legroom is '
                                '${Fmt.moneyShort(seatMap.valueOrNull?.extraLegroomPrice ?? 18)}.'
                            : 'Standard seats are ${Fmt.moneyShort(seatMap.valueOrNull?.standardPrice ?? 6)} with ${fare.name}. '
                                'Extra legroom is ${Fmt.moneyShort(seatMap.valueOrNull?.extraLegroomPrice ?? 18)}. '
                                'Skip to get a free seat at check-in.',
                        style: SysflyTypography.body.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF2B2D3A)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
        seatMap.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: SysflyPlaneSpinner(size: 64)),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(32),
            child: TrText('The seat map could not be loaded. Skip to get a seat at check-in.', style: SysflyTypography.bodySecondary),
          ),
          data: (map) => _cabin(map, draft),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SysflySpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SysflySectionHeader(title: 'Extras for the trip', subtitle: 'Added for every flight of the trip'),
              const SizedBox(height: 14),
              for (final extra in extras)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExtraTile(
                    extra: extra,
                    selected: draft.extraIds.contains(extra.id),
                    onTap: () => ref.read(bookingControllerProvider.notifier).toggleExtra(extra.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cabin(SeatMap map, BookingDraft draft) {
    final pages = (map.rows / _rowsPerPage).ceil();
    final page = _page.clamp(0, pages - 1);
    final from = page * _rowsPerPage + 1;
    final to = (from + _rowsPerPage - 1).clamp(1, map.rows);
    final selected = {
      for (final entry in draft.seats.entries) entry.value.id: draft.travellers[entry.key]?.initials ?? '${entry.key + 1}',
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SysflySpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrText('Rows $from–$to', style: SysflyTypography.section),
                        const SizedBox(height: 3),
                        TrText(
                          '${page == 0 ? 'Front' : 'Rear'} cabin · ${map.freeIn(from, to)} of ${map.totalIn(from, to)} free',
                          style: SysflyTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < pages; i++) ...[
                    const SizedBox(width: 8),
                    _PageButton(
                      label: '${i + 1}',
                      selected: i == page,
                      semanticLabel: 'Rows ${i * _rowsPerPage + 1} to ${((i + 1) * _rowsPerPage).clamp(1, map.rows)}',
                      onTap: () => setState(() => _page = i),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              SysflySeatLegend(extraLegroomPrice: map.extraLegroomPrice),
              const SizedBox(height: 18),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: SysflyMotion.normal,
          child: SysflySeatMap(
            key: ValueKey('cabin-$page'),
            map: map,
            fromRow: from,
            toRow: to,
            showNose: page == 0,
            selected: selected,
            onSeatTap: (seat) => _onSeat(seat, map, draft),
          ),
        ),
        if (pages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SysflyOutlineButton(
              label: page < pages - 1
                  ? 'Rows ${to + 1}–${(to + _rowsPerPage).clamp(1, map.rows)}'
                  : 'Rows 1–$_rowsPerPage',
              icon: page < pages - 1 ? SysflyIcons.chevronDown : SysflyIcons.chevronLeft,
              height: 32,
              dense: true,
              foreground: SysflyColors.royalText,
              onPressed: () => setState(() => _page = page < pages - 1 ? page + 1 : 0),
            ),
          ),
      ],
    );
  }
}

class _TravellerChip extends StatelessWidget {
  const _TravellerChip({required this.passenger, required this.seat, required this.active, required this.onTap});

  final Passenger passenger;
  final String? seat;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: '${passenger.firstName}, ${seat == null ? 'no seat yet' : 'seat $seat'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!active) SysflyHaptics.selection();
          onTap();
        },
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: SysflyMotion.normal,
            curve: SysflyMotion.standard,
            padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
            decoration: BoxDecoration(
              color: active ? SysflyColors.selected : SysflyColors.surface,
              borderRadius: SysflyRadius.pillAll,
              border: Border.all(color: active ? SysflyColors.selected : SysflyColors.fieldBorder),
              boxShadow: active ? null : SysflyShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SysflyInitials(
                  initials: passenger.initials,
                  size: 38,
                  background: active ? SysflyColors.surface : SysflyColors.tile,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TrText(
                      passenger.firstName,
                      style: SysflyTypography.bodyStrong.copyWith(fontSize: 14, color: active ? Colors.white : SysflyColors.textPrimary),
                    ),
                    const SizedBox(height: 1),
                    TrText(
                      seat == null ? 'No seat yet' : 'Seat $seat',
                      style: SysflyTypography.caption.copyWith(
                        fontSize: 11.5,
                        color: active ? const Color(0xCCFFFFFF) : SysflyColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.label, required this.selected, required this.semanticLabel, required this.onTap});

  final String label;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected
            ? null
            : () {
                SysflyHaptics.selection();
                onTap();
              },
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: SysflyMotion.normal,
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? SysflyColors.selected : SysflyColors.surface,
              borderRadius: BorderRadius.circular(SysflyRadius.sm),
              border: Border.all(color: selected ? SysflyColors.selected : SysflyColors.fieldBorder),
            ),
            child: TrText(
              label,
              style: SysflyTypography.bodyStrong.copyWith(fontSize: 14, color: selected ? Colors.white : SysflyColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtraTile extends StatelessWidget {
  const _ExtraTile({required this.extra, required this.selected, required this.onTap});

  final TripExtra extra;
  final bool selected;
  final VoidCallback onTap;

  static const _icons = {'baggage': SysflyIcons.bag, 'flex': SysflyIcons.shield, 'insurance': SysflyIcons.insurance};

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      label: '${extra.title}, ${extra.subtitle}, plus ${Fmt.moneyShort(extra.price)}',
      child: GestureDetector(
        key: ValueKey('extra-${extra.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SysflyHaptics.selection();
          onTap();
        },
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: SysflyMotion.normal,
            curve: SysflyMotion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: SysflyColors.surface,
              borderRadius: BorderRadius.circular(SysflyRadius.lg),
              border: Border.all(color: selected ? SysflyColors.selected : const Color(0xFFEEF0F7), width: selected ? 1.5 : 1),
              boxShadow: SysflyShadows.soft,
            ),
            child: Row(
              children: [
                SysflyIconTile(icon: _icons[extra.id] ?? SysflyIcons.plus, size: 42),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrText(extra.title, style: SysflyTypography.bodyStrong),
                      const SizedBox(height: 3),
                      TrText(extra.subtitle, style: SysflyTypography.caption),
                    ],
                  ),
                ),
                TrText('+${Fmt.moneyShort(extra.price)}', style: SysflyTypography.bodyStrong),
                const SizedBox(width: 12),
                SysflyCheckbox(value: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
