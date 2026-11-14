import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../models/models.dart';
import 'sysfly_seat_widget.dart';

/// Scrollable cabin section: fuselage, wings, galley, exits and the seat
/// grid for rows [fromRow] to [toRow].
///
/// The cabin has a fixed width and is centred, so it never overflows
/// horizontally; the parent scrolls it vertically. Measurements follow the
/// reference: 37 pt seats 5.5 pt apart, a 41 pt aisle, 52 pt between rows and
/// 16 pt of extra legroom in front of every exit row.
class SysflySeatMap extends StatelessWidget {
  const SysflySeatMap({
    super.key,
    required this.map,
    required this.fromRow,
    required this.toRow,
    required this.selected,
    required this.onSeatTap,
    this.showNose = true,
  });

  final SeatMap map;
  final int fromRow;
  final int toRow;

  /// Seat id to the initials of the traveller holding it.
  final Map<String, String> selected;
  final ValueChanged<Seat> onSeatTap;

  /// Draw the rounded nose and front galley above the first row.
  final bool showNose;

  static const double seat = 37;
  static const double seatGap = 5.5;
  static const double aisle = 41;
  static const double rowPitch = 52;
  static const double exitGap = 16;
  static const double sidePadding = 24;
  static const double cabinWidth = seat * 4 + seatGap * 2 + aisle + sidePadding * 2;

  /// Where the nose reaches the full cabin width, below its tip.
  static const double noseHeight = 122;

  /// Galley boxes start this far below the tip of the nose.
  static const double galleyTop = 132;

  /// Galley boxes, rule, column letters and spacing down to the first row.
  static const double galleyHeight = 84;

  /// Letters row when there is no nose.
  static const double plainHeaderHeight = 46;

  double get _top => showNose ? galleyTop + galleyHeight : plainHeaderHeight;

  /// Extra space above [row], which exit rows other than the first have.
  double _gapBefore(int row) => row != fromRow && map.exitRows.contains(row) ? exitGap : 0;

  /// Top of [row] within the map.
  double _rowTop(int row) {
    var y = _top;
    for (var r = fromRow; r < row; r++) {
      y += _gapBefore(r) + rowPitch;
    }
    return y + _gapBefore(row);
  }

  @override
  Widget build(BuildContext context) {
    final rows = [for (var r = fromRow; r <= toRow; r++) r];
    final half = map.letters.length ~/ 2;
    final left = map.letters.sublist(0, half);
    final right = map.letters.sublist(half);
    final height = _rowTop(toRow) + rowPitch + 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cabinLeft = (width - cabinWidth) / 2;
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _CabinPainter(
                      showNose: showNose,
                      aisleTop: _top - 8,
                      wingTop: showNose ? _rowTop(fromRow + 4) + 6 : -1,
                      wingBottom: showNose ? _rowTop(math.min(fromRow + 11, toRow)) + 30 : -1,
                      tickRows: [for (final r in rows) _rowTop(r) + rowPitch / 2 - 6],
                    ),
                  ),
                ),
              ),
              if (showNose)
                Positioned(
                  left: cabinLeft + sidePadding,
                  width: cabinWidth - sidePadding * 2,
                  top: galleyTop,
                  child: Row(
                    children: const [
                      Expanded(child: _GalleyBox(label: 'WC')),
                      SizedBox(width: aisle),
                      Expanded(child: _GalleyBox(icon: SysflyIcons.galley)),
                    ],
                  ),
                ),
              Positioned(
                left: cabinLeft + sidePadding,
                width: cabinWidth - sidePadding * 2,
                top: _top - 31,
                child: _Letters(left: left, right: right),
              ),
              for (final row in rows)
                Positioned(
                  left: cabinLeft + sidePadding,
                  width: cabinWidth - sidePadding * 2,
                  top: _rowTop(row),
                  height: rowPitch,
                  child: Row(
                    children: [
                      for (final letter in left) ...[
                        if (letter != left.first) const SizedBox(width: seatGap),
                        _seat(row, letter),
                      ],
                      SizedBox(
                        width: aisle,
                        child: Center(
                          child: TrText('$row', style: SysflyTypography.caption.copyWith(fontSize: 11, color: SysflyColors.textTertiary)),
                        ),
                      ),
                      for (final letter in right) ...[
                        if (letter != right.first) const SizedBox(width: seatGap),
                        _seat(row, letter),
                      ],
                    ],
                  ),
                ),
              // Exit markers sit just outside the fuselage, in the legroom gap.
              for (final row in rows)
                if (map.exitRows.contains(row)) ...[
                  Positioned(top: _exitTop(row), left: cabinLeft - 50, child: const _ExitMarker(leftSide: true)),
                  Positioned(top: _exitTop(row), left: cabinLeft + cabinWidth, child: const _ExitMarker(leftSide: false)),
                ],
            ],
          ),
        );
      },
    );
  }

  double _exitTop(int row) {
    // The first row's exit is level with the galley; the others sit in the
    // gap in front of their row.
    if (row == fromRow) return showNose ? galleyTop + 1 : _rowTop(row) - 16;
    return _rowTop(row) - exitGap / 2 - 15;
  }

  Widget _seat(int row, String letter) {
    final seat = map.seat(row, letter)!;
    return SysflySeatWidget(
      key: ValueKey('seat-${seat.id}'),
      seat: seat,
      selectedBy: selected[seat.id],
      onTap: () => onSeatTap(seat),
      size: SysflySeatMap.seat,
    );
  }
}

class _Letters extends StatelessWidget {
  const _Letters({required this.left, required this.right});

  final List<String> left;
  final List<String> right;

  @override
  Widget build(BuildContext context) {
    Widget letter(String l) => SizedBox(
          width: SysflySeatMap.seat,
          child: Center(child: TrText(l, style: SysflyTypography.caption.copyWith(fontSize: 11.5, color: SysflyColors.textTertiary))),
        );
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final l in left) ...[if (l != left.first) const SizedBox(width: SysflySeatMap.seatGap), letter(l)],
          const SizedBox(width: SysflySeatMap.aisle),
          for (final l in right) ...[if (l != right.first) const SizedBox(width: SysflySeatMap.seatGap), letter(l)],
        ],
      ),
    );
  }
}

/// Lavatory or galley block with a rule beneath it.
class _GalleyBox extends StatelessWidget {
  const _GalleyBox({this.label, this.icon});

  final String? label;
  final SysflyIconData? icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E5EF)),
            ),
            child: label != null
                ? TrText(label!, style: SysflyTypography.overline.copyWith(fontSize: 10, color: SysflyColors.textTertiary))
                : SysflyIcon(icon!, size: 16, color: SysflyColors.textTertiary),
          ),
          const SizedBox(height: 11),
          Container(height: 1.5, color: const Color(0xFFDDE0EA)),
        ],
      ),
    );
  }
}

class _ExitMarker extends StatelessWidget {
  const _ExitMarker({required this.leftSide});

  final bool leftSide;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      width: 4,
      height: 22,
      decoration: const BoxDecoration(color: SysflyColors.selected, borderRadius: SysflyRadius.pillAll),
    );
    final label = TrText(
      'EXIT',
      style: SysflyTypography.overline.copyWith(fontSize: 7.5, color: SysflyColors.link, fontWeight: FontWeight.w700, letterSpacing: 0.8),
    );
    final arrow = SysflyIcon(leftSide ? SysflyIcons.chevronLeft : SysflyIcons.chevronRight, size: 8, color: SysflyColors.link, strokeWidth: 3);
    return Semantics(
      label: 'Emergency exit',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 50,
          height: 30,
          child: Row(
            mainAxisAlignment: leftSide ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: leftSide
                ? [label, const SizedBox(width: 2), arrow, const SizedBox(width: 3), bar]
                : [bar, const SizedBox(width: 3), arrow, const SizedBox(width: 2), label],
          ),
        ),
      ),
    );
  }
}

class _CabinPainter extends CustomPainter {
  const _CabinPainter({
    required this.showNose,
    required this.aisleTop,
    required this.wingTop,
    required this.wingBottom,
    required this.tickRows,
  });

  final bool showNose;
  final double aisleTop;
  final double wingTop;
  final double wingBottom;

  /// Vertical positions of the window marks, one per row.
  final List<double> tickRows;

  @override
  void paint(Canvas canvas, Size size) {
    const cabin = SysflySeatMap.cabinWidth;
    final left = (size.width - cabin) / 2;
    final right = left + cabin;
    final centre = size.width / 2;

    // Wings, behind the fuselage.
    if (wingTop >= 0) {
      final wing = Paint()..color = const Color(0xFFE9ECF6);
      final edge = Paint()
        ..color = const Color(0xFFDDE1EE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final dir in const [-1.0, 1.0]) {
        final root = dir < 0 ? left : right;
        final tip = dir < 0 ? -30.0 : size.width + 30;
        final path = Path()
          ..moveTo(root, wingTop)
          ..lineTo(tip, wingTop + 70)
          ..lineTo(tip, wingBottom + 40)
          ..lineTo(root, wingBottom)
          ..close();
        canvas.drawPath(path, wing);
        canvas.drawPath(path, edge);
      }
    }

    // Fuselage: a half ellipse for the nose, then straight sides.
    const tip = 0.6;
    const shoulder = tip + SysflySeatMap.noseHeight;
    final body = Path();
    if (showNose) {
      body
        ..moveTo(left, size.height)
        ..lineTo(left, shoulder)
        ..arcToPoint(Offset(right, shoulder), radius: const Radius.elliptical(cabin / 2, SysflySeatMap.noseHeight))
        ..lineTo(right, size.height)
        ..close();
    } else {
      body.addRect(Rect.fromLTRB(left, 0, right, size.height));
    }
    canvas.drawPath(body, Paint()..color = const Color(0xFFFBFBFE));
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFFDCE0EC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Aisle strip.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(centre - SysflySeatMap.aisle / 2 + 4, aisleTop, centre + SysflySeatMap.aisle / 2 - 4, size.height),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFF1F3F9),
    );

    // Cockpit windows: five panes on an arc 131 pt wide that rises 34 pt.
    if (showNose) {
      final glass = Paint()
        ..color = SysflyColors.selected
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      const radius = 80.0;
      final rect = Rect.fromCircle(center: Offset(centre, tip + 30 + radius), radius: radius);
      const sweep = 1.92;
      const start = -math.pi / 2 - sweep / 2;
      const panes = 5;
      for (var i = 0; i < panes; i++) {
        canvas.drawArc(rect, start + sweep * i / panes + 0.035, sweep / panes - 0.07, false, glass);
      }
    }

    // Window marks down both sides, one per row.
    final tick = Paint()
      ..color = const Color(0xFFD5D9E6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final y in tickRows) {
      canvas.drawLine(Offset(left + 7, y), Offset(left + 7, y + 8), tick);
      canvas.drawLine(Offset(right - 7, y), Offset(right - 7, y + 8), tick);
    }
  }

  @override
  bool shouldRepaint(_CabinPainter old) =>
      old.showNose != showNose ||
      old.aisleTop != aisleTop ||
      old.wingTop != wingTop ||
      old.wingBottom != wingBottom ||
      old.tickRows.length != tickRows.length;
}

/// Key to the seat colours.
class SysflySeatLegend extends StatelessWidget {
  const SysflySeatLegend({super.key, required this.extraLegroomPrice});

  final int extraLegroomPrice;

  @override
  Widget build(BuildContext context) {
    Widget item(Color fill, Color border, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(4), border: Border.all(color: border)),
            ),
            const SizedBox(width: 6),
            TrText(label, style: SysflyTypography.caption.copyWith(fontSize: 11.5, color: SysflyColors.textSecondary)),
          ],
        );
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        item(SysflyColors.surface, SysflyColors.seatBorder, 'Available'),
        item(SysflyColors.selected, SysflyColors.selected, 'Selected'),
        item(SysflyColors.seatTaken, SysflyColors.seatTaken, 'Taken'),
        item(SysflyColors.seatExtra, SysflyColors.seatExtraBorder, 'Extra legroom · \$$extraLegroomPrice'),
      ],
    );
  }
}
