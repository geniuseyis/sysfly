import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/utils/formatters.dart';
import '../models/models.dart';
import 'sysfly_glass_card.dart';

/// "Price details" card listing every line of a [PriceBreakdown].
class SysflyPriceSummary extends StatelessWidget {
  const SysflyPriceSummary({super.key, required this.price});

  final PriceBreakdown price;

  @override
  Widget build(BuildContext context) {
    return SysflyCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrText('Price details', style: SysflyTypography.cardTitle.copyWith(fontSize: 15.5)),
          const SizedBox(height: 14),
          for (final line in price.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: TrText(line.label, style: SysflyTypography.bodySecondary.copyWith(fontSize: 13.5))),
                  TrText(
                    line.note ?? Fmt.money(line.amount),
                    style: SysflyTypography.bodyStrong.copyWith(
                      fontSize: 13.5,
                      color: line.amount < 0 ? SysflyColors.successText : SysflyColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 12, thickness: 1, color: SysflyColors.divider),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: TrText('Total', style: SysflyTypography.bodyStrong)),
              TrText(Fmt.money(price.total), style: SysflyTypography.total.copyWith(fontSize: 23)),
            ],
          ),
        ],
      ),
    );
  }
}
