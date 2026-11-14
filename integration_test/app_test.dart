import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sysfly/app/app.dart';
import 'package:sysfly/features/shell/main_shell.dart';
import 'package:sysfly/features/shell/shell_controller.dart';
import 'package:sysfly/shared/widgets/widgets.dart';

// Runs on a device or emulator:
//   flutter test integration_test/app_test.dart -d <device id>
//
// Set HOLD to keep each navigation state on screen for that many seconds,
// which leaves time to look at (or capture) the glass effects:
//   flutter test integration_test/app_test.dart -d <device id> --dart-define=HOLD=8
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const hold = Duration(seconds: int.fromEnvironment('HOLD'));

  Future<void> wait(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('sign in, switch tabs and drag the navigation lens', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SysflyApp()));

    // Splash runs for about three seconds, then the login form appears.
    await wait(tester, const Duration(seconds: 5));
    await tester.enterText(find.byKey(const ValueKey('login-email')), 'traveller@example.com');
    await tester.enterText(find.byKey(const ValueKey('login-password')), 'secret1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await wait(tester, const Duration(seconds: 5));
    expect(find.byType(MainShell), findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(find.byType(MainShell)));
    final bar = find.byKey(SysflyFloatingNavigationBar.barKey);
    final box = tester.getRect(bar);
    Offset tab(int index) => Offset(box.left + box.width * (index * 2 + 1) / 8, box.center.dy);

    // Tapping each tab selects it.
    for (final target in [AppTab.flights, AppTab.status, AppTab.profile, AppTab.home]) {
      await tester.tapAt(tab(target.index));
      await wait(tester, const Duration(milliseconds: 700));
      expect(container.read(navigationProvider), target);
    }
    debugPrint('SYSFLY-STATE rest');
    await wait(tester, hold);

    // Dragging the capsule turns it into a lens that follows the finger and
    // selects the tab it is released over.
    final gesture = await tester.startGesture(tab(0));
    await wait(tester, const Duration(milliseconds: 100));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(box.width * 3 / 8 / 10, 0));
      await wait(tester, const Duration(milliseconds: 30));
    }
    debugPrint('SYSFLY-STATE lens');
    await wait(tester, hold);
    await gesture.up();
    await wait(tester, const Duration(seconds: 1));
    expect(container.read(navigationProvider), isNot(AppTab.home));
    await wait(tester, hold);
  });
}
