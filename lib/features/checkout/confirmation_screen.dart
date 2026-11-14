import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../booking/booking_controller.dart';
import '../my_flights/trip_actions.dart';
import '../my_flights/trips_controller.dart';
import '../shell/shell_controller.dart';

/// Shown after a successful (simulated) payment.
class ConfirmationScreen extends ConsumerWidget {
  const ConfirmationScreen({super.key, required this.reference});

  final String reference;

  void _home(BuildContext context, WidgetRef ref) {
    ref.read(bookingControllerProvider.notifier).reset();
    ref.read(navigationProvider.notifier).select(AppTab.home);
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripByReferenceProvider(reference));
    final media = MediaQuery.of(context);
    if (trip == null) {
      return Scaffold(
        backgroundColor: SysflyColors.background,
        body: Center(
          child: SysflyOutlineButton(label: 'Back to Home', onPressed: () => _home(context, ref)),
        ),
      );
    }
    final first = trip.firstLeg.flight;
    final last = trip.lastLeg.flight;
    final roundTrip = trip.legs.length > 1 && last.destination == first.origin;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        // The booking is done; going back would re-enter checkout.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _home(context, ref);
        },
        child: Scaffold(
          backgroundColor: SysflyColors.background,
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(SysflySpacing.page, media.padding.top + 2, SysflySpacing.page, 16),
                  children: [
                    const Center(child: SysflySuccessAnimation()),
                    const SizedBox(height: 4),
                    TrText(
                      'Booking confirmed',
                      textAlign: TextAlign.center,
                      style: SysflyTypography.captionStrong.copyWith(color: SysflyColors.royalText, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      header: true,
                      child: TrText(
                        'You’re off to ${first.destination.city}',
                        textAlign: TextAlign.center,
                        style: SysflyTypography.title.copyWith(fontSize: 25),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TrText(
                      'E-tickets for everyone are on their way to\n${trip.contactEmail}',
                      textAlign: TextAlign.center,
                      style: SysflyTypography.bodySecondary.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 22),
                    _Receipt(trip: trip, roundTrip: roundTrip),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SquareAction(
                            icon: SysflyIcons.calendarAdd,
                            label: 'Add to calendar',
                            onTap: () => TripActions.addToCalendar(context, ref, trip),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SquareAction(
                            icon: SysflyIcons.share,
                            label: 'Share',
                            onTap: () => TripActions.share(context, ref, trip),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(SysflySpacing.page, 8, SysflySpacing.page, 12 + media.padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SysflyGradientButton(
                      key: const ValueKey('view-trip'),
                      label: 'View trip',
                      icon: SysflyIcons.ticket,
                      onPressed: () {
                        ref.read(bookingControllerProvider.notifier).reset();
                        ref.read(navigationProvider.notifier).select(AppTab.flights);
                        context.go(Routes.home);
                        context.push(Routes.tripDetails(trip.reference));
                      },
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      button: true,
                      label: 'Back to Home',
                      child: SysflyPressable(
                        key: const ValueKey('back-home'),
                        onTap: () => _home(context, ref),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: ExcludeSemantics(child: TrText('Back to Home', style: SysflyTypography.link)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.trip, required this.roundTrip});

  final Trip trip;
  final bool roundTrip;

  @override
  Widget build(BuildContext context) {
    final first = trip.firstLeg.flight;
    return SysflyCard(
      radius: SysflyRadius.xl,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SysflyIconTile(icon: SysflyIcons.plane, size: 46),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrText(
                            '${first.origin.code} → ${first.destination.code}',
                            style: SysflyTypography.cardTitle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 3),
                          TrText(
                            '${roundTrip ? 'Round trip' : 'One way'} · ${trip.cabin.label} ${trip.fareName} · ${trip.travellerLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SysflyTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                for (var i = 0; i < trip.legs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: SysflyColors.selected, shape: BoxShape.circle),
                          child: TrText('${i + 1}', style: SysflyTypography.chip.copyWith(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TrText(
                                '${trip.legs[i].flight.number} · ${Fmt.dayShort(trip.legs[i].flight.departure)}',
                                style: SysflyTypography.bodyStrong.copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 3),
                              TrText(
                                '${trip.legs[i].flight.origin.code} ${Fmt.time(trip.legs[i].flight.departure)} → '
                                '${trip.legs[i].flight.destination.code} ${Fmt.time(trip.legs[i].flight.arrival)}',
                                style: SysflyTypography.caption.copyWith(color: SysflyColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TrText(
                          trip.legs[i].seats.whereType<String>().isEmpty
                              ? 'Seat at check-in'
                              : trip.legs[i].seats.whereType<String>().join(', '),
                          style: SysflyTypography.captionStrong.copyWith(color: SysflyColors.royalText, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
                const SizedBox(height: 12),
                TrText(trip.passengers.length == 1 ? 'Traveller' : 'Travellers', style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                const SizedBox(height: 5),
                for (final p in trip.passengers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: TrText(p.fullName, style: SysflyTypography.bodyStrong.copyWith(fontSize: 14)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14, child: CustomPaint(painter: _NotchPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrText('Booking reference', style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          TrText(
                            trip.reference,
                            key: const ValueKey('booking-reference'),
                            style: SysflyTypography.cardTitle.copyWith(fontSize: 18, letterSpacing: 0.6),
                          ),
                          Semantics(
                            button: true,
                            label: 'Copy booking reference',
                            child: SysflyPressable(
                              onTap: () => TripActions.copyReference(context, trip),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: SysflyIcon(SysflyIcons.copy, size: 16, color: SysflyColors.royalText),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TrText('Total paid', style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                    const SizedBox(height: 4),
                    TrText(
                      Fmt.money(trip.totalPaid),
                      style: SysflyTypography.cardTitle.copyWith(fontSize: 18, color: SysflyColors.royalText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed tear line with a half-circle cut into each edge of the card.
class _NotchPainter extends CustomPainter {
  const _NotchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final cut = Paint()..color = SysflyColors.background;
    canvas.drawCircle(Offset(0, y), 7, cut);
    canvas.drawCircle(Offset(size.width, y), 7, cut);
    final dash = Paint()
      ..color = const Color(0xFFDADDE8)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var x = 16.0; x < size.width - 16; x += 6) {
      canvas.drawLine(Offset(x, y), Offset(x + 2.5, y), dash);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({required this.icon, required this.label, required this.onTap});

  final SysflyIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SysflyPressable(
        onTap: onTap,
        child: ExcludeSemantics(
          child: SysflyCard(
            radius: SysflyRadius.lg,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                SysflyIcon(icon, size: 22, color: SysflyColors.royalText),
                const SizedBox(height: 8),
                TrText(label, style: SysflyTypography.bodyStrong.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
