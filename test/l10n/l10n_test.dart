import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysfly/core/l10n/l10n.dart';
import 'package:sysfly/core/l10n/translations.dart';
import 'package:sysfly/core/storage/key_value_store.dart';
import 'package:sysfly/data/datasources/airport_catalog.dart';
import 'package:sysfly/data/generated/country_names.dart';
import 'package:sysfly/data/mock/demo_catalog.dart';
import 'package:sysfly/data/mock/demo_flights.dart';
import 'package:sysfly/data/mock/demo_seed.dart';
import 'package:sysfly/features/authentication/login_screen.dart';
import 'package:sysfly/features/booking/booking_controller.dart';
import 'package:sysfly/features/booking/fare_screen.dart';
import 'package:sysfly/features/booking/passengers_screen.dart';
import 'package:sysfly/features/checkout/review_screen.dart';
import 'package:sysfly/features/flight_search/flight_results_screen.dart';
import 'package:sysfly/features/home/search_controller.dart';
import 'package:sysfly/features/my_flights/trip_details_screen.dart';
import 'package:sysfly/features/notifications/notifications_screen.dart';
import 'package:sysfly/features/profile/account_screens.dart';
import 'package:sysfly/features/seats/seats_screen.dart';
import 'package:sysfly/features/shell/main_shell.dart';
import 'package:sysfly/features/shell/shell_controller.dart';

import '../support/app_harness.dart';
import '../support/harness.dart';

void main() {
  setUpAll(loadAppFonts);
  tearDown(() {
    L10n.use(AppLanguage.en);
    L10n.debugUntranslated = null;
  });

  group('translation table', () {
    test('every entry has all six languages', () {
      for (final table in [kTranslations, kTemplates]) {
        for (final entry in table.entries) {
          expect(entry.value, hasLength(6), reason: entry.key);
          expect(entry.value.every((v) => v.trim().isNotEmpty), isTrue, reason: entry.key);
        }
      }
    });

    test('templates keep every placeholder of their source', () {
      final placeholder = RegExp(r'\{(\d)');
      for (final entry in kTemplates.entries) {
        final wanted = placeholder.allMatches(entry.key).map((m) => m.group(1)).toSet();
        for (final value in entry.value) {
          final used = placeholder.allMatches(value).map((m) => m.group(1)).toSet();
          expect(used.difference(wanted), isEmpty, reason: '${entry.key} -> $value');
        }
      }
    });
  });

  group('engine', () {
    test('English is returned unchanged', () {
      expect(tr('Search Flight'), 'Search Flight');
    });

    test('exact strings', () {
      L10n.use(AppLanguage.tr);
      expect(tr('Search Flight'), 'Uçuş Ara');
      L10n.use(AppLanguage.de);
      expect(tr('Search Flight'), 'Flug suchen');
      L10n.use(AppLanguage.ar);
      expect(tr('Welcome back'), 'مرحباً بعودتك');
    });

    test('templates translate their parts', () {
      L10n.use(AppLanguage.tr);
      expect(tr('Departs in 10h 35m'), 'Kalkışa 10sa 35dk');
      expect(tr('Departs in 8 days'), 'Kalkışa 8 gün');
      expect(tr('Good Afternoon, Arya'), 'İyi günler, Arya');
      L10n.use(AppLanguage.fr);
      expect(tr('Show 6 flights'), 'Afficher 6 vols');
    });

    test('separators are split and each part translated', () {
      L10n.use(AppLanguage.tr);
      expect(tr('Fri, 4 Sep · Economy'), 'Cum, 4 Eyl · Ekonomi');
      expect(tr('1 traveller · Classic fare'), '1 yolcu · Classic tarifesi');
    });

    test('dates, month names and capitals', () {
      L10n.use(AppLanguage.tr);
      expect(tr('04 Sep 2026'), '04 Eyl 2026');
      expect(tr('September 2026'), 'Eylül 2026');
      expect(tr('FRI 4 SEP'), 'CUM 4 EYL');
      expect(tr('BOARDING PASS'), 'BİNİŞ KARTI');
      L10n.use(AppLanguage.de);
      expect(tr('Fri, 4 Sep'), 'Fr, 4 Sep');
    });

    test('Russian plural forms', () {
      L10n.use(AppLanguage.ru);
      expect(tr('1 trip'), '1 поездка');
      expect(tr('3 trips'), '3 поездки');
      expect(tr('5 trips'), '5 поездок');
      expect(tr('21 trips'), '21 поездка');
    });

    test('names, codes and amounts are left alone', () {
      L10n.use(AppLanguage.es);
      for (final text in ['Arya Pratama', 'GA 159', '\$128.00', 'DPS', '6:05 AM']) {
        expect(tr(text), text);
      }
    });
  });

  group('airport catalogue', () {
    testWidgets('loads every airport and keeps the popular ones first', (tester) async {
      final airports = (await tester.runAsync(AirportCatalog.load))!;
      expect(airports.length, greaterThan(3500));
      expect(airports.take(AirportCatalog.popularCount).map((a) => a.code), DemoCatalog.airports.map((a) => a.code));
      expect(airports.map((a) => a.code).toSet().length, airports.length, reason: 'codes are unique');

      final ist = airports.firstWhere((a) => a.code == 'IST');
      expect(ist.countryCode, 'TR');
      expect(ist.utcOffsetHours, 3);
      expect(airports.map((a) => a.countryCode).toSet().length, greaterThan(200));

      // Any pair of real airports yields bookable demo flights.
      final jfk = airports.firstWhere((a) => a.code == 'JFK');
      expect(DemoFlights.search(ist, jfk, DateTime(2026, 9, 4)), isNotEmpty);
    });

    test('country names are localized', () {
      L10n.use(AppLanguage.tr);
      expect(L10n.country('DE'), 'Almanya');
      L10n.use(AppLanguage.fr);
      expect(L10n.country('DE'), 'Allemagne');
      expect(kCountryNames.values.every((names) => names.length == 7), isTrue);
    });
  });

  testWidgets('changing the language updates the screen at once and is remembered', (tester) async {
    useReferenceDevice(tester);
    final store = MemoryKeyValueStore();
    await pumpWholeApp(tester, store: store);
    await signIn(tester);
    expect(find.text('Flights'), findsWidgets);

    final container = ProviderScope.containerOf(tester.element(find.byType(MainShell)));
    await container.read(languageProvider.notifier).set(AppLanguage.tr);
    await settle(tester, const Duration(milliseconds: 300));
    expect(find.text('Uçuşlar'), findsWidgets);
    expect(find.text('Uçuş Ara'), findsOneWidget);
    expect(find.text('Flights'), findsNothing);
    expect(store.getString(StorageKeys.language), 'tr');

    await container.read(languageProvider.notifier).set(AppLanguage.en);
    await settle(tester, const Duration(milliseconds: 300));
    expect(find.text('Search Flight'), findsOneWidget);
  });

  // Draws the main screens in every language. Layout overflows fail the
  // test; strings that stayed English are listed for Turkish.
  for (final language in AppLanguage.values.skip(1)) {
    testWidgets('screens render in ${language.nativeName}', (tester) async {
      useReferenceDevice(tester);
      final missing = <String>{};
      if (language == AppLanguage.tr) L10n.debugUntranslated = missing.add;
      L10n.use(language);
      await pumpApp(tester, const SizedBox(key: ValueKey('root')));
      final container = ProviderScope.containerOf(tester.element(find.byKey(const ValueKey('root'))));
      // Through the setting, as the app does; the Profile tab reads it.
      await container.read(languageProvider.notifier).set(language);

      final problems = <String>[];
      var tabName = '';
      Future<void> show(Widget screen) async {
        tester.state<NavigatorState>(find.byType(Navigator).first).push(
              PageRouteBuilder<void>(pageBuilder: (_, _, _) => screen, transitionDuration: Duration.zero),
            );
        await settle(tester, const Duration(milliseconds: 600));
        for (Object? error = tester.takeException(); error != null; error = tester.takeException()) {
          final where = error is FlutterError
              ? error.diagnostics.map((d) => d.toString()).where((l) => l.contains('.dart:')).take(1).join()
              : '';
          final summary = error.toString().replaceAll(RegExp(r'\s+'), ' ');
          problems.add('${screen.runtimeType}$tabName: ${summary.length > 70 ? summary.substring(0, 70) : summary} $where');
        }
      }

      await show(const LoginScreen());
      for (final tab in AppTab.values) {
        container.read(navigationProvider.notifier).select(tab);
        tabName = ' (${tab.name})';
        await show(const MainShell());
      }
      tabName = '';
      final date = DateTime(2026, 9, 4);
      container.read(searchControllerProvider.notifier).setRoute(
            origin: DemoCatalog.airport('DPS'),
            destination: DemoCatalog.airport('CGK'),
            date: date,
          );
      await show(const FlightResultsScreen());
      final flight = DemoFlights.search(DemoCatalog.airport('SIN'), DemoCatalog.airport('KUL'), date).first;
      container.read(bookingControllerProvider.notifier)
        ..start(outbound: flight, passengers: 2)
        ..selectSeat(0, DemoSeed.seatMap(flight).seat(15, 'C')!, standardPrice: 6)
        ..toggleExtra('baggage');
      await show(const FareScreen());
      await show(const PassengersScreen());
      await show(const SeatsScreen());
      await show(const ReviewScreen());
      await show(const TripDetailsScreen(reference: 'GA-4F7CMH'));
      await show(const NotificationsScreen());
      await show(const PersonalInfoScreen());
      await show(const PaymentMethodsScreen());
      await show(const TravelDocumentsScreen());

      expect(problems, isEmpty, reason: problems.join(' || '));
      if (language == AppLanguage.tr) {
        final words = RegExp(r'[a-z]{3,}');
        final leftovers = missing.where((s) => words.hasMatch(s)).toList()..sort();
        debugPrint('UNTRANSLATED (${leftovers.length}):\n${leftovers.join('\n')}');
      }
    });
  }
}
