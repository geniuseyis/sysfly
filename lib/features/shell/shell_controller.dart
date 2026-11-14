import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/services/haptics.dart';
import '../../core/storage/key_value_store.dart';

/// The four tabs of the main shell, in bar order.
enum AppTab { home, flights, status, profile }

class NavigationController extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void select(AppTab tab) => state = tab;
}

/// Which tab is showing. Anything can switch tabs by writing here.
final navigationProvider = NotifierProvider<NavigationController, AppTab>(NavigationController.new);

class HapticsSetting extends Notifier<bool> {
  @override
  bool build() {
    final enabled = ref.watch(keyValueStoreProvider).getBool(StorageKeys.hapticsEnabled, fallback: true);
    SysflyHaptics.enabled = enabled;
    return enabled;
  }

  Future<void> set(bool enabled) async {
    SysflyHaptics.enabled = enabled;
    state = enabled;
    await ref.read(keyValueStoreProvider).setBool(StorageKeys.hapticsEnabled, enabled);
  }
}

final hapticsSettingProvider = NotifierProvider<HapticsSetting, bool>(HapticsSetting.new);

enum SeatPreference {
  window('Window seat'),
  aisle('Aisle seat'),
  none('No preference');

  const SeatPreference(this.label);
  final String label;
}

class SeatPreferenceSetting extends Notifier<SeatPreference> {
  @override
  SeatPreference build() {
    final stored = ref.watch(keyValueStoreProvider).getString(StorageKeys.seatPreference);
    return SeatPreference.values.firstWhere((p) => p.name == stored, orElse: () => SeatPreference.window);
  }

  Future<void> set(SeatPreference preference) async {
    state = preference;
    await ref.read(keyValueStoreProvider).setString(StorageKeys.seatPreference, preference.name);
  }
}

final seatPreferenceProvider = NotifierProvider<SeatPreferenceSetting, SeatPreference>(SeatPreferenceSetting.new);

/// The language the app is shown in. Stored so it survives restarts.
class LanguageSetting extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final stored = ref.watch(keyValueStoreProvider).getString(StorageKeys.language);
    final language = AppLanguage.values.firstWhere((l) => l.code == stored, orElse: () => AppLanguage.en);
    L10n.use(language);
    return language;
  }

  Future<void> set(AppLanguage language) async {
    L10n.use(language);
    state = language;
    await ref.read(keyValueStoreProvider).setString(StorageKeys.language, language.code);
  }
}

final languageProvider = NotifierProvider<LanguageSetting, AppLanguage>(LanguageSetting.new);
