import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysfly/app/theme/app_theme.dart';
import 'package:sysfly/core/services/haptics.dart';
import 'package:sysfly/core/utils/clock.dart';
import 'package:sysfly/data/repositories/providers.dart';

/// Logical size of the reference device (iPhone 17 Pro Max).
const Size referenceSize = Size(440, 956);

bool _fontsLoaded = false;

/// Loads every font declared in the app and its packages, so text and icons
/// render for real instead of as test placeholder boxes.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_fontsLoaded) return;
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in entry['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

/// A clock pinned to the demo anchor with a fixed afternoon greeting, which
/// is what the reference recording shows.
class TestClock implements Clock {
  const TestClock({this.hour = 16});
  final int hour;

  @override
  DateTime now() => DemoClock.anchor;

  @override
  int deviceHour() => hour;
}

/// Repository overrides that respond immediately.
List<Override> fastOverrides({Duration bookingLatency = Duration.zero}) => [
      clockProvider.overrideWithValue(const TestClock()),
      authRepositoryProvider.overrideWithValue(DemoAuthRepository(latency: Duration.zero)),
      flightRepositoryProvider.overrideWithValue(DemoFlightRepository(latency: Duration.zero)),
      bookingRepositoryProvider.overrideWith(
        (ref) => DemoBookingRepository(
          flights: ref.watch(flightRepositoryProvider),
          clock: ref.watch(clockProvider),
          latency: bookingLatency,
          // A fixed seed keeps generated booking references stable.
          random: Random(7),
        ),
      ),
      flightStatusRepositoryProvider.overrideWith(
        (ref) => DemoFlightStatusRepository(clock: ref.watch(clockProvider), latency: Duration.zero),
      ),
    ];

/// Sizes the test view like the reference iPhone, safe areas included.
void useReferenceDevice(WidgetTester tester, {Size size = referenceSize, double pixelRatio = 2}) {
  SysflyHaptics.enabled = false;
  tester.view.devicePixelRatio = pixelRatio;
  tester.view.physicalSize = size * pixelRatio;
  tester.view.padding = FakeViewPadding(top: 62 * pixelRatio, bottom: 34 * pixelRatio);
  tester.view.viewPadding = FakeViewPadding(top: 62 * pixelRatio, bottom: 34 * pixelRatio);
  addTearDown(tester.view.reset);
}

/// Pumps [child] inside the app theme and a [ProviderScope].
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  bool disableAnimations = false,
  Duration bookingLatency = Duration.zero,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...fastOverrides(bookingLatency: bookingLatency), ...overrides],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
          child: app!,
        ),
        home: child,
      ),
    ),
  );
}
