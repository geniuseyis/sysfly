import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../booking/booking_controller.dart';
import '../flight_filters/filter_sheet.dart';
import '../flight_filters/flight_filter.dart';
import '../home/search_controller.dart';
import '../home/widgets/search_sheets.dart';
import 'flight_search_providers.dart';
import 'widgets/route_hero.dart';

/// Search results for one leg of the trip: route hero, a week of dates,
/// and the matching flights as tickets.
class FlightResultsScreen extends ConsumerStatefulWidget {
  const FlightResultsScreen({super.key, this.leg = SearchLeg.outbound});

  final SearchLeg leg;

  @override
  ConsumerState<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends ConsumerState<FlightResultsScreen> {
  /// First day of the date strip; fixed so the strip does not jump when a
  /// later day is picked.
  late DateTime _stripStart;

  bool get _inbound => widget.leg == SearchLeg.inbound;

  DateTime _dateOf(SearchQuery query) => _inbound ? (query.returnDate ?? query.departDate) : query.departDate;

  @override
  void initState() {
    super.initState();
    _stripStart = _dateOf(ref.read(searchControllerProvider));
  }

  void _setDate(DateTime date) {
    final controller = ref.read(searchControllerProvider.notifier);
    if (_inbound) {
      controller.setReturnDate(date);
    } else {
      final query = ref.read(searchControllerProvider);
      final keepsRoundTrip = query.isRoundTrip && query.returnDate != null && !query.returnDate!.isBefore(date);
      controller.setDepartDate(date);
      // Moving the outbound past the return date pushes the return out too.
      if (query.isRoundTrip && !keepsRoundTrip) controller.setReturnDate(date.add(const Duration(days: 1)));
    }
  }

  Future<void> _openCalendar(SearchQuery query) async {
    final today = Fmt.dateOnly(ref.read(clockProvider).now());
    await showSysflySheet<void>(
      context,
      builder: (sheetContext) => SysflyDatePicker(
        title: _inbound ? 'Return date' : 'Departure date',
        today: today,
        firstDate: _inbound ? query.departDate : today,
        lastDate: today.add(const Duration(days: 330)),
        initial: _dateOf(query),
        rangeStart: _inbound ? query.departDate : null,
        onConfirm: (date) {
          setState(() => _stripStart = date);
          _setDate(date);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Future<void> _openFilters(List<Flight> flights, SearchQuery query) async {
    final result = await showFilterSheet(
      context,
      flights: flights,
      current: ref.read(flightFilterProvider),
      date: _dateOf(query),
      cabin: query.cabin,
    );
    if (result != null) ref.read(flightFilterProvider.notifier).set(result);
  }

  void _choose(Flight flight, SearchQuery query) {
    if (!_inbound && query.isRoundTrip) {
      ref.read(outboundSelectionProvider.notifier).set(flight);
      ref.read(flightFilterProvider.notifier).reset();
      context.push('${Routes.results}?leg=inbound');
      return;
    }
    final outbound = _inbound ? ref.read(outboundSelectionProvider) : flight;
    if (outbound == null) {
      context.pop();
      return;
    }
    ref.read(bookingControllerProvider.notifier).start(
          outbound: outbound,
          inbound: _inbound ? flight : null,
          passengers: query.passengers,
        );
    context.push(Routes.fare);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchControllerProvider);
    final filter = ref.watch(flightFilterProvider);
    final results = ref.watch(flightResultsProvider(widget.leg));
    final origin = _inbound ? query.destination : query.origin;
    final destination = _inbound ? query.origin : query.destination;
    final date = _dateOf(query);
    final all = results.valueOrNull ?? const <Flight>[];
    final shown = filter.apply(all);
    final airlineCount = shown.map((f) => f.airline).toSet().length;
    final typical = all.isEmpty ? null : all.first.duration;
    final today = Fmt.dateOnly(ref.watch(clockProvider).now());

    return Scaffold(
      backgroundColor: SysflyColors.background,
      body: Column(
        children: [
          RouteHero(
            title: _inbound ? 'Return Flight' : (query.isRoundTrip ? 'Outbound Flight' : 'Select Flight'),
            origin: origin,
            destination: destination,
            date: date,
            duration: typical,
            onBack: () => context.pop(),
            filterBadge: filter.activeCount > 0,
            onFilter: all.isEmpty ? null : () => _openFilters(all, query),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 18, 0, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SysflySpacing.page),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: SysflyColors.selected, shape: BoxShape.circle),
                        child: TrText(
                          _inbound ? '2' : '1',
                          style: SysflyTypography.chip.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TrText(
                          '${_inbound ? 'Choose return' : (query.isRoundTrip ? 'Choose outbound' : 'Choose flight')} · '
                          '${origin.code} → ${destination.code}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SysflyTypography.bodyStrong,
                        ),
                      ),
                      if (query.isRoundTrip) TrText('${_inbound ? 2 : 1} of 2', style: SysflyTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SysflySpacing.page),
                  child: SysflySectionHeader(title: 'Flight Date', action: 'Calendar', onAction: () => _openCalendar(query)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: SysflySpacing.page),
                    itemCount: 7,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final day = _stripStart.add(Duration(days: i));
                      final allowed = !day.isBefore(_inbound ? query.departDate : today);
                      return _DateChip(
                        date: day,
                        selected: Fmt.sameDay(day, date),
                        enabled: allowed,
                        onTap: () => _setDate(day),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SysflySpacing.page),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: TrText(
                            results.isLoading
                                ? 'Finding flights'
                                : '$airlineCount ${airlineCount == 1 ? 'Airline' : 'Airlines'}',
                            style: SysflyTypography.section,
                          ),
                        ),
                      ),
                      SysflyOutlineButton(
                        label: query.cabin.label,
                        icon: SysflyIcons.cabin,
                        height: 36,
                        dense: true,
                        onPressed: () async {
                          final cabin = await showCabinSheet(context, current: query.cabin);
                          if (cabin != null) ref.read(searchControllerProvider.notifier).setCabin(cabin);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SysflySpacing.page),
                  child: AnimatedSwitcher(
                    duration: SysflyMotion.normal,
                    layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                    child: results.isLoading
                        ? const Padding(
                            key: ValueKey('results-loading'),
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: SysflyPlaneSpinner(size: 64)),
                          )
                        : shown.isEmpty
                            ? _NoFlights(
                                key: const ValueKey('results-empty'),
                                filtered: all.isNotEmpty,
                                onReset: () => ref.read(flightFilterProvider.notifier).reset(),
                              )
                            : Column(
                                key: ValueKey('results-${Fmt.dayShort(date)}-${origin.code}-${filter.hashCode}'),
                                children: [
                                  for (final flight in shown)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: SysflyFlightTicket(
                                        key: ValueKey('flight-${flight.id}'),
                                        flight: flight,
                                        details: [
                                          TicketDetail('FLIGHT', flight.number),
                                          TicketDetail('CLASS', flight.cabin.label),
                                          TicketDetail('SEATS', '${flight.seatsLeft} left'),
                                        ],
                                        stub: TicketFareStub(label: 'FARE', price: flight.basePrice, barcode: flight.id),
                                        onTap: () => _choose(flight, query),
                                      ),
                                    ),
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

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.selected, required this.enabled, required this.onTap});

  final DateTime date;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: Fmt.dayShort(date),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled && !selected
            ? () {
                SysflyHaptics.selection();
                onTap();
              }
            : null,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: AnimatedContainer(
              duration: SysflyMotion.normal,
              curve: SysflyMotion.standard,
              width: 51,
              decoration: BoxDecoration(
                color: selected ? SysflyColors.selected : SysflyColors.surface,
                borderRadius: BorderRadius.circular(SysflyRadius.md),
                border: Border.all(color: selected ? SysflyColors.selected : SysflyColors.fieldBorder),
                boxShadow: selected ? null : SysflyShadows.soft,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TrText(
                    Fmt.weekday(date),
                    style: SysflyTypography.caption.copyWith(fontSize: 11.5, color: selected ? const Color(0xCCFFFFFF) : SysflyColors.textTertiary),
                  ),
                  const SizedBox(height: 3),
                  TrText(
                    '${date.day}',
                    style: SysflyTypography.cardTitle.copyWith(fontSize: 17, color: selected ? Colors.white : SysflyColors.textPrimary),
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

class _NoFlights extends StatelessWidget {
  const _NoFlights({super.key, required this.filtered, required this.onReset});

  /// True when flights exist but the filters hide them all.
  final bool filtered;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const SysflyIconTile(icon: SysflyIcons.planeOutline, size: 56),
          const SizedBox(height: 14),
          TrText(
            filtered ? 'No flights match your filters' : 'No flights on this route for the day',
            style: SysflyTypography.bodySecondary,
          ),
          if (filtered) ...[
            const SizedBox(height: 16),
            SysflyOutlineButton(label: 'Reset filters', icon: SysflyIcons.reset, onPressed: onReset),
          ],
        ],
      ),
    );
  }
}
