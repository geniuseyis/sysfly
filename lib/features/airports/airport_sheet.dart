import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/airport_catalog.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../home/search_controller.dart';

/// Opens the airport picker and returns the chosen airport, or null when the
/// sheet is dismissed.
Future<Airport?> showAirportSheet(
  BuildContext context, {
  required String title,
  Airport? selected,
  Airport? disabled,
}) {
  return showSysflySheet<Airport>(
    context,
    expand: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final airports = ref.watch(airportsProvider).valueOrNull ?? const <Airport>[];
        return SysflyAirportSelector(
          title: title,
          airports: airports,
          popularCount: AirportCatalog.popularCount,
          selected: selected,
          disabled: disabled,
          onSelected: (airport) => Navigator.of(sheetContext).pop(airport),
        );
      },
    ),
  );
}
