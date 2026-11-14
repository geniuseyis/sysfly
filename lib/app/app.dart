import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_brand.dart';
import '../core/l10n/l10n.dart';
import '../features/shell/shell_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SysflyApp extends ConsumerWidget {
  const SysflyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reading the setting applies the stored haptics preference at start-up.
    ref.watch(hapticsSettingProvider);
    // When the language changes every widget is rebuilt so all text, however
    // it was assembled, is produced again in the new language.
    ref.watch(languageProvider);
    ref.listen(languageProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) rebuildAllBelow(context);
      });
    });
    return MaterialApp.router(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Large accessibility text sizes are honoured up to 1.3x; beyond that
        // the dense ticket layouts would clip.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: media.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3)),
          child: child!,
        );
      },
    );
  }
}
