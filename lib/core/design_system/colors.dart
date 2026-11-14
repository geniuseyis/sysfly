import 'package:flutter/painting.dart';

/// Colour tokens. Values marked (measured) were sampled from the reference
/// video frames; the recording is H.264 so each channel carries about ±3 of
/// noise. See docs/DESIGN_SYSTEM.md.
abstract final class SysflyColors {
  // Brand navy scale (measured)
  static const ink = Color(0xFF0C0E2B);
  static const navy = Color(0xFF121443);
  static const navyMid = Color(0xFF1A2264);
  static const navyLight = Color(0xFF202E7E);
  static const indigo = Color(0xFF181D5A);
  static const indigoMid = Color(0xFF1A266E);
  static const royal = Color(0xFF2D41A7);
  static const selected = Color(0xFF24348A);

  // Text on light
  static const textPrimary = Color(0xFF05060F);
  static const textBody = Color(0xFF15161E);
  static const textSecondary = Color(0xFF555764);
  static const textTertiary = Color(0xFF858896);
  static const textDisabled = Color(0xFFC3C6D2);
  static const link = Color(0xFF1E2874);
  static const royalText = Color(0xFF25328B);

  // Surfaces (measured)
  static const background = Color(0xFFF2F3FA);
  static const surface = Color(0xFFFFFFFF);
  static const field = Color(0xFFF3F4FB);
  static const fieldBorder = Color(0xFFE6E8F2);
  static const divider = Color(0xFFECEEF5);
  static const tile = Color(0xFFE9EBFA);
  static const chip = Color(0xFFE6EAF8);

  // Status
  static const success = Color(0xFF1FB57E);
  static const successText = Color(0xFF2A8468);
  static const successBg = Color(0xFFE3F4EE);
  static const info = Color(0xFF2BB5E8);
  static const infoText = Color(0xFF1B6478);
  static const infoBg = Color(0xFFE6F4FC);
  static const warning = Color(0xFFF5A524);
  static const error = Color(0xFFE5484D);
  static const errorBg = Color(0xFFFDECEC);

  // Seats
  static const seatExtra = Color(0xFFC4EDFB);
  static const seatExtraBorder = Color(0xFF63C9EA);
  static const seatExtraText = Color(0xFF1D86A8);
  static const seatTaken = Color(0xFFDFE3EC);
  static const seatBorder = Color(0xFFD5D9E4);

  /// Header "bubble" buttons: a periwinkle glass tint, not plain white.
  /// 25 % of #7D90F3 over the header gives the measured #354293.
  static const bubble = Color(0x407D90F3);
  static const bubbleHighlight = Color(0x4D94A5FF);
  static const bubbleBorder = Color(0x3DB9C4FF);

  /// Text and dot of neutral chips such as "Departs in 10h 35m".
  static const chipText = Color(0xFF181C52);

  // Navigation
  static const navInactive = Color(0xFF3B3D4D);
  static const navInactiveLabel = Color(0xFF4E5378);

  // Login illustration
  static const skyTop = Color(0xFFC6DEF6);
  static const skyBottom = Color(0xFFE4F0FC);
}
