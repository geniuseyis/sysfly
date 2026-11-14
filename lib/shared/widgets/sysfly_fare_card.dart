import 'package:flutter/material.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/formatters.dart';
import '../models/models.dart';
import 'sysfly_controls.dart';

/// Selectable fare family card: name, radio, price and one-line summary.
class SysflyFareCard extends StatelessWidget {
  const SysflyFareCard({super.key, required this.fare, required this.selected, required this.onTap, this.price});

  final Fare fare;
  final bool selected;
  final VoidCallback onTap;

  /// Overrides the displayed price, e.g. for a round trip total.
  final int? price;

  @override
  Widget build(BuildContext context) {
    final amount = price ?? fare.price;
    return Semantics(
      button: true,
      selected: selected,
      label: '${fare.name} fare, ${Fmt.moneyShort(amount)}, ${fare.tagline}${fare.mostPopular ? ', most popular' : ''}',
      child: SysflyPressable(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: SysflyMotion.normal,
                curve: SysflyMotion.standard,
                padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
                decoration: BoxDecoration(
                  color: SysflyColors.surface,
                  borderRadius: BorderRadius.circular(SysflyRadius.lg),
                  border: Border.all(
                    color: selected ? SysflyColors.selected : const Color(0xFFEEF0F7),
                    width: selected ? 1.6 : 1,
                  ),
                  boxShadow: SysflyShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TrText(fare.name, style: SysflyTypography.bodyStrong.copyWith(fontSize: 14.5)),
                        ),
                        SysflyRadioCheck(selected: selected, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AnimatedDefaultTextStyle(
                        duration: SysflyMotion.normal,
                        style: SysflyTypography.total.copyWith(
                          fontSize: 22,
                          color: selected ? SysflyColors.royalText : SysflyColors.textPrimary,
                        ),
                        child: TrText(Fmt.moneyShort(amount)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TrText(
                      fare.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SysflyTypography.caption.copyWith(fontSize: 11.5, color: SysflyColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (fare.mostPopular)
                Positioned(
                  top: -10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const BoxDecoration(color: SysflyColors.selected, borderRadius: SysflyRadius.pillAll),
                      child: TrText(
                        'Most popular',
                        style: SysflyTypography.chip.copyWith(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
