import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';

/// Material theme wired to the sysfly tokens. Screens style themselves from
/// the design system; this only covers framework-drawn pieces such as text
/// selection, dialogs and route transitions.
abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: SysflyColors.selected,
      brightness: Brightness.light,
      primary: SysflyColors.selected,
      surface: SysflyColors.surface,
      error: SysflyColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: SysflyTypography.family,
      scaffoldBackgroundColor: SysflyColors.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: SysflyColors.indigoMid,
        selectionColor: Color(0x3324348A),
        selectionHandleColor: SysflyColors.selected,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: SysflyColors.selected),
      // iOS-style push and swipe-back on every platform.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
