import 'package:flutter/painting.dart';

import 'colors.dart';

/// Gradient tokens (stops measured from the reference video).
abstract final class SysflyGradients {
  /// Splash background, top to bottom.
  static const splash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [SysflyColors.ink, Color(0xFF0E102F), Color(0xFF131545), Color(0xFF1A2366), Color(0xFF243488)],
    stops: [0.0, 0.16, 0.42, 0.68, 1.0],
  );

  /// Screen headers, top to bottom.
  static const header = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [SysflyColors.navy, SysflyColors.navyMid, SysflyColors.navyLight],
    stops: [0.0, 0.55, 1.0],
  );

  /// Primary buttons and selected pills, left to right.
  static const primary = LinearGradient(
    colors: [SysflyColors.indigo, SysflyColors.indigoMid, SysflyColors.royal],
    stops: [0.0, 0.32, 1.0],
  );

  /// Navigation indicator and ticket shortcut.
  static const indicator = LinearGradient(
    colors: [Color(0xFF171E61), Color(0xFF2D3EA8)],
  );

  /// Ticket header strip.
  static const ticketStrip = LinearGradient(
    colors: [Color(0xFF0F1235), Color(0xFF243285)],
  );

  /// Boarding pass body, diagonal.
  static const boardingPass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF101237), Color(0xFF161A52), Color(0xFF1D3080)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Flight results hero header.
  static const hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF101A4C), Color(0xFF18276C), Color(0xFF233A90)],
    stops: [0.0, 0.5, 1.0],
  );
}
