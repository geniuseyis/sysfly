import 'package:flutter/material.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/formatters.dart';
import 'sysfly_gradient_button.dart';
import 'sysfly_sheet.dart';

/// Month calendar for choosing a flight date, shown in a bottom sheet.
///
/// When [rangeStart] is given (choosing a return date) the departure day is
/// ringed and the days up to the selection are banded.
class SysflyDatePicker extends StatefulWidget {
  const SysflyDatePicker({
    super.key,
    required this.title,
    required this.today,
    required this.firstDate,
    required this.lastDate,
    required this.onConfirm,
    this.initial,
    this.rangeStart,
  });

  final String title;
  final DateTime today;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initial;
  final DateTime? rangeStart;
  final ValueChanged<DateTime> onConfirm;

  @override
  State<SysflyDatePicker> createState() => _SysflyDatePickerState();
}

class _SysflyDatePickerState extends State<SysflyDatePicker> {
  late DateTime? _selected = widget.initial == null ? null : Fmt.dateOnly(widget.initial!);
  late DateTime _month = DateTime((widget.initial ?? widget.rangeStart ?? widget.firstDate).year,
      (widget.initial ?? widget.rangeStart ?? widget.firstDate).month);
  int _direction = 1;

  DateTime get _first => Fmt.dateOnly(widget.firstDate);
  DateTime get _last => Fmt.dateOnly(widget.lastDate);
  bool get _canGoBack => _month.isAfter(DateTime(_first.year, _first.month));
  bool get _canGoForward => _month.isBefore(DateTime(_last.year, _last.month));

  void _shift(int by) {
    SysflyHaptics.selection();
    setState(() {
      _direction = by;
      _month = DateTime(_month.year, _month.month + by);
    });
  }

  String get _subtitle {
    final start = widget.rangeStart;
    if (start == null) {
      return _selected == null ? 'Pick the day you want to fly' : Fmt.dayShort(_selected!);
    }
    final from = 'Departing ${Fmt.dayShort(start)}';
    if (_selected == null) return from;
    final nights = _selected!.difference(Fmt.dateOnly(start)).inDays;
    return '$from · $nights ${nights == 1 ? 'night' : 'nights'}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SysflySheetTitle(title: widget.title, subtitle: _subtitle),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    TrText(Fmt.monthYear(_month), style: SysflyTypography.cardTitle.copyWith(fontSize: 16.5)),
                    const SizedBox(width: 6),
                    const SysflyIcon(SysflyIcons.chevronDown, size: 14, color: SysflyColors.textPrimary),
                  ],
                ),
              ),
              _MonthButton(icon: SysflyIcons.chevronLeft, label: 'Previous month', onTap: _canGoBack ? () => _shift(-1) : null),
              const SizedBox(width: 8),
              _MonthButton(icon: SysflyIcons.chevronRight, label: 'Next month', onTap: _canGoForward ? () => _shift(1) : null),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final d in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                Expanded(
                  child: Center(child: TrText(d, style: SysflyTypography.caption.copyWith(fontSize: 12))),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: SysflyMotion.normal,
            switchInCurve: SysflyMotion.enter,
            switchOutCurve: SysflyMotion.exit,
            transitionBuilder: (child, animation) {
              final incoming = child.key == ValueKey(_month);
              final from = Offset((incoming ? 1 : -1) * 0.12 * _direction, 0);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: Tween(begin: from, end: Offset.zero).animate(animation), child: child),
              );
            },
            layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
            child: _MonthGrid(
              key: ValueKey(_month),
              month: _month,
              today: Fmt.dateOnly(widget.today),
              first: _first,
              last: _last,
              selected: _selected,
              rangeStart: widget.rangeStart == null ? null : Fmt.dateOnly(widget.rangeStart!),
              onSelect: (day) {
                SysflyHaptics.selection();
                setState(() => _selected = day);
              },
            ),
          ),
          const SizedBox(height: 18),
          SysflyGradientButton(
            label: _selected == null ? 'Select a date' : 'Select ${Fmt.dayShort(_selected!)}',
            onPressed: _selected == null ? null : () => widget.onConfirm(_selected!),
          ),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.icon, required this.label, required this.onTap});

  final SysflyIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SysflyPressable(
        onTap: onTap,
        haptic: PressHaptic.none,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SysflyColors.surface,
            border: Border.all(color: enabled ? SysflyColors.fieldBorder : Colors.transparent),
            boxShadow: enabled ? SysflyShadows.soft : null,
          ),
          child: SysflyIcon(icon, size: 14, color: enabled ? SysflyColors.textPrimary : SysflyColors.textDisabled),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.month,
    required this.today,
    required this.first,
    required this.last,
    required this.selected,
    required this.rangeStart,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final DateTime first;
  final DateTime last;
  final DateTime? selected;
  final DateTime? rangeStart;
  final ValueChanged<DateTime> onSelect;

  static const double _rowHeight = 46;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = DateTime(month.year, month.month, 1).weekday - 1;
    final weeks = ((lead + daysInMonth) / 7).ceil();
    final hasRange = rangeStart != null && selected != null && selected!.isAfter(rangeStart!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var week = 0; week < 6; week++)
          SizedBox(
            height: _rowHeight,
            child: week >= weeks
                ? null
                : Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(child: _cell(week * 7 + col - lead + 1, col, daysInMonth, hasRange)),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _cell(int dayNumber, int column, int daysInMonth, bool hasRange) {
    if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox.shrink();
    final day = DateTime(month.year, month.month, dayNumber);
    final enabled = !day.isBefore(first) && !day.isAfter(last);
    final isSelected = selected != null && Fmt.sameDay(day, selected!);
    final isStart = rangeStart != null && Fmt.sameDay(day, rangeStart!);
    final isToday = Fmt.sameDay(day, today);
    final inRange = hasRange && !day.isBefore(rangeStart!) && !day.isAfter(selected!);

    // The band runs edge to edge inside a week and is rounded where the
    // range starts, ends, or wraps to another row.
    Widget? band;
    if (inRange) {
      final roundLeft = isStart || column == 0 || dayNumber == 1;
      final roundRight = isSelected || column == 6 || dayNumber == daysInMonth;
      band = Container(
        margin: EdgeInsets.only(top: 3, bottom: 3, left: isStart ? 4 : 0, right: isSelected ? 4 : 0),
        decoration: BoxDecoration(
          color: SysflyColors.chip,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(roundLeft ? 20 : 0),
            right: Radius.circular(roundRight ? 20 : 0),
          ),
        ),
      );
    }

    final textColor = isSelected
        ? Colors.white
        : !enabled
            ? SysflyColors.textDisabled
            : isStart
                ? SysflyColors.link
                : SysflyColors.textPrimary;

    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: isSelected,
      label: '${Fmt.dayShort(day)}${isToday ? ', today' : ''}${isStart ? ', departure' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onSelect(day) : null,
        child: ExcludeSemantics(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (band != null) Positioned.fill(child: band),
              AnimatedContainer(
                duration: SysflyMotion.fast,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? SysflyColors.selected : (isStart ? SysflyColors.surface : Colors.transparent),
                  border: isStart && !isSelected ? Border.all(color: SysflyColors.selected, width: 1.4) : null,
                ),
                alignment: Alignment.center,
                child: TrText(
                  '$dayNumber',
                  style: SysflyTypography.body.copyWith(
                    fontSize: 15,
                    fontWeight: isSelected || isStart ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (isToday && !isSelected)
                const Positioned(
                  bottom: 5,
                  child: SizedBox(
                    width: 4,
                    height: 4,
                    child: DecoratedBox(decoration: BoxDecoration(color: SysflyColors.info, shape: BoxShape.circle)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
