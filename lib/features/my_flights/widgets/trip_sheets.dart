import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/mock/demo_catalog.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../booking/booking_controller.dart';

/// Full boarding pass with its scannable code, shown after check-in.
Future<void> showBoardingPassSheet(BuildContext context, {required Trip trip, required int leg, required int traveller}) {
  final tripLeg = trip.legs[leg];
  final passenger = trip.passengers[traveller];
  return showSysflySheet<void>(
    context,
    builder: (sheetContext) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SysflySheetTitle(
            title: 'Boarding pass',
            subtitle: '${tripLeg.flight.number} · ${Fmt.dayShort(tripLeg.flight.departure)} · Terminal ${tripLeg.terminal}',
          ),
          const SizedBox(height: 16),
          SysflyBoardingPass(leg: tripLeg, passenger: passenger, traveller: traveller),
          const SizedBox(height: 16),
          SysflyFieldBox(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              children: [
                SizedBox(height: 64, child: SysflyBarcode(data: '${trip.reference}${tripLeg.flight.id}$traveller')),
                const SizedBox(height: 10),
                TrText(
                  '${trip.reference} · ${passenger.shortName.toUpperCase()}',
                  style: SysflyTypography.overline.copyWith(fontSize: 10.5, color: SysflyColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TrText(
            'Demo boarding pass · not valid for travel',
            textAlign: TextAlign.center,
            style: SysflyTypography.caption.copyWith(fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          SysflyGradientButton(label: 'Done', onPressed: () => Navigator.of(sheetContext).pop()),
        ],
      ),
    ),
  );
}

/// Confirms adding a checked bag. Returns true when confirmed.
Future<bool?> showAddBaggageSheet(BuildContext context, {required Trip trip}) {
  final bag = DemoCatalog.extras.first;
  final total = bag.price * trip.passengers.length;
  return showSysflySheet<bool>(
    context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SysflySheetTitle(title: bag.title, subtitle: '${bag.subtitle} for every flight of the trip'),
          const SizedBox(height: 16),
          SysflyFieldBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const SysflyIconTile(icon: SysflyIcons.bag, size: 42),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrText(trip.travellerLabel, style: SysflyTypography.bodyStrong),
                      const SizedBox(height: 2),
                      TrText('${Fmt.moneyShort(bag.price)} per traveller', style: SysflyTypography.caption),
                    ],
                  ),
                ),
                TrText(Fmt.money(total), style: SysflyTypography.cardTitle),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TrText(
            'Demo: nothing is charged to ${trip.paymentLabel.isEmpty ? 'your card' : trip.paymentLabel}',
            textAlign: TextAlign.center,
            style: SysflyTypography.caption.copyWith(fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          SysflyGradientButton(
            key: const ValueKey('confirm-baggage'),
            label: 'Add for ${Fmt.money(total)}',
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      ),
    ),
  );
}

/// Confirms cancelling a booking. Returns true when confirmed.
Future<bool?> showCancelTripSheet(BuildContext context, {required Trip trip}) {
  const fee = 35;
  final refund = (trip.totalPaid - fee * trip.passengers.length).clamp(0, trip.totalPaid);
  return showSysflySheet<bool>(
    context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SysflySheetTitle(
            title: 'Cancel this booking?',
            subtitle: '${trip.reference} · ${trip.firstLeg.flight.origin.code} → ${trip.firstLeg.flight.destination.code} · '
                '${Fmt.dayShort(trip.firstLeg.flight.departure)}',
          ),
          const SizedBox(height: 16),
          SysflyFieldBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                _Line(label: 'Paid', value: Fmt.money(trip.totalPaid)),
                const SizedBox(height: 8),
                _Line(label: 'Cancellation fee', value: '-${Fmt.money(fee * trip.passengers.length)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFE4E7F0)),
                ),
                _Line(label: 'Refund', value: Fmt.money(refund), strong: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TrText(
            'Demo: the booking moves to Cancelled and no money moves',
            textAlign: TextAlign.center,
            style: SysflyTypography.caption.copyWith(fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SysflyOutlineButton(
                  label: 'Keep booking',
                  height: 54,
                  expand: true,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Cancel booking',
                  child: SysflyPressable(
                    key: const ValueKey('confirm-cancel'),
                    onTap: () => Navigator.of(sheetContext).pop(true),
                    haptic: PressHaptic.tap,
                    child: ExcludeSemantics(
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: SysflyColors.error, borderRadius: SysflyRadius.pillAll),
                        child: TrText('Cancel booking', style: SysflyTypography.button),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TrText(label, style: strong ? SysflyTypography.bodyStrong : SysflyTypography.bodySecondary.copyWith(fontSize: 13.5)),
        ),
        TrText(value, style: strong ? SysflyTypography.cardTitle : SysflyTypography.bodyStrong.copyWith(fontSize: 13.5)),
      ],
    );
  }
}

/// Seat picker for an existing booking. Returns the chosen seat id.
Future<String?> showChangeSeatSheet(BuildContext context, {required TripLeg leg, required String? current}) {
  return showSysflySheet<String>(context, expand: true, builder: (_) => _ChangeSeatSheet(leg: leg, current: current));
}

class _ChangeSeatSheet extends ConsumerStatefulWidget {
  const _ChangeSeatSheet({required this.leg, required this.current});

  final TripLeg leg;
  final String? current;

  @override
  ConsumerState<_ChangeSeatSheet> createState() => _ChangeSeatSheetState();
}

class _ChangeSeatSheetState extends ConsumerState<_ChangeSeatSheet> {
  static const _rowsPerPage = 16;
  int _page = 0;
  Seat? _picked;

  @override
  Widget build(BuildContext context) {
    final seatMap = ref.watch(seatMapProvider(widget.leg.flight));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 12),
          child: SysflySheetTitle(
            title: 'Change seat',
            subtitle: '${widget.leg.flight.number} · ${widget.current == null ? 'no seat yet' : 'currently ${widget.current}'}',
          ),
        ),
        Expanded(
          child: seatMap.when(
            loading: () => const Center(child: SysflyPlaneSpinner(size: 64)),
            error: (_, _) => Center(child: TrText('The seat map could not be loaded', style: SysflyTypography.bodySecondary)),
            data: (map) {
              final pages = (map.rows / _rowsPerPage).ceil();
              final from = _page * _rowsPerPage + 1;
              final to = (from + _rowsPerPage - 1).clamp(1, map.rows);
              return ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SysflySpacing.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SysflySegmentedControl(
                          labels: [
                            for (var i = 0; i < pages; i++)
                              'Rows ${i * _rowsPerPage + 1}–${((i + 1) * _rowsPerPage).clamp(1, map.rows)}',
                          ],
                          index: _page,
                          onChanged: (i) => setState(() => _page = i),
                        ),
                        const SizedBox(height: 14),
                        SysflySeatLegend(extraLegroomPrice: map.extraLegroomPrice),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  SysflySeatMap(
                    key: ValueKey('change-cabin-$_page'),
                    map: map,
                    fromRow: from,
                    toRow: to,
                    showNose: _page == 0,
                    selected: {if (_picked != null) _picked!.id: '✓'},
                    onSeatTap: (seat) => setState(() => _picked = _picked?.id == seat.id ? null : seat),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 8, SysflySpacing.page, 12),
          child: SysflyGradientButton(
            key: const ValueKey('confirm-seat'),
            label: _picked == null ? 'Pick a seat' : 'Move to ${_picked!.id}',
            onPressed: _picked == null ? null : () => Navigator.of(context).pop(_picked!.id),
          ),
        ),
      ],
    );
  }
}
