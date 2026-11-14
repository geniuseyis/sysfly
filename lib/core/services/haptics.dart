import 'package:flutter/services.dart';

/// Light, selection-level haptics. Kept behind one switch so the settings
/// sheet can turn them off.
abstract final class SysflyHaptics {
  static bool enabled = true;

  /// Tab changes, chips, seats, toggles.
  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Primary buttons.
  static void tap() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Booking confirmed.
  static void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
