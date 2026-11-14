import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysfly/app/app.dart';
import 'package:sysfly/core/services/share_service.dart';
import 'package:sysfly/core/storage/key_value_store.dart';
import 'package:sysfly/features/shell/main_shell.dart';

import 'harness.dart';

/// Records what the app tried to share instead of opening a share sheet.
class RecordingShareService implements ShareService {
  final List<String> texts = [];
  final Map<String, List<int>> files = {};

  @override
  Future<void> shareText({required String text, String? subject, Rect? origin}) async => texts.add(text);

  @override
  Future<void> shareFile({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
    String? subject,
    Rect? origin,
  }) async =>
      files[fileName] = bytes;
}

/// Boots the whole app (real router, demo repositories without latency).
Future<RecordingShareService> pumpWholeApp(
  WidgetTester tester, {
  KeyValueStore? store,
  List<Override> overrides = const [],
}) async {
  final share = RecordingShareService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fastOverrides(),
        keyValueStoreProvider.overrideWithValue(store ?? MemoryKeyValueStore()),
        shareServiceProvider.overrideWithValue(share),
        ...overrides,
      ],
      child: const SysflyApp(),
    ),
  );
  return share;
}

/// Advances time in steps so animations and timers run to completion.
/// Unlike pumpAndSettle this is safe with endlessly repeating animations.
Future<void> settle(WidgetTester tester, [Duration total = const Duration(milliseconds: 1200)]) async {
  const step = Duration(milliseconds: 50);
  for (var elapsed = Duration.zero; elapsed < total; elapsed += step) {
    await tester.pump(step);
  }
}

/// Runs the splash and signs in through the login form.
Future<void> signIn(WidgetTester tester, {String email = 'traveller@example.com', String password = 'secret1'}) async {
  await settle(tester, const Duration(milliseconds: 4200));
  await tester.enterText(find.byKey(const ValueKey('login-email')).first, email);
  await tester.enterText(find.byKey(const ValueKey('login-password')).first, password);
  await tester.tap(find.byKey(const ValueKey('login-submit')));
  await settle(tester, const Duration(milliseconds: 2600));
  expect(find.byType(MainShell), findsOneWidget);
}

/// Scrolls [finder] into view inside the nearest vertical scrollable and
/// taps it.
Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // Lazily built list items do not exist until they are scrolled near.
    await tester.scrollUntilVisible(finder, 240, scrollable: find.byType(Scrollable).hitTestable().first, maxScrolls: 40);
  }
  await tester.ensureVisible(finder);
  await settle(tester, const Duration(milliseconds: 300));
  await tester.tap(finder);
  await settle(tester);
}
