import 'package:hugeicons/hugeicons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'custom_icons.dart';
import 'sysfly_icon.dart';

/// Icon tokens. The reference uses the Hugeicons rounded stroke family
/// (matched icon by icon against enlarged reference crops); the solid icons
/// of selected states are the same outlines filled in. Two brand-style
/// glyphs that Hugeicons' free set lacks come from Phosphor.
abstract final class SysflyIcons {
  // Navigation: outline when idle, filled when selected.
  static const home = SysflyIconData.vector(SysflyCustomIcons.home);
  static const homeFill = SysflyIconData.vector(SysflyCustomIcons.home, fill: {0}, cut: {1});
  static const flights = SysflyIconData.vector(HugeIcons.strokeRoundedAirplane01);
  static const flightsFill = SysflyIconData.vector(HugeIcons.strokeRoundedAirplane01, fill: {0});
  static const status = SysflyIconData.vector(HugeIcons.strokeRoundedLocation05);
  static const statusFill = SysflyIconData.vector(HugeIcons.strokeRoundedLocation05, fill: {1}, cut: {0});
  static const profile = SysflyIconData.vector(HugeIcons.strokeRoundedUser);
  static const profileFill = SysflyIconData.vector(HugeIcons.strokeRoundedUser, fill: {0, 1});

  // Header actions
  static const back = SysflyIconData.vector(HugeIcons.strokeRoundedArrowLeft01);
  static const bell = SysflyIconData.vector(HugeIcons.strokeRoundedNotification01);
  static const search = SysflyIconData.vector(HugeIcons.strokeRoundedSearch01);
  static const settings = SysflyIconData.vector(HugeIcons.strokeRoundedSettings01);
  static const filter = SysflyIconData.vector(HugeIcons.strokeRoundedFilterHorizontal);
  static const share = SysflyIconData.vector(HugeIcons.strokeRoundedShare08);

  // Search form
  static const swap = SysflyIconData.vector(HugeIcons.strokeRoundedArrowDataTransferHorizontal);
  static const calendar = SysflyIconData.vector(HugeIcons.strokeRoundedCalendar03);
  static const calendarAdd = SysflyIconData.vector(HugeIcons.strokeRoundedCalendarAdd01);
  static const returnTrip = SysflyIconData.vector(HugeIcons.strokeRoundedArrowDataTransferHorizontal);
  static const passengers = SysflyIconData.vector(HugeIcons.strokeRoundedUserMultiple);
  static const cabin = SysflyIconData.vector(HugeIcons.strokeRoundedDashboardSquare01);
  static const plus = SysflyIconData.vector(HugeIcons.strokeRoundedAdd01);
  static const minus = SysflyIconData.vector(HugeIcons.strokeRoundedRemove01);
  static const chevronDown = SysflyIconData.vector(HugeIcons.strokeRoundedArrowDown01);
  static const chevronRight = SysflyIconData.vector(HugeIcons.strokeRoundedArrowRight01);
  static const chevronLeft = SysflyIconData.vector(HugeIcons.strokeRoundedArrowLeft01);

  // Flights
  static const plane = SysflyIconData.vector(HugeIcons.strokeRoundedAirplaneMode, fill: {0});
  static const planeTilt = SysflyIconData.vector(HugeIcons.strokeRoundedAirplane01, fill: {0});
  static const planeOutline = SysflyIconData.vector(HugeIcons.strokeRoundedAirplaneMode);
  static const checkIn = SysflyIconData.vector(HugeIcons.strokeRoundedLogin03);
  static const clock = SysflyIconData.vector(HugeIcons.strokeRoundedClock01);

  /// Radar sweep, mirrored so the sweep points up-left as in the reference.
  static const target = SysflyIconData.vector(HugeIcons.strokeRoundedRadar02, mirrored: true);
  static const lightning = SysflyIconData.vector(HugeIcons.strokeRoundedFlash, fill: {0});
  static const ticket = SysflyIconData.vector(HugeIcons.strokeRoundedCoupon03);
  static const copy = SysflyIconData.vector(HugeIcons.strokeRoundedCopy01);
  static const info = SysflyIconData.vector(HugeIcons.strokeRoundedInformationCircle);

  // Forms
  static const email = SysflyIconData.vector(HugeIcons.strokeRoundedMail01);
  static const lock = SysflyIconData.vector(HugeIcons.strokeRoundedSquareLock02);
  static const eye = SysflyIconData.vector(HugeIcons.strokeRoundedView);
  static const eyeOff = SysflyIconData.vector(HugeIcons.strokeRoundedViewOffSlash);
  static const check = SysflyIconData.vector(HugeIcons.strokeRoundedTick02);
  static const close = SysflyIconData.vector(HugeIcons.strokeRoundedCancel01);
  static const edit = SysflyIconData.vector(HugeIcons.strokeRoundedEdit02);
  static const user = SysflyIconData.vector(HugeIcons.strokeRoundedUser);
  static const warning = SysflyIconData.vector(HugeIcons.strokeRoundedAlert02);

  // Extras and fares
  static const bag = SysflyIconData.vector(HugeIcons.strokeRoundedShoppingBag02);
  static const shield = SysflyIconData.vector(HugeIcons.strokeRoundedSecurityCheck);
  static const insurance = SysflyIconData.vector(HugeIcons.strokeRoundedActivity01);
  static const seat = SysflyIconData.vector(HugeIcons.strokeRoundedSeatSelector);
  static const lavatory = SysflyIconData.vector(HugeIcons.strokeRoundedToilet01);
  static const galley = SysflyIconData.vector(HugeIcons.strokeRoundedCoffee02);

  // Checkout
  static const card = SysflyIconData.vector(HugeIcons.strokeRoundedCreditCard);
  static const promo = SysflyIconData.vector(HugeIcons.strokeRoundedCouponPercent);
  static const sealCheck = SysflyIconData.glyph(PhosphorIconsFill.sealCheck);
  static const apple = SysflyIconData.glyph(PhosphorIconsFill.appleLogo);

  // Trip actions
  static const boardingPass = SysflyIconData.vector(HugeIcons.strokeRoundedQrCodeScan);
  static const eTicket = SysflyIconData.vector(HugeIcons.strokeRoundedFileDownload);
  static const cancel = SysflyIconData.vector(HugeIcons.strokeRoundedCancelSquare);

  // Filters
  static const reset = SysflyIconData.vector(HugeIcons.strokeRoundedRefresh);
  static const morning = SysflyIconData.vector(HugeIcons.strokeRoundedSunrise);
  static const afternoon = SysflyIconData.vector(HugeIcons.strokeRoundedSun01);
  static const evening = SysflyIconData.vector(HugeIcons.strokeRoundedCloud);
  static const night = SysflyIconData.vector(HugeIcons.strokeRoundedMoon02);

  // Profile
  static const travellers = SysflyIconData.vector(HugeIcons.strokeRoundedUserGroup);
  static const documents = SysflyIconData.vector(HugeIcons.strokeRoundedIdentityCard);
  static const pin = SysflyIconData.vector(HugeIcons.strokeRoundedLocation01);
  static const language = SysflyIconData.vector(HugeIcons.strokeRoundedGlobe02);
  static const signOut = SysflyIconData.vector(HugeIcons.strokeRoundedLogout03);
  static const trash = SysflyIconData.vector(HugeIcons.strokeRoundedDelete02);

  // Notifications
  static const gate = SysflyIconData.vector(HugeIcons.strokeRoundedSecurityCheck);
  static const boarding = SysflyIconData.vector(HugeIcons.strokeRoundedSiren);
  static const landed = SysflyIconData.vector(HugeIcons.strokeRoundedCircleArrowDown01);
  static const priceDrop = SysflyIconData.vector(HugeIcons.strokeRoundedSquareArrowDownRight);
}
