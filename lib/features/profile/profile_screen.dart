import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/clock.dart';
import '../../data/mock/demo_catalog.dart';
import '../../shared/widgets/widgets.dart';
import '../authentication/auth_controller.dart';
import '../booking/booking_controller.dart';
import '../my_flights/trips_controller.dart';
import '../shell/shell_controller.dart';
import 'widgets/profile_sheets.dart';

/// Profile tab: the traveller, their stats, account sections and preferences.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final upcoming = ref.watch(upcomingTripsProvider).length;
    final flown = ref.watch(pastTripsProvider).length;
    final cities = ref.watch(citiesVisitedProvider);
    final cards = ref.watch(paymentMethodsProvider).valueOrNull?.length ?? 0;
    final seat = ref.watch(seatPreferenceProvider);
    final haptics = ref.watch(hapticsSettingProvider);
    final passportValid = user.traveller.passportExpiry?.isAfter(ref.watch(clockProvider).now()) ?? false;

    return ColoredBox(
      color: SysflyColors.background,
      child: Column(
        children: [
          SysflyHeader.brand(
            title: 'Profile',
            trailing: SysflyCircleButton(
              icon: SysflyIcons.settings,
              semanticLabel: 'Settings',
              onTap: () => showSettingsSheet(context),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 24, SysflySpacing.page, SysflySpacing.navClearance),
              children: [
                Center(child: SysflyAvatar(name: user.displayName)),
                const SizedBox(height: 20),
                TrText(user.displayName, textAlign: TextAlign.center, style: SysflyTypography.title.copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                TrText(user.email, textAlign: TextAlign.center, style: SysflyTypography.bodySecondary),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SysflyIcon(SysflyIcons.pin, size: 14, color: SysflyColors.textSecondary),
                    const SizedBox(width: 5),
                    TrText(
                      'Flies from ${user.homeCity} · ${user.homeAirportCode}',
                      style: SysflyTypography.captionStrong.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: SysflyOutlineButton(
                    label: 'Edit profile',
                    icon: SysflyIcons.edit,
                    height: 42,
                    onPressed: () => showEditProfileSheet(context),
                  ),
                ),
                const SizedBox(height: 24),
                SysflyCard(
                  radius: SysflyRadius.xl,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      _Stat(value: flown, label: 'Trips flown'),
                      const _StatDivider(),
                      _Stat(value: cities, label: 'Cities'),
                      const _StatDivider(),
                      _Stat(value: upcoming, label: 'Upcoming'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const _GroupLabel('Account'),
                SysflyCard(
                  radius: SysflyRadius.xl,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Column(
                    children: [
                      _Row(icon: SysflyIcons.user, title: 'Personal information', onTap: () => context.push(Routes.personalInfo)),
                      const _RowDivider(),
                      _Row(
                        icon: SysflyIcons.travellers,
                        title: 'Saved travellers',
                        value: '${DemoCatalog.savedTravellers.length}',
                        onTap: () => context.push(Routes.savedTravellers),
                      ),
                      const _RowDivider(),
                      _Row(
                        icon: SysflyIcons.card,
                        title: 'Payment methods',
                        value: cards == 1 ? '1 card' : '$cards cards',
                        onTap: () => context.push(Routes.paymentMethods),
                      ),
                      const _RowDivider(),
                      _Row(
                        icon: SysflyIcons.documents,
                        title: 'Travel documents',
                        value: passportValid ? 'Valid' : 'Expired',
                        onTap: () => context.push(Routes.travelDocuments),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _GroupLabel('Preferences'),
                SysflyCard(
                  radius: SysflyRadius.xl,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Column(
                    children: [
                      _Row(
                        icon: SysflyIcons.seat,
                        title: 'Travel preferences',
                        value: seat.label,
                        onTap: () => showSeatPreferenceSheet(context),
                      ),
                      const _RowDivider(),
                      _Row(
                        icon: SysflyIcons.language,
                        title: 'Language',
                        value: ref.watch(languageProvider).englishName,
                        onTap: () => showLanguageSheet(context),
                      ),
                      const _RowDivider(),
                      _Row(
                        icon: SysflyIcons.bell,
                        title: 'Haptic feedback',
                        value: haptics ? 'On' : 'Off',
                        onTap: () => ref.read(hapticsSettingProvider.notifier).set(!haptics),
                        showChevron: false,
                        trailing: Switch.adaptive(
                          value: haptics,
                          activeTrackColor: SysflyColors.selected,
                          onChanged: (v) => ref.read(hapticsSettingProvider.notifier).set(v),
                        ),
                      ),
                      const _RowDivider(),
                      _Row(
                        icon: SysflyIcons.signOut,
                        title: 'Sign out',
                        danger: true,
                        showChevron: false,
                        onTap: () async {
                          await ref.read(authControllerProvider.notifier).signOut();
                          ref.read(navigationProvider.notifier).select(AppTab.home);
                          if (context.mounted) context.go(Routes.login);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: '$value $label',
        child: ExcludeSemantics(
          child: Column(
            children: [
              TrText('$value', style: SysflyTypography.title.copyWith(fontSize: 21)),
              const SizedBox(height: 3),
              TrText(label, style: SysflyTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 34, child: VerticalDivider(width: 1, thickness: 1, color: SysflyColors.divider));
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 12),
      child: Semantics(
        header: true,
        child: TrText(text, style: SysflyTypography.bodyStrong.copyWith(fontSize: 14, color: const Color(0xFF3D4052))),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, indent: 52, color: SysflyColors.divider);
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.trailing,
    this.showChevron = true,
    this.danger = false,
  });

  final SysflyIconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool showChevron;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: value == null ? title : '$title, $value',
      child: SysflyPressable(
        onTap: onTap,
        pressedScale: 0.985,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SysflyIconTile(
                icon: icon,
                size: 38,
                background: danger ? SysflyColors.errorBg : SysflyColors.tile,
                foreground: danger ? SysflyColors.error : SysflyColors.link,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ExcludeSemantics(
                  child: TrText(
                    title,
                    style: SysflyTypography.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: danger ? SysflyColors.error : SysflyColors.textBody,
                    ),
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (value != null)
                ExcludeSemantics(child: TrText(value!, style: SysflyTypography.bodySecondary.copyWith(fontSize: 13.5, color: SysflyColors.textTertiary))),
              if (showChevron) ...[
                const SizedBox(width: 10),
                const SysflyIcon(SysflyIcons.chevronRight, size: 14, color: Color(0xFFC6C9D4)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
