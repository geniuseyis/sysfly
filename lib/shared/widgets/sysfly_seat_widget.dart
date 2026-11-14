import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/services/haptics.dart';
import '../models/models.dart';

/// Visual state of a seat on the map.
enum SeatVisual { available, occupied, selected, extraLegroom, unavailable }

/// One seat. Tapping a free seat pops it and swaps its colours; taken and
/// unavailable seats do not respond.
class SysflySeatWidget extends StatefulWidget {
  const SysflySeatWidget({
    super.key,
    required this.seat,
    required this.selectedBy,
    required this.onTap,
    this.size = 38,
  });

  final Seat seat;

  /// Initials of the traveller holding this seat, or null.
  final String? selectedBy;
  final VoidCallback? onTap;
  final double size;

  SeatVisual get visual {
    if (selectedBy != null) return SeatVisual.selected;
    return switch (seat.availability) {
      SeatAvailability.occupied => SeatVisual.occupied,
      SeatAvailability.unavailable => SeatVisual.unavailable,
      SeatAvailability.available => seat.kind == SeatKind.extraLegroom ? SeatVisual.extraLegroom : SeatVisual.available,
    };
  }

  @override
  State<SysflySeatWidget> createState() => _SysflySeatWidgetState();
}

class _SysflySeatWidgetState extends State<SysflySeatWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);

  @override
  void didUpdateWidget(SysflySeatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBy == null && widget.selectedBy != null) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = widget.visual;
    final tappable = widget.onTap != null && (widget.seat.isSelectable || visual == SeatVisual.selected);
    final (fill, border, text) = switch (visual) {
      SeatVisual.available => (SysflyColors.surface, SysflyColors.seatBorder, const Color(0xFF50556A)),
      SeatVisual.occupied => (SysflyColors.seatTaken, SysflyColors.seatTaken, Colors.transparent),
      SeatVisual.unavailable => (const Color(0xFFEFF1F6), const Color(0xFFE3E6EE), Colors.transparent),
      SeatVisual.extraLegroom => (SysflyColors.seatExtra, SysflyColors.seatExtraBorder, SysflyColors.seatExtraText),
      SeatVisual.selected => (SysflyColors.selected, SysflyColors.indigo, Colors.white),
    };
    final label = switch (visual) {
      SeatVisual.selected => widget.selectedBy!,
      SeatVisual.available || SeatVisual.extraLegroom => widget.seat.letter,
      _ => '',
    };
    final description = switch (visual) {
      SeatVisual.available => 'available',
      SeatVisual.occupied => 'taken',
      SeatVisual.unavailable => 'unavailable',
      SeatVisual.extraLegroom => 'available, extra legroom',
      SeatVisual.selected => 'selected',
    };

    return Semantics(
      button: tappable,
      enabled: tappable,
      selected: visual == SeatVisual.selected,
      label: 'Seat ${widget.seat.id}, $description',
      onTap: tappable ? widget.onTap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tappable
            ? () {
                SysflyHaptics.selection();
                widget.onTap!();
              }
            : null,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.78, end: 1).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOutBack)),
          child: SizedBox(
            width: widget.size,
            height: widget.size + 4,
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  // Seat cushion and armrests.
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: SysflyMotion.normal,
                      curve: SysflyMotion.standard,
                      decoration: BoxDecoration(
                        color: Color.lerp(fill, border, visual == SeatVisual.selected ? 0.55 : 0.28),
                        borderRadius: BorderRadius.circular(widget.size * 0.28),
                        border: Border.all(color: border, width: 1.1),
                      ),
                    ),
                  ),
                  // Backrest.
                  Positioned(
                    left: 3.5,
                    right: 3.5,
                    top: 0,
                    bottom: 7,
                    child: AnimatedContainer(
                      duration: SysflyMotion.normal,
                      curve: SysflyMotion.standard,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(widget.size * 0.24),
                        border: Border.all(color: border, width: 1.1),
                      ),
                      child: TrText(
                        label,
                        style: SysflyTypography.chip.copyWith(
                          fontSize: visual == SeatVisual.selected ? 10.5 : 12,
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
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
