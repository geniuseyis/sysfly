import 'package:flutter/material.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';
import '../models/models.dart';
import 'sysfly_controls.dart';
import 'sysfly_flag.dart';
import 'sysfly_sheet.dart';

/// Searchable airport list for a bottom sheet, organised by country.
///
/// With no search text it shows the first [popularCount] airports grouped by
/// region, then every country with its number of airports; tapping a
/// country lists only its airports. Typing searches the whole catalogue and
/// shows matching countries first, then airports under their country.
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

/// A country in the list: its code and how many airports it has.
class _CountryItem {
  const _CountryItem(this.code, this.count);
  final String code;
  final int count;
}

/// Section title with a count, e.g. "Asia · 9 airports".
class _Header {
  const _Header(this.title, this.count, {this.unit = 'airport'});
  final String title;
  final int count;
  final String unit;
}

class _SysflyAirportSelectorState extends State<SysflyAirportSelector> {
  final _query = TextEditingController();
  final _scroll = ScrollController();

  /// Country being browsed, or null for the overview.
  String? _country;

  /// Airports by country code, built once per catalogue.
  Map<String, List<Airport>> _byCountry = const {};
  List<Airport>? _indexedFor;

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _index() {
    if (identical(_indexedFor, widget.airports)) return;
    _indexedFor = widget.airports;
    final map = <String, List<Airport>>{};
    for (final airport in widget.airports) {
      map.putIfAbsent(airport.countryCode, () => []).add(airport);
    }
    // Catalogue order is kept: popular airports, then large, medium and small.
    _byCountry = map;
  }

  bool _matches(Airport airport, String q) =>
      airport.matches(q) || L10n.country(airport.countryCode).toLowerCase().contains(q);

  List<_CountryItem> _countries(Iterable<String> codes) {
    final list = [for (final code in codes) _CountryItem(code, _byCountry[code]?.length ?? 0)];
    list.sort((a, b) => _sortKey(L10n.country(a.code)).compareTo(_sortKey(L10n.country(b.code))));
    return list;
  }

  /// Folds accented Latin letters onto their base letter so "Çad" sorts
  /// with C and "Österreich" with O.
  static String _sortKey(String name) {
    const from = 'çğıiöşüâêîôûàèìòùáéíóúäëïöüñåøæœÇĞIİÖŞÜÂÊÎÔÛÀÈÌÒÙÁÉÍÓÚÄËÏÖÜÑÅØÆŒ';
    const to = 'cgiiosuaeiouaeiouaeiouaeiounaoaoCGIIOSUAEIOUAEIOUAEIOUAEIOUNAOAO';
    final out = StringBuffer();
    for (final ch in name.split('')) {
      final i = from.indexOf(ch);
      out.write(i >= 0 ? to[i] : ch);
    }
    return out.toString().toLowerCase();
  }

  void _open(String? country) {
    setState(() => _country = country);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// Rows in display order: [_Header], [_CountryItem] or [Airport].
  List<Object> _items() {
    final q = _query.text.trim().toLowerCase();

    if (q.isNotEmpty) {
      // Matching countries first, then matching airports under their country.
      final countries = _countries(_byCountry.keys.where((c) => L10n.country(c).toLowerCase().contains(q)));
      final airports = <String, List<Airport>>{};
      var count = 0;
      for (final airport in widget.airports) {
        if (!_matches(airport, q)) continue;
        airports.putIfAbsent(airport.countryCode, () => []).add(airport);
        if (++count >= SysflyAirportSelector.maxResults) break;
      }
      return [
        if (countries.isNotEmpty) ...[_Header('Countries', countries.length, unit: 'country'), ...countries.take(6)],
        for (final entry in airports.entries) ...[_Header(L10n.country(entry.key), entry.value.length), ...entry.value],
      ];
    }

    final country = _country;
    if (country != null) {
      final airports = _byCountry[country] ?? const <Airport>[];
      return [_Header(L10n.country(country), airports.length), ...airports];
    }

    // Overview: the popular airports as in the reference, then every country.
    final popular = <String, List<Airport>>{};
    for (final airport in widget.airports.take(widget.popularCount.clamp(0, widget.airports.length))) {
      popular.putIfAbsent(airport.region, () => []).add(airport);
    }
    return [
      for (final entry in popular.entries) ...[_Header(entry.key, entry.value.length), ...entry.value],
      if (_byCountry.isNotEmpty) ...[
        _Header('All countries', _byCountry.length, unit: 'country'),
        ..._countries(_byCountry.keys),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    _index();
    final items = _items();
    final browsing = _country != null && _query.text.trim().isEmpty;
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
          child: items.isEmpty
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
                  controller: _scroll,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 12, SysflySpacing.page, 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is _Header) {
                      return _SectionHeader(
                        header: item,
                        onBack: browsing && index == 0 ? () => _open(null) : null,
                      );
                    }
                    if (item is _CountryItem) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CountryRow(
                          country: item,
                          onTap: () {
                            _query.clear();
                            FocusScope.of(context).unfocus();
                            _open(item.code);
                          },
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.header, this.onBack});

  final _Header header;

  /// Set while browsing one country: returns to the country list.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final count = header.count == 1 ? '1 ${header.unit}' : '${header.count} ${header.unit == 'country' ? 'countries' : 'airports'}';
    final title = Row(
      children: [
        if (onBack != null) ...[
          const SysflyIcon(SysflyIcons.chevronLeft, size: 16, color: SysflyColors.link),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: TrText(
            header.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SysflyTypography.captionStrong.copyWith(color: SysflyColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 6),
        TrText(count, style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: onBack == null
          ? title
          : Semantics(
              button: true,
              label: tr('All countries'),
              child: SysflyPressable(
                key: const ValueKey('airport-country-back'),
                onTap: onBack,
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: ExcludeSemantics(child: title)),
              ),
            ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({required this.country, required this.onTap});

  final _CountryItem country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = L10n.country(country.code);
    final count = country.count == 1 ? '1 airport' : '${country.count} airports';
    return Semantics(
      button: true,
      label: '$name, ${tr(count)}',
      child: SysflyPressable(
        key: ValueKey('airport-country-${country.code}'),
        onTap: onTap,
        pressedScale: 0.985,
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SysflyColors.surface,
              borderRadius: BorderRadius.circular(SysflyRadius.lg),
              border: Border.all(color: SysflyColors.fieldBorder),
            ),
            child: Row(
              children: [
                SysflyFlag(countryCode: country.code, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.bodyStrong.copyWith(fontSize: 14.5)),
                ),
                TrText(count, style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                const SizedBox(width: 8),
                const SysflyIcon(SysflyIcons.chevronRight, size: 14, color: SysflyColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
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
