import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../shared/models/models.dart';
import '../generated/country_names.dart';
import '../mock/demo_catalog.dart';

/// Every airport with scheduled service and an IATA code (about 4,000 in 233
/// countries), read from `assets/data/airports.tsv`.
///
/// The hand-picked airports of [DemoCatalog] come first, so they lead the
/// picker as "popular" choices. See `tool/build_airport_data.js` for where
/// the data comes from.
abstract final class AirportCatalog {
  static const _continents = {
    'AF': 'Africa',
    'AN': 'Antarctica',
    'AS': 'Asia',
    'EU': 'Europe',
    'NA': 'North America',
    'OC': 'Oceania',
    'SA': 'South America',
  };

  static List<Airport>? _cache;

  /// Number of hand-picked airports at the start of the list.
  static int get popularCount => DemoCatalog.airports.length;

  static Future<List<Airport>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final all = <Airport>[...DemoCatalog.airports];
    final known = {for (final a in all) a.code};
    try {
      // Decoded here rather than with loadString, which hands large files to
      // another isolate.
      final data = await rootBundle.load('assets/data/airports.tsv');
      final text = utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      for (final line in const LineSplitter().convert(text)) {
        final f = line.split('\t');
        if (f.length < 8 || known.contains(f[0])) continue;
        all.add(
          Airport(
            code: f[0],
            name: f[1],
            city: f[2],
            country: kCountryNames[f[3]]?.first ?? f[3],
            countryCode: f[3],
            region: _continents[f[4]] ?? 'Other',
            latitude: double.parse(f[5]),
            longitude: double.parse(f[6]),
            utcOffsetHours: double.parse(f[7]),
          ),
        );
      }
    } on FlutterError catch (error) {
      // Without the asset the app still works with the hand-picked airports.
      debugPrint('Airport catalogue unavailable: $error');
    }
    return _cache = List.unmodifiable(all);
  }
}
