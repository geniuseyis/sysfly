import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import 'flight_filter.dart';

/// Opens "Filter & sort" for [flights] and returns the chosen filter, or
/// null when the sheet is dismissed.
Future<FlightFilter?> showFilterSheet(
  BuildContext context, {
  required List<Flight> flights,
  required FlightFilter current,
  required DateTime date,
  required CabinClass cabin,
}) {
  return showSysflySheet<FlightFilter>(
    context,
    expand: true,
    builder: (_) => FilterSheet(flights: flights, initial: current, date: date, cabin: cabin),
  );
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.flights, required this.initial, required this.date, required this.cabin});

  final List<Flight> flights;
  final FlightFilter initial;
  final DateTime date;
  final CabinClass cabin;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FlightFilter _filter = widget.initial;

  static const _icons = {
    DayPart.morning: SysflyIcons.morning,
    DayPart.afternoon: SysflyIcons.afternoon,
    DayPart.evening: SysflyIcons.evening,
    DayPart.night: SysflyIcons.night,
  };

  void _update(FlightFilter next) {
    SysflyHaptics.selection();
    setState(() => _filter = next);
  }

  @override
  Widget build(BuildContext context) {
    final flights = widget.flights;
    final matching = _filter.apply(flights).length;
    final airlines = airlineFloorPrices(flights);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
            children: [
              SysflySheetTitle(
                title: 'Filter & sort',
                subtitle: '${flights.length} ${flights.length == 1 ? 'flight' : 'flights'} on '
                    '${Fmt.dayShort(widget.date)} · ${widget.cabin.label}',
              ),
              const SizedBox(height: 18),
              TrText('Sort by', style: SysflyTypography.cardTitle.copyWith(fontSize: 15.5)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sort in FlightSort.values)
                    _SortChip(
                      label: sort.label,
                      selected: _filter.sort == sort,
                      onTap: () => _update(_filter.copyWith(sort: sort)),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              TrText('Departure time', style: SysflyTypography.cardTitle.copyWith(fontSize: 15.5)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final part in DayPart.values)
                        SizedBox(
                          width: width,
                          child: _DayPartTile(
                            part: part,
                            icon: _icons[part]!,
                            count: flights.where((f) => f.dayPart == part).length,
                            selected: _filter.dayParts.contains(part),
                            onTap: () => _update(_filter.toggleDayPart(part)),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              TrText('Airlines', style: SysflyTypography.cardTitle.copyWith(fontSize: 15.5)),
              const SizedBox(height: 12),
              for (final (airline, price) in airlines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AirlineTile(
                    airline: airline,
                    price: price,
                    selected: _filter.airlines.contains(airline.code),
                    onTap: () => _update(_filter.toggleAirline(airline.code)),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 12, SysflySpacing.page, 12),
          decoration: const BoxDecoration(
            color: SysflyColors.surface,
            boxShadow: [BoxShadow(color: Color(0x0F181D5A), blurRadius: 16, offset: Offset(0, -6))],
          ),
          child: Row(
            children: [
              SysflyOutlineButton(
                key: const ValueKey('filter-reset'),
                label: 'Reset',
                icon: SysflyIcons.reset,
                height: 54,
                onPressed: _filter.isDefault ? null : () => _update(const FlightFilter()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SysflyGradientButton(
                  key: const ValueKey('filter-apply'),
                  label: matching == 0
                      ? 'No flights match'
                      : 'Show $matching ${matching == 1 ? 'flight' : 'flights'}',
                  onPressed: matching == 0 ? null : () => Navigator.of(context).pop(_filter),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Sort by $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected ? null : onTap,
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: SysflyMotion.normal,
            curve: SysflyMotion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? SysflyColors.selected : SysflyColors.surface,
              borderRadius: SysflyRadius.pillAll,
              border: Border.all(color: selected ? SysflyColors.selected : SysflyColors.fieldBorder, width: 1.2),
              boxShadow: selected ? null : SysflyShadows.soft,
            ),
            child: TrText(
              label,
              style: SysflyTypography.chip.copyWith(fontSize: 13, color: selected ? Colors.white : SysflyColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayPartTile extends StatelessWidget {
  const _DayPartTile({required this.part, required this.icon, required this.count, required this.selected, required this.onTap});

  final DayPart part;
  final SysflyIconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: '${part.label}, ${part.range}, $count ${count == 1 ? 'flight' : 'flights'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: SysflyFieldBox(
              selected: selected,
              color: selected ? SysflyColors.chip : SysflyColors.field,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  SysflyIcon(icon, size: 19, color: selected ? SysflyColors.link : SysflyColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrText(part.label, style: SysflyTypography.bodyStrong.copyWith(fontSize: 14)),
                        const SizedBox(height: 2),
                        TrText('${part.range} · $count', style: SysflyTypography.caption.copyWith(fontSize: 11)),
                      ],
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

class _AirlineTile extends StatelessWidget {
  const _AirlineTile({required this.airline, required this.price, required this.selected, required this.onTap});

  final Airline airline;
  final int price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${airline.name}, from ${Fmt.moneyShort(price)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: SysflyFieldBox(
            selected: selected,
            color: selected ? SysflyColors.chip : SysflyColors.field,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
            child: Row(
              children: [
                SysflyIcon(SysflyIcons.planeOutline, size: 19, color: selected ? SysflyColors.link : SysflyColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(child: TrText(airline.name, style: SysflyTypography.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600))),
                TrText('from ${Fmt.moneyShort(price)}', style: SysflyTypography.bodyStrong.copyWith(fontSize: 13.5)),
                AnimatedSize(
                  duration: SysflyMotion.normal,
                  child: selected
                      ? const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: SysflyIcon(SysflyIcons.check, size: 15, color: SysflyColors.selected),
                        )
                      : const SizedBox(height: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
