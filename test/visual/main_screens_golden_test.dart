import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysfly/features/authentication/login_screen.dart';
import 'package:sysfly/features/shell/main_shell.dart';
import 'package:sysfly/features/shell/shell_controller.dart';
import 'package:sysfly/features/splash/splash_screen.dart';

import '../support/harness.dart';

// Renders the screens that appear in the reference recording at the
// reference device size. The PNGs under goldens/ are compared against the
// video frames in docs/REFERENCE_ANALYSIS.md.
void main() {
  setUpAll(loadAppFonts);

  Future<void> shell(WidgetTester tester, AppTab tab) async {
    useReferenceDevice(tester);
    await pumpApp(tester, const MainShell());
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(MainShell)));
    container.read(navigationProvider.notifier).select(tab);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('splash, finished state', (tester) async {
    useReferenceDevice(tester);
    await pumpApp(tester, const SplashScreen());
    await tester.pump(const Duration(milliseconds: 2400));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/splash.png'));
  });

  testWidgets('login', (tester) async {
    useReferenceDevice(tester);
    await pumpApp(tester, const LoginScreen());
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/login.png'));
  });

  testWidgets('home', (tester) async {
    await shell(tester, AppTab.home);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home.png'));
  });

  testWidgets('my flights', (tester) async {
    await shell(tester, AppTab.flights);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/my_flights.png'));
  });

  testWidgets('flight status', (tester) async {
    await shell(tester, AppTab.status);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/flight_status.png'));
  });

  testWidgets('profile', (tester) async {
    await shell(tester, AppTab.profile);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/profile.png'));
  });
}
