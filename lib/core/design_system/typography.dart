import 'package:flutter/painting.dart';

import 'colors.dart';

/// Typography tokens. The reference typeface is Plus Jakarta Sans; the brand
/// wordmark uses a connected script (Playball). Both are bundled under OFL.
abstract final class SysflyTypography {
  static const String family = 'PlusJakartaSans';
  static const String brandFamily = 'Playball';

  static const TextStyle _base = TextStyle(
    fontFamily: family,
    color: SysflyColors.textPrimary,
    height: 1.25,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Screen hero title, e.g. "Where Are You Going?".
  static final hero = _base.copyWith(fontSize: 25, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.2);

  /// Large page headline, e.g. "Choose your fare".
  static final headline = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2);

  /// Sheet and auth titles, e.g. "Welcome back".
  static final title = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4);

  /// Section titles, e.g. "Popular Flight Routes".
  static final section = _base.copyWith(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3);

  /// Card titles.
  static final cardTitle = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2);

  /// Compact header title, e.g. "My Flights".
  static final headerTitle = _base.copyWith(fontSize: 16.5, fontWeight: FontWeight.w600, color: const Color(0xFFFFFFFF), letterSpacing: -0.1);

  /// Airport codes on tickets.
  static final airportCode = _base.copyWith(fontSize: 29, fontWeight: FontWeight.w700, letterSpacing: -0.6, height: 1.1);

  /// Fare price on ticket stubs.
  static final price = _base.copyWith(fontSize: 27, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: SysflyColors.royalText, height: 1.1);

  /// Checkout total.
  static final total = _base.copyWith(fontSize: 25, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.1);

  static final bodyStrong = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.1);
  static final body = _base.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600, color: SysflyColors.textBody);
  static final bodySecondary = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: SysflyColors.textSecondary);
  static final caption = _base.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, color: SysflyColors.textTertiary);
  static final captionStrong = _base.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: SysflyColors.textSecondary);

  /// Field labels such as "Departure".
  static final fieldLabel = _base.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, color: SysflyColors.textTertiary);

  /// Field values such as "Fri, 4 Sep".
  static final fieldValue = _base.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: -0.2);

  /// Small caps labels on tickets ("FROM", "FLIGHT").
  static final overline = _base.copyWith(fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 1.3, color: SysflyColors.textTertiary);

  /// Ticket numbers and values under an overline.
  static final ticketValue = _base.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: -0.1);

  static final button = _base.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFFFFFFFF), letterSpacing: -0.1);
  static final link = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: SysflyColors.link);
  static final navLabel = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.1);
  static final chip = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w700);

  /// Brand wordmark.
  static TextStyle brand(double size) => TextStyle(
        fontFamily: brandFamily,
        fontSize: size,
        color: const Color(0xFFFFFFFF),
        height: 1.0,
        letterSpacing: 0.2,
      );
}
