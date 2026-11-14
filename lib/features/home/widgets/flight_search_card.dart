import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/services/haptics.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../airports/airport_sheet.dart';
import '../../flight_filters/flight_filter.dart';
import '../search_controller.dart';
import 'search_sheets.dart';

/// The flight search form on the home screen.
class FlightSearchCard extends ConsumerStatefulWidget {
  const FlightSearchCard({super.key});

  @override
  ConsumerState<FlightSearchCard> createState() => _FlightSearchCardState();
}

class _FlightSearchCardState extends ConsumerState<FlightSearchCard> {
  int _swaps = 0;

  FlightSearchController get _controller => ref.read(searchControllerProvider.notifier);

  Future<void> _pickOrigin(SearchQuery query) async {
    final airport = await showAirportSheet(context, title: 'Flying from', selected: query.origin);
    if (airport != null) _controller.setOrigin(airport);
  }

  Future<void> _pickDestination(SearchQuery query) async {
    final airport = await showAirportSheet(context, title: 'Flying to', selected: query.destination);
    if (airport != null) _controller.setDestination(airport);
  }

  Future<void> _pickDeparture(SearchQuery query) async {
    final today = Fmt.dateOnly(ref.read(clockProvider).now());
    await showSysflySheet<void>(
      context,
      builder: (sheetContext) => SysflyDatePicker(
        title: 'Departure date',
        today: today,
        firstDate: today,
        lastDate: today.add(const Duration(days: 330)),
        initial: query.departDate,
        onConfirm: (date) {
          _controller.setDepartDate(date);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Future<void> _pickReturn(SearchQuery query) async {
    final today = Fmt.dateOnly(ref.read(clockProvider).now());
    await showSysflySheet<void>(
      context,
      builder: (sheetContext) => SysflyDatePicker(
        title: 'Return date',
        today: today,
        firstDate: query.departDate,
        lastDate: today.add(const Duration(days: 330)),
        initial: query.returnDate,
        rangeStart: query.departDate,
        onConfirm: (date) {
          _controller.setReturnDate(date);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  void _onTripType(int index, SearchQuery query) {
    final type = TripType.values[index];
    if (type == TripType.multiCity) {
      showDemoNotice(
        context,
        title: 'Multi-city',
        message: 'Multi-city itineraries are not part of this demo build yet. One way and round trip are fully bookable.',
      );
      return;
    }
    _controller.setTripType(type);
    if (type == TripType.roundTrip && query.returnDate == null) _pickReturn(query);
  }

  void _search(SearchQuery query) {
    final problem = query.problem;
    if (problem != null) {
      showSysflyToast(context, problem, error: true);
      if (query.isRoundTrip && query.returnDate == null) _pickReturn(query);
      return;
    }
    ref.read(flightFilterProvider.notifier).reset();
    context.push(Routes.results);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchControllerProvider);
    return SysflyCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SysflySegmentedControl(
            labels: [for (final t in TripType.values) t.label],
            index: query.tripType.index,
            onChanged: (i) => _onTripType(i, query),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _AirportBox(
                        label: 'From',
                        airport: query.origin,
                        alignEnd: false,
                        onTap: () => _pickOrigin(query),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AirportBox(
                        label: 'To',
                        airport: query.destination,
                        alignEnd: true,
                        onTap: () => _pickDestination(query),
                      ),
                    ),
                  ],
                ),
                Semantics(
                  button: true,
                  label: 'Swap airports',
                  child: SysflyPressable(
                    onTap: () {
                      setState(() => _swaps++);
                      _controller.swap();
                    },
                    pressedScale: 0.88,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SysflyGradients.indicator,
                        border: Border.all(color: SysflyColors.surface, width: 3),
                      ),
                      child: AnimatedRotation(
                        turns: _swaps / 2,
                        duration: SysflyMotion.slow,
                        curve: SysflyMotion.emphasized,
                        child: const SysflyIcon(SysflyIcons.swap, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SplitBox(
            left: _FieldCell(
              icon: SysflyIcons.calendar,
              label: 'Departure',
              value: Fmt.dayShort(query.departDate),
              trailing: const SysflyIcon(SysflyIcons.chevronDown, size: 14, color: SysflyColors.textTertiary),
              onTap: () => _pickDeparture(query),
            ),
            right: _FieldCell(
              icon: SysflyIcons.returnTrip,
              label: 'Return',
              value: query.returnDate == null ? 'Add date' : Fmt.dayShort(query.returnDate!),
              placeholder: query.returnDate == null,
              trailing: query.returnDate == null
                  ? const _RoundGlyph(icon: SysflyIcons.plus)
                  : Semantics(
                      button: true,
                      label: 'Remove return date',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          SysflyHaptics.selection();
                          _controller.setTripType(TripType.oneWay);
                        },
                        child: const _RoundGlyph(icon: SysflyIcons.close),
                      ),
                    ),
              onTap: () => _pickReturn(query),
            ),
          ),
          const SizedBox(height: 12),
          _SplitBox(
            left: _FieldCell(
              icon: SysflyIcons.passengers,
              label: 'Passenger',
              value: query.passengerLabel,
              trailing: const SysflyIcon(SysflyIcons.chevronDown, size: 14, color: SysflyColors.textTertiary),
              onTap: () async {
                final count = await showPassengerSheet(context, current: query.passengers);
                if (count != null) _controller.setPassengers(count);
              },
            ),
            right: _FieldCell(
              icon: SysflyIcons.cabin,
              label: 'Class',
              value: query.cabin.label,
              trailing: const SysflyIcon(SysflyIcons.chevronDown, size: 14, color: SysflyColors.textTertiary),
              onTap: () async {
                final cabin = await showCabinSheet(context, current: query.cabin);
                if (cabin != null) _controller.setCabin(cabin);
              },
            ),
          ),
          const SizedBox(height: 18),
          SysflyGradientButton(
            key: const ValueKey('search-flight'),
            label: 'Search Flight',
            icon: SysflyIcons.search,
            onPressed: () => _search(query),
          ),
        ],
      ),
    );
  }
}

class _AirportBox extends StatelessWidget {
  const _AirportBox({required this.label, required this.airport, required this.alignEnd, required this.onTap});

  final String label;
  final Airport airport;
  final bool alignEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Semantics(
      button: true,
      label: '$label ${airport.city}, ${airport.name}, ${airport.code}',
      child: SysflyPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: ExcludeSemantics(
          child: SysflyFieldBox(
            radius: 22,
            padding: EdgeInsets.fromLTRB(alignEnd ? 24 : 15, 12, alignEnd ? 15 : 24, 10),
            child: AnimatedSwitcher(
              duration: SysflyMotion.normal,
              switchInCurve: SysflyMotion.enter,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: Offset(alignEnd ? -0.12 : 0.12, 0), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: SizedBox(
                key: ValueKey(airport.code),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: align,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TrText(label, style: SysflyTypography.fieldLabel),
                    const SizedBox(height: 2),
                    TrText(airport.code, style: SysflyTypography.airportCode.copyWith(fontSize: 30)),
                    const SizedBox(height: 1),
                    TrText(
                      airport.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SysflyTypography.body.copyWith(fontSize: 14.5, color: SysflyColors.textBody),
                    ),
                    const SizedBox(height: 1),
                    TrText(
                      airport.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SysflyTypography.caption.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One rounded box holding two fields separated by a hairline.
class _SplitBox extends StatelessWidget {
  const _SplitBox({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return SysflyFieldBox(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            Expanded(child: left),
            const SizedBox(height: 34, child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E5EF))),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }
}

class _FieldCell extends StatelessWidget {
  const _FieldCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.trailing,
    required this.onTap,
    this.placeholder = false,
  });

  final SysflyIconData icon;
  final String label;
  final String value;
  final Widget trailing;
  final VoidCallback onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $value',
      child: SysflyPressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SysflyIcon(icon, size: 13, color: SysflyColors.textTertiary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: TrText(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.fieldLabel),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TrText(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: placeholder
                            ? SysflyTypography.fieldValue.copyWith(fontWeight: FontWeight.w500, color: SysflyColors.textTertiary)
                            : SysflyTypography.fieldValue,
                      ),
                    ],
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundGlyph extends StatelessWidget {
  const _RoundGlyph({required this.icon});

  final SysflyIconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(color: SysflyColors.tile, shape: BoxShape.circle),
      child: SysflyIcon(icon, size: 12, color: SysflyColors.link),
    );
  }
}
