import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock/demo_catalog.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../authentication/auth_controller.dart';
import '../booking/booking_controller.dart';
import '../booking/widgets/passenger_sheets.dart';
import '../checkout/widgets/payment_sheets.dart';
import 'widgets/profile_sheets.dart';

class _AccountScaffold extends StatelessWidget {
  const _AccountScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SysflyColors.background,
      body: Column(
        children: [
          SysflyHeader(title: title, onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(SysflySpacing.page, 22, SysflySpacing.page, 24 + MediaQuery.paddingOf(context).bottom),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              TrText(label, style: SysflyTypography.bodySecondary.copyWith(fontSize: 13.5)),
              const SizedBox(width: 16),
              Expanded(
                child: TrText(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SysflyTypography.bodyStrong.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
      ],
    );
  }
}

/// Name, contact and home airport of the account holder.
class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final home = DemoCatalog.airport(user.homeAirportCode);
    return _AccountScaffold(
      title: 'Personal information',
      children: [
        SysflyCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Column(
            children: [
              _InfoRow(label: 'Name', value: user.displayName),
              _InfoRow(label: 'Email', value: user.email),
              _InfoRow(label: 'Mobile', value: user.phone),
              _InfoRow(label: 'Date of birth', value: Fmt.full(user.traveller.dateOfBirth)),
              _InfoRow(label: 'Home airport', value: '${home.name}, ${home.city} (${home.code})', last: true),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SysflyGradientButton(label: 'Edit profile', icon: SysflyIcons.edit, onPressed: () => showEditProfileSheet(context)),
      ],
    );
  }
}

/// Travellers saved for faster booking.
class SavedTravellersScreen extends ConsumerWidget {
  const SavedTravellersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AccountScaffold(
      title: 'Saved travellers',
      children: [
        for (final p in DemoCatalog.savedTravellers)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SysflyCard(
              radius: SysflyRadius.xl,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SysflyInitials(initials: p.initials, size: 44, verified: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrText(p.fullName, style: SysflyTypography.bodyStrong),
                        const SizedBox(height: 3),
                        TrText(
                          '${p.isAccountHolder ? 'You · ' : ''}${p.nationality} · Passport ${p.maskedPassport}',
                          style: SysflyTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        TrText(
          'Saved travellers are offered when you add passengers to a booking.',
          textAlign: TextAlign.center,
          style: SysflyTypography.caption,
        ),
      ],
    );
  }
}

/// Saved cards. Cards can be added and removed.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(paymentMethodsProvider).valueOrNull ?? const <PaymentMethod>[];
    return _AccountScaffold(
      title: 'Payment methods',
      children: [
        for (final card in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SysflyCard(
              radius: SysflyRadius.xl,
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  PaymentBrandMark(brand: card.brand),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrText(card.title, style: SysflyTypography.bodyStrong),
                        const SizedBox(height: 3),
                        TrText(card.subtitle, style: SysflyTypography.caption),
                      ],
                    ),
                  ),
                  if (!card.isDefault)
                    Semantics(
                      button: true,
                      label: 'Remove ${card.title}',
                      child: SysflyPressable(
                        key: ValueKey('remove-${card.id}'),
                        onTap: () async {
                          await ref.read(paymentMethodsProvider.notifier).remove(card);
                          if (context.mounted) showSysflyToast(context, '${card.title} removed');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: SysflyIcon(SysflyIcons.trash, size: 18, color: SysflyColors.error),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        SysflyGradientButton(
          key: const ValueKey('add-card-button'),
          label: 'Add a new card',
          icon: SysflyIcons.plus,
          onPressed: () async {
            final added = await showAddCardSheet(context);
            if (added != null && context.mounted) showSysflyToast(context, '${added.title} saved', icon: SysflyIcons.check);
          },
        ),
        const SizedBox(height: 14),
        TrText(
          'Only the card brand, last four digits and expiry are kept. This demo build never charges a card.',
          textAlign: TextAlign.center,
          style: SysflyTypography.caption,
        ),
      ],
    );
  }
}

/// Passport details of the account holder.
class TravelDocumentsScreen extends ConsumerWidget {
  const TravelDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final now = ref.watch(clockProvider).now();
    final p = user.traveller;
    final valid = p.passportExpiry?.isAfter(now) ?? false;
    return _AccountScaffold(
      title: 'Travel documents',
      children: [
        SysflyCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SysflyIconTile(icon: SysflyIcons.documents, size: 42),
                  const SizedBox(width: 14),
                  Expanded(child: TrText('Passport', style: SysflyTypography.cardTitle)),
                  SysflyStatusChip(label: valid ? 'Valid' : 'Expired', tone: valid ? SysflyChipTone.success : SysflyChipTone.danger),
                ],
              ),
              const SizedBox(height: 6),
              _InfoRow(label: 'Name', value: p.fullName),
              _InfoRow(label: 'Number', value: p.maskedPassport),
              _InfoRow(label: 'Nationality', value: p.nationality),
              _InfoRow(label: 'Expires', value: p.passportExpiry == null ? '\u2014' : Fmt.full(p.passportExpiry!), last: true),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SysflyGradientButton(
          label: 'Update passport',
          icon: SysflyIcons.edit,
          onPressed: () async {
            final updated = await showTravellerSheet(
              context,
              title: 'Passport',
              id: p.id,
              travelDate: now,
              today: now,
              initial: p,
            );
            if (updated != null) {
              ref.read(authControllerProvider.notifier).updateProfile(user.copyWith(traveller: updated));
              if (context.mounted) showSysflyToast(context, 'Passport updated', icon: SysflyIcons.check);
            }
          },
        ),
      ],
    );
  }
}
