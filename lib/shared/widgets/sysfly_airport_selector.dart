import 'package:flutter/material.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';
import '../models/models.dart';
import 'sysfly_controls.dart';
import 'sysfly_flag.dart';
import 'sysfly_sheet.dart';

/// Searchable, grouped airport list for a bottom sheet.
///
/// With no search text it shows the first [popularCount] airports grouped as
/// given, followed by every other airport by continent. Typing searches the
/// whole list by code, airport, city or country.
class SysflyAirportSelector extends StatefulWidget {
  const SysflyAirportSelector({
    super.key,
    required this.title,
    required this.airports,
    required this.onSelected,
    this.selected,
    this.disabled,
    this.popularCount = 0,
  });

  final String title;
  final List<Airport> airports;
  final ValueChanged<Airport> onSelected;

  /// Currently chosen airport for this field.
  final Airport? selected;

  /// The airport chosen for the other end of the route; it cannot be picked.
  final Airport? disabled;

  /// How many airports at the start of [airports] are the popular ones.
  final int popularCount;

  /// Most results shown for one search.
  static const int maxResults = 80;

  @override
  State<SysflyAirportSelector> createState() => _SysflyAirportSelectorState();
}

class _SysflyAirportSelectorState extends State<SysflyAirportSelector> {
  final _query = TextEditingController();

  /// Headers (String) and airports, in display order.
  List<Object> _items = const [];
  List<Airport>? _itemsFor;
  String _itemsQuery = '\u0000';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(Airport airport, String q) =>
      airport.matches(q) || L10n.country(airport.countryCode).toLowerCase().contains(q);

  /// Flattens groups into one list so it can be built lazily.
  List<Object> _flatten(Map<String, List<Airport>> groups) => [
        for (final entry in groups.entries) ...[
          '${entry.key}\n${entry.value.length == 1 ? '1 airport' : '${entry.value.length} airports'}',
          ...entry.value,
        ],
      ];

  void _rebuildItems() {
    final q = _query.text.trim().toLowerCase();
    if (identical(_itemsFor, widget.airports) && q == _itemsQuery) return;
    _itemsFor = widget.airports;
    _itemsQuery = q;
    final groups = <String, List<Airport>>{};
    if (q.isEmpty) {
      final popular = widget.popularCount.clamp(0, widget.airports.length);
      for (final airport in widget.airports.take(popular)) {
        groups.putIfAbsent(airport.region, () => []).add(airport);
      }
      final rest = <String, List<Airport>>{};
      for (final airport in widget.airports.skip(popular)) {
        rest.putIfAbsent(airport.region, () => []).add(airport);
      }
      for (final name in rest.keys.toList()..sort()) {
        // A continent that already leads the list keeps its popular airports
        // on top and continues below under "… · more".
        groups[groups.containsKey(name) ? '$name · more' : name] = rest[name]!
          ..sort((a, b) => a.country == b.country ? a.city.compareTo(b.city) : a.country.compareTo(b.country));
      }
    } else {
      var count = 0;
      for (final airport in widget.airports) {
        if (!_matches(airport, q)) continue;
        groups.putIfAbsent(airport.region, () => []).add(airport);
        if (++count >= SysflyAirportSelector.maxResults) break;
      }
    }
    _items = _flatten(groups);
  }

  @override
  Widget build(BuildContext context) {
    _rebuildItems();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SysflySheetTitle(title: widget.title),
              const SizedBox(height: 14),
              SysflyTextField(
                controller: _query,
                hint: 'City, airport or country',
                icon: SysflyIcons.search,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: TrText(
                      widget.airports.isEmpty ? 'Loading airports' : 'No airports match your search',
                      textAlign: TextAlign.center,
                      style: SysflyTypography.bodySecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 12, SysflySpacing.page, 24),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    if (item is String) {
                      final parts = item.split('\n');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 10),
                        child: Row(
                          children: [
                            TrText(
                              parts[0],
                              style: SysflyTypography.captionStrong.copyWith(color: SysflyColors.textPrimary, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            TrText(parts[1], style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                          ],
                        ),
                      );
                    }
                    final airport = item as Airport;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AirportRow(
                        airport: airport,
                        selected: airport == widget.selected,
                        enabled: airport != widget.disabled,
                        onTap: () => widget.onSelected(airport),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AirportRow extends StatelessWidget {
  const _AirportRow({required this.airport, required this.selected, required this.enabled, required this.onTap});

  final Airport airport;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final country = L10n.country(airport.countryCode);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: '${airport.name}, ${airport.code}, ${airport.city}, $country',
      child: SysflyPressable(
        onTap: enabled ? onTap : null,
        pressedScale: 0.985,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: SysflyColors.field,
                borderRadius: BorderRadius.circular(SysflyRadius.lg),
                border: Border.all(color: selected ? SysflyColors.selected : SysflyColors.fieldBorder, width: selected ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  SysflyFlag(countryCode: airport.countryCode),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrText(airport.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.bodyStrong.copyWith(fontSize: 14.5)),
                        const SizedBox(height: 3),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: airport.code,
                                style: SysflyTypography.captionStrong.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: '  ·  ${airport.city}, $country'),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SysflyTypography.caption.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  if (selected) const SysflyIcon(SysflyIcons.check, size: 16, color: SysflyColors.selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
