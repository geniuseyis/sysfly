import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock/demo_catalog.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import 'booking_controller.dart';
import 'fare_screen.dart';
import 'widgets/booking_scaffold.dart';
import 'widgets/passenger_sheets.dart';

/// Step 2 of booking: who is flying and where to send the tickets.
class PassengersScreen extends ConsumerWidget {
  const PassengersScreen({super.key});

  Future<void> _editTraveller(BuildContext context, WidgetRef ref, BookingDraft draft, int index) async {
    final used = draft.travellers.whereType<Passenger>().map((p) => p.id).toSet();
    final result = await showTravellerSheet(
      context,
      title: 'Traveller ${index + 1}',
      id: draft.travellers[index]?.id ?? 'traveller-${index + 1}',
      travelDate: (draft.inbound ?? draft.outbound!).departure,
      today: ref.read(clockProvider).now(),
      initial: draft.travellers[index],
      // Citizens of Türkiye fly domestic routes on their national ID.
      domestic: [draft.outbound, draft.inbound]
          .whereType<Flight>()
          .every((f) => f.origin.countryCode == 'TR' && f.destination.countryCode == 'TR'),
      suggestions: [
        for (final p in DemoCatalog.savedTravellers)
          if (!used.contains(p.id) || p.id == draft.travellers[index]?.id) p,
      ],
    );
    if (result != null) ref.read(bookingControllerProvider.notifier).setTraveller(index, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(bookingControllerProvider);
    final price = ref.watch(bookingPriceProvider);
    final flight = draft.outbound;
    final fare = draft.fare;
    if (flight == null || fare == null) return const NoBookingInProgress();
    final n = draft.travellerCount;
    final missing = draft.travellers.where((t) => t == null).length;

    return BookingScaffold(
      title: 'Passengers',
      step: 1,
      bottomBar: SysflyBottomBar(
        title: Fmt.money(price.total),
        subtitle: missing > 0
            ? 'Add details for $missing more ${missing == 1 ? 'traveller' : 'travellers'}'
            : '${n == 1 ? '1 traveller' : '$n travellers'} · ${fare.name} fare',
        action: BookingContinueButton(onPressed: draft.travellersComplete ? () => context.push(Routes.seats) : null),
      ),
      children: [
        TrText(
          '${flight.origin.code} → ${flight.destination.code} · ${Fmt.dayMonth(flight.departure)}',
          style: SysflyTypography.caption.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 6),
        Semantics(header: true, child: TrText('Who’s flying?', style: SysflyTypography.headline)),
        const SizedBox(height: 4),
        TrText('Enter your details exactly as on your passport', style: SysflyTypography.bodySecondary),
        const SizedBox(height: 18),
        for (var i = 0; i < n; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _TravellerCard(
              index: i,
              passenger: draft.travellers[i],
              onEdit: () => _editTraveller(context, ref, draft, i),
            ),
          ),
        SysflyCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SysflyIconTile(icon: SysflyIcons.email, size: 42),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrText('Contact details', style: SysflyTypography.cardTitle),
                        const SizedBox(height: 3),
                        TrText('E-tickets and flight updates go here', style: SysflyTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Semantics(
                button: true,
                label: 'Edit contact details. Email ${draft.contact.email}, mobile ${draft.contact.phone}',
                child: SysflyPressable(
                  onTap: () async {
                    final contact = await showContactSheet(context, initial: draft.contact);
                    if (contact != null) ref.read(bookingControllerProvider.notifier).setContact(contact);
                  },
                  pressedScale: 0.985,
                  child: ExcludeSemantics(
                    child: SysflyFieldBox(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          _ContactLine(label: 'Email', value: draft.contact.email),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE4E7F0)),
                          _ContactLine(label: 'Mobile number', value: draft.contact.phone),
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
        Row(
          children: [
            const SysflyIcon(SysflyIcons.lock, size: 14, color: SysflyColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: TrText(
                'Passport details go to the airline and border control, and nowhere else',
                style: SysflyTypography.caption.copyWith(fontSize: 10.5, letterSpacing: -0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrText(label, style: SysflyTypography.caption.copyWith(fontSize: 11.5, color: SysflyColors.textSecondary)),
            const SizedBox(height: 5),
            TrText(value, style: SysflyTypography.bodyStrong),
          ],
        ),
      ),
    );
  }
}

class _TravellerCard extends StatelessWidget {
  const _TravellerCard({required this.index, required this.passenger, required this.onEdit});

  final int index;
  final Passenger? passenger;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = passenger;
    if (p == null) {
      return SysflyCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SysflyInitials(initials: '${index + 1}', size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TrText('Traveller ${index + 1} · Adult', style: SysflyTypography.caption),
                  const SizedBox(height: 2),
                  TrText('Details needed', style: SysflyTypography.cardTitle),
                ],
              ),
            ),
            SysflyOutlineButton(
              key: ValueKey('traveller-add-$index'),
              label: 'Add details',
              icon: SysflyIcons.plus,
              height: 40,
              onPressed: onEdit,
            ),
          ],
        ),
      );
    }
    return SysflyCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SysflyInitials(initials: p.initials, size: 44, verified: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrText(
                      'Traveller ${index + 1} · Adult · ${p.title.label}${p.isAccountHolder ? ' · You' : ''}',
                      style: SysflyTypography.caption,
                    ),
                    const SizedBox(height: 2),
                    TrText(p.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.cardTitle),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Edit ${p.fullName}',
                child: SysflyPressable(
                  key: ValueKey('traveller-edit-$index'),
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ExcludeSemantics(child: TrText('Edit', style: SysflyTypography.link)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Fact(label: 'Date of birth', value: Fmt.full(p.dateOfBirth))),
              Expanded(child: _Fact(label: 'Nationality', value: p.nationality)),
            ],
          ),
          const SizedBox(height: 14),
          for (final pair in _documentFacts(p)) ...[
            Row(children: [for (final fact in pair) Expanded(child: fact)]),
            if (pair != _documentFacts(p).last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

/// Identity facts in pairs: national ID, passport and Miles&Smiles number
/// where the traveller has them.
List<List<Widget>> _documentFacts(Passenger p) {
  final facts = <Widget>[
    if (p.nationalId != null) _Fact(label: 'T.C. identity number', value: p.maskedNationalId),
    if (p.hasPassport) _Fact(label: 'Passport', value: p.maskedPassport),
    if (p.hasPassport && p.passportExpiry != null) _Fact(label: 'Expires', value: Fmt.full(p.passportExpiry!)),
    if (p.frequentFlyer != null) _Fact(label: 'Miles&Smiles', value: p.frequentFlyer!),
  ];
  return [
    for (var i = 0; i < facts.length; i += 2) [facts[i], if (i + 1 < facts.length) facts[i + 1] else const SizedBox()],
  ];
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrText(label, style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
        const SizedBox(height: 4),
        TrText(value, style: SysflyTypography.bodyStrong.copyWith(fontSize: 14)),
      ],
    );
  }
}
