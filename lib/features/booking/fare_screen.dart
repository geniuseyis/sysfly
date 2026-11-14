import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'booking_controller.dart';
import 'widgets/booking_scaffold.dart';

/// Step 1 of booking: choose Lite, Classic or Flex.
class FareScreen extends ConsumerWidget {
  const FareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(bookingControllerProvider);
    final price = ref.watch(bookingPriceProvider);
    final flight = draft.outbound;
    final fare = draft.fare;
    if (flight == null || fare == null) return const NoBookingInProgress();
    final n = draft.travellerCount;

    return BookingScaffold(
      title: 'Choose Fare',
      step: 0,
      bottomBar: SysflyBottomBar(
        title: Fmt.money(price.total),
        subtitle: '${n == 1 ? '1 traveller' : '$n travellers'} · incl. ${Fmt.moneyShort(price.taxes)} taxes',
        action: BookingContinueButton(onPressed: () => context.push(Routes.passengers)),
      ),
      children: [
        TrText(
          '${flight.origin.code} → ${flight.destination.code} · ${Fmt.dayMonth(flight.departure)}',
          style: SysflyTypography.caption.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 6),
        Semantics(header: true, child: TrText('Choose your fare', style: SysflyTypography.headline)),
        const SizedBox(height: 4),
        TrText(
          '${flight.cabin.label} · per traveller, ${draft.inbound == null ? 'one way' : 'round trip'}',
          style: SysflyTypography.bodySecondary,
        ),
        const SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final option in draft.fares) ...[
              if (option != draft.fares.first) const SizedBox(width: 10),
              Expanded(
                child: SysflyFareCard(
                  key: ValueKey('fare-${option.type.name}'),
                  fare: option,
                  price: draft.farePrice(option.type),
                  selected: option.type == draft.fareType,
                  onTap: () => ref.read(bookingControllerProvider.notifier).selectFare(option.type),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SysflyCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          child: AnimatedSwitcher(
            duration: SysflyMotion.normal,
            layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
            child: Column(
              key: ValueKey(fare.type),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SysflyIconTile(icon: SysflyIcons.ticket, size: 42),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrText('${fare.name} includes', style: SysflyTypography.cardTitle),
                          const SizedBox(height: 3),
                          TrText(fare.summary, style: SysflyTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final feature in fare.features) ...[
                  if (feature != fare.features.first) const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: feature.included ? SysflyColors.tile : SysflyColors.field,
                            shape: BoxShape.circle,
                          ),
                          child: SysflyIcon(
                            feature.included ? SysflyIcons.check : SysflyIcons.close,
                            size: 12,
                            color: feature.included ? SysflyColors.link : SysflyColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TrText(
                            feature.label,
                            style: SysflyTypography.body.copyWith(fontWeight: FontWeight.w500, color: const Color(0xFF2B2D3A)),
                          ),
                        ),
                        TrText(
                          feature.value,
                          style: SysflyTypography.bodyStrong.copyWith(
                            fontSize: 13.5,
                            color: feature.included ? SysflyColors.textPrimary : SysflyColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TrText(
          'Fares are per traveller, before taxes and airport fees. Seats we assign for you are always free.',
          textAlign: TextAlign.center,
          style: SysflyTypography.caption.copyWith(fontSize: 11.5, height: 1.5),
        ),
      ],
    );
  }
}

/// Shown if a booking step is opened without a flight selected.
class NoBookingInProgress extends StatelessWidget {
  const NoBookingInProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SysflyColors.background,
      body: Column(
        children: [
          SysflyHeader(title: 'Booking', onBack: () => context.canPop() ? context.pop() : context.go(Routes.home)),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SysflyIconTile(icon: SysflyIcons.planeOutline, size: 56),
                    const SizedBox(height: 14),
                    TrText('Pick a flight to start booking', style: SysflyTypography.bodySecondary),
                    const SizedBox(height: 16),
                    SysflyOutlineButton(label: 'Back to Home', onPressed: () => context.go(Routes.home)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
