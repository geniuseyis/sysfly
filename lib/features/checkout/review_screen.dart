import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../booking/booking_controller.dart';
import '../booking/fare_screen.dart';
import '../booking/widgets/booking_scaffold.dart';
import '../my_flights/trips_controller.dart';
import 'widgets/payment_sheets.dart';

/// Step 4 of booking: check everything, choose how to pay, and pay.
///
/// The payment is simulated. The loading overlay is shown for exactly as
/// long as the booking request is in flight.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final trip = await ref.read(bookingControllerProvider.notifier).confirm();
      await ref.read(tripsControllerProvider.notifier).refresh();
      SysflyHaptics.success();
      if (!mounted) return;
      // The flow is finished: leave nothing of it to go back to.
      context.go(Routes.confirmedFor(trip.reference));
    } catch (error) {
      if (!mounted) return;
      setState(() => _paying = false);
      showSysflyToast(context, describeError(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingControllerProvider);
    final price = ref.watch(bookingPriceProvider);
    final flight = draft.outbound;
    final fare = draft.fare;
    if (flight == null || fare == null) return const NoBookingInProgress();
    final controller = ref.read(bookingControllerProvider.notifier);
    final n = draft.travellerCount;
    final travellers = draft.travellers.whereType<Passenger>().toList();

    return SysflyLoadingOverlay(
      visible: _paying,
      title: 'Confirming your booking',
      subtitle: '${draft.payment.title} · ${Fmt.money(price.total)}',
      child: BookingScaffold(
        title: 'Review & Pay',
        step: 3,
        bottomBar: SysflyBottomBar(
          title: Fmt.money(price.total),
          subtitle: draft.termsAccepted
              ? '${n == 1 ? '1 traveller' : '$n travellers'} · incl. taxes & fees'
              : 'Accept the terms below',
          action: BookingContinueButton(
            label: 'Pay ${Fmt.money(price.total)}',
            onPressed: draft.termsAccepted && !_paying ? _pay : null,
          ),
        ),
        children: [
          SysflyCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TrText(
                  '${flight.origin.code} → ${flight.destination.code}',
                  style: SysflyTypography.title.copyWith(fontSize: 21),
                ),
                const SizedBox(height: 4),
                TrText(
                  '${draft.inbound == null ? 'One way' : 'Round trip'} · ${Fmt.dayMonth(flight.departure)} · '
                  '${flight.cabin.label} ${fare.name}',
                  style: SysflyTypography.bodySecondary.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
                const SizedBox(height: 14),
                _FlightSummary(
                  caption: '${draft.inbound == null ? 'Your flight' : 'Outbound'} · ${Fmt.dayShort(flight.departure)}',
                  flight: flight,
                  seats: [for (var i = 0; i < n; i++) draft.seats[i]?.id].whereType<String>().join(', '),
                ),
                if (draft.inbound != null) ...[
                  const SizedBox(height: 16),
                  _FlightSummary(
                    caption: 'Return · ${Fmt.dayShort(draft.inbound!.departure)}',
                    flight: draft.inbound!,
                    seats: '',
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
                for (final traveller in travellers)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        SysflyInitials(initials: traveller.initials, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TrText(traveller.fullName, style: SysflyTypography.bodyStrong.copyWith(fontSize: 14.5)),
                              const SizedBox(height: 2),
                              TrText(
                                traveller == travellers.first ? 'E-tickets to ${draft.contact.email}' : 'Adult',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SysflyTypography.caption.copyWith(fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SysflyCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      PaymentBrandMark(brand: draft.payment.brand),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TrText(draft.payment.title, style: SysflyTypography.bodyStrong),
                            const SizedBox(height: 2),
                            TrText(
                              draft.payment.brand.isWallet ? draft.payment.subtitle : 'Expires ${draft.payment.expiry}',
                              style: SysflyTypography.caption.copyWith(fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Change payment method',
                        child: SysflyPressable(
                          key: const ValueKey('change-payment'),
                          onTap: () async {
                            final method = await showPaymentMethodSheet(context, current: draft.payment);
                            if (method != null) controller.setPayment(method);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: ExcludeSemantics(child: TrText('Change', style: SysflyTypography.link)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
                Semantics(
                  button: true,
                  label: draft.promo == null ? 'Add promo code' : 'Remove promo code ${draft.promo!.code}',
                  child: SysflyPressable(
                    key: const ValueKey('promo-row'),
                    onTap: () async {
                      if (draft.promo != null) {
                        controller.removePromo();
                        return;
                      }
                      final applied = await showPromoSheet(context);
                      if (applied == true && context.mounted) {
                        showSysflyToast(context, 'Promo code applied', icon: SysflyIcons.check);
                      }
                    },
                    pressedScale: 0.985,
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 36,
                              decoration: BoxDecoration(color: SysflyColors.tile, borderRadius: BorderRadius.circular(9)),
                              child: const SysflyIcon(SysflyIcons.promo, size: 17, color: SysflyColors.link),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: draft.promo == null
                                  ? TrText('Add promo code', style: SysflyTypography.bodyStrong)
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TrText('${draft.promo!.code} applied', style: SysflyTypography.bodyStrong),
                                        const SizedBox(height: 2),
                                        TrText(draft.promo!.description, style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                                      ],
                                    ),
                            ),
                            SysflyIcon(
                              draft.promo == null ? SysflyIcons.plus : SysflyIcons.close,
                              size: 16,
                              color: SysflyColors.royalText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SysflyPriceSummary(price: price),
          const SizedBox(height: 18),
          Semantics(
            checked: draft.termsAccepted,
            label: 'I accept the ${fare.name} fare rules, the conditions of carriage and the dangerous goods policy',
            child: GestureDetector(
              key: const ValueKey('accept-terms'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                SysflyHaptics.selection();
                controller.setTerms(!draft.termsAccepted);
              },
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SysflyCheckbox(value: draft.termsAccepted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TrText(
                        'I accept the ${fare.name} fare rules, the conditions of carriage and the dangerous goods policy.',
                        style: SysflyTypography.bodySecondary.copyWith(fontSize: 13, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SysflyIcon(SysflyIcons.lock, size: 14, color: SysflyColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: TrText(
                  'Secure, encrypted payment · charged in USD',
                  style: SysflyTypography.caption.copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlightSummary extends StatelessWidget {
  const _FlightSummary({required this.caption, required this.flight, required this.seats});

  final String caption;
  final Flight flight;

  /// Comma separated seat ids, or empty when assigned at check-in.
  final String seats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrText(
          caption,
          style: SysflyTypography.captionStrong.copyWith(fontSize: 12, color: SysflyColors.royalText, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrText(flight.origin.code, style: SysflyTypography.cardTitle.copyWith(fontSize: 17)),
                const SizedBox(height: 2),
                TrText(Fmt.time(flight.departure), style: SysflyTypography.caption.copyWith(color: SysflyColors.textSecondary)),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    TrText(Fmt.duration(flight.duration), style: SysflyTypography.caption.copyWith(fontSize: 11)),
                    const SizedBox(height: 2),
                    const SysflyFlightRouteLine(
                      style: RouteLineStyle.straight,
                      height: 16,
                      startColor: Color(0xFF9CC6F7),
                      lineColor: Color(0xFF3F5FD0),
                      dotColor: SysflyColors.selected,
                      endColor: SysflyColors.selected,
                      endFilled: true,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TrText(flight.destination.code, style: SysflyTypography.cardTitle.copyWith(fontSize: 17)),
                const SizedBox(height: 2),
                TrText(Fmt.time(flight.arrival), style: SysflyTypography.caption.copyWith(color: SysflyColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TrText(
                '${flight.airline.name} · ${flight.number}',
                style: SysflyTypography.caption.copyWith(fontSize: 12),
              ),
            ),
            const SysflyIcon(SysflyIcons.cabin, size: 13, color: SysflyColors.royalText),
            const SizedBox(width: 5),
            TrText(
              seats.isEmpty ? 'At check-in' : seats,
              style: SysflyTypography.captionStrong.copyWith(fontSize: 12.5, color: SysflyColors.royalText, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}
