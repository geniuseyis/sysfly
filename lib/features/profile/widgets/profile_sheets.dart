import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_brand.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/utils/validators.dart';
import '../../../data/mock/demo_catalog.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../airports/airport_sheet.dart';
import '../../authentication/auth_controller.dart';
import '../../shell/shell_controller.dart';

/// Edits the display name, email and home airport.
Future<void> showEditProfileSheet(BuildContext context) =>
    showSysflySheet<void>(context, builder: (_) => const _EditProfileSheet());

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _name = TextEditingController(text: ref.read(currentUserProvider).displayName);
  late final _email = TextEditingController(text: ref.read(currentUserProvider).email);
  late Airport _home = DemoCatalog.airport(ref.read(currentUserProvider).homeAirportCode);
  String? _nameError;
  String? _emailError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    final nameError = Validators.required(_name.text, 'your name');
    final emailError = Validators.email(_email.text);
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
    });
    if (nameError != null || emailError != null) return;
    final user = ref.read(currentUserProvider);
    ref.read(authControllerProvider.notifier).updateProfile(
          user.copyWith(
            displayName: _name.text.trim(),
            email: _email.text.trim(),
            homeCity: _home.city,
            homeAirportCode: _home.code,
          ),
        );
    Navigator.of(context).pop();
    showSysflyToast(context, 'Profile updated', icon: SysflyIcons.check);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SysflySheetTitle(title: 'Edit profile'),
          const SizedBox(height: 16),
          SysflyTextField(
            controller: _name,
            label: 'Name',
            hint: 'Your name',
            icon: SysflyIcons.user,
            textCapitalization: TextCapitalization.words,
            errorText: _nameError,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: 12),
          SysflyTextField(
            controller: _email,
            label: 'Email',
            hint: 'Your email',
            icon: SysflyIcons.email,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: (_) => setState(() => _emailError = null),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: TrText('Home airport', style: SysflyTypography.captionStrong),
          ),
          Semantics(
            button: true,
            label: 'Home airport, ${_home.city}, ${_home.code}',
            child: SysflyPressable(
              onTap: () async {
                final airport = await showAirportSheet(context, title: 'Home airport', selected: _home);
                if (airport != null) setState(() => _home = airport);
              },
              pressedScale: 0.985,
              child: ExcludeSemantics(
                child: SysflyFieldBox(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SysflyFlag(countryCode: _home.countryCode, size: 32),
                      const SizedBox(width: 12),
                      Expanded(child: TrText('${_home.city} · ${_home.code}', style: SysflyTypography.bodyStrong)),
                      const SysflyIcon(SysflyIcons.chevronDown, size: 14, color: SysflyColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SysflyGradientButton(label: 'Save changes', onPressed: _save),
        ],
      ),
    );
  }
}

/// Seat preference used when a seat is assigned automatically.
Future<void> showSeatPreferenceSheet(BuildContext context) {
  return showSysflySheet<void>(
    context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(seatPreferenceProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SysflySheetTitle(title: 'Travel preferences', subtitle: 'Used when a seat is assigned for you'),
              const SizedBox(height: 16),
              for (final option in SeatPreference.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    button: true,
                    selected: option == current,
                    label: option.label,
                    child: SysflyPressable(
                      onTap: () => ref.read(seatPreferenceProvider.notifier).set(option),
                      pressedScale: 0.985,
                      child: ExcludeSemantics(
                        child: SysflyFieldBox(
                          selected: option == current,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          child: Row(
                            children: [
                              const SysflyIcon(SysflyIcons.seat, size: 20, color: SysflyColors.link),
                              const SizedBox(width: 14),
                              Expanded(child: TrText(option.label, style: SysflyTypography.bodyStrong)),
                              SysflyRadioCheck(selected: option == current),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              SysflyGradientButton(label: 'Done', onPressed: () => Navigator.of(sheetContext).pop()),
            ],
          ),
        );
      },
    ),
  );
}

/// App settings and build information.
Future<void> showSettingsSheet(BuildContext context) {
  return showSysflySheet<void>(
    context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final haptics = ref.watch(hapticsSettingProvider);
        final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        return Padding(
          padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SysflySheetTitle(title: 'Settings'),
              const SizedBox(height: 16),
              SysflyFieldBox(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrText('Haptic feedback', style: SysflyTypography.bodyStrong),
                          const SizedBox(height: 2),
                          TrText('Light taps on tabs, seats and buttons', style: SysflyTypography.caption),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: haptics,
                      activeTrackColor: SysflyColors.selected,
                      onChanged: (v) => ref.read(hapticsSettingProvider.notifier).set(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SysflyFieldBox(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrText('Reduce Motion', style: SysflyTypography.bodyStrong),
                          const SizedBox(height: 2),
                          TrText('Follows the iOS accessibility setting', style: SysflyTypography.caption),
                        ],
                      ),
                    ),
                    TrText(reduceMotion ? 'On' : 'Off', style: SysflyTypography.captionStrong),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TrText(AppBrand.demoNotice, textAlign: TextAlign.center, style: SysflyTypography.caption),
              const SizedBox(height: 4),
              TrText('${AppBrand.name} 1.0.0', textAlign: TextAlign.center, style: SysflyTypography.caption),
              const SizedBox(height: 16),
              SysflyGradientButton(label: 'Done', onPressed: () => Navigator.of(sheetContext).pop()),
            ],
          ),
        );
      },
    ),
  );
}

/// Lets the traveller choose the app language.
Future<void> showLanguageSheet(BuildContext context) {
  return showSysflySheet<void>(
    context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(languageProvider);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SysflySheetTitle(title: 'Language', subtitle: 'Choose the language of the app'),
              const SizedBox(height: 16),
              for (final language in AppLanguage.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Semantics(
                    button: true,
                    selected: language == current,
                    label: tr(language.englishName),
                    child: SysflyPressable(
                      key: ValueKey('language-${language.code}'),
                      onTap: () => ref.read(languageProvider.notifier).set(language),
                      pressedScale: 0.985,
                      child: ExcludeSemantics(
                        child: SysflyFieldBox(
                          selected: language == current,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          child: Row(
                            children: [
                              // Named in the language currently selected.
                              Expanded(child: TrText(language.englishName, style: SysflyTypography.bodyStrong)),
                              SysflyRadioCheck(selected: language == current),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SysflyGradientButton(label: 'Done', onPressed: () => Navigator.of(sheetContext).pop()),
            ],
          ),
        );
      },
    ),
  );
}
