import 'package:flutter/widgets.dart';

/// Spacing scale. The reference layout was measured on a 440 pt wide canvas
/// (iPhone 17 Pro Max); horizontal page padding is 20.
abstract final class SysflySpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double page = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Space reserved at the bottom of tab pages so content can scroll clear of
  /// the floating navigation bar.
  static const double navClearance = 118;
}

abstract final class SysflyRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double card = 28;
  static const double sheet = 32;
  static const double pill = 999;

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius fieldAll = BorderRadius.all(Radius.circular(18));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
  static const BorderRadius headerBottom = BorderRadius.vertical(bottom: Radius.circular(30));
}

abstract final class SysflyShadows {
  static const card = [
    BoxShadow(color: Color(0x0F181D5A), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const soft = [
    BoxShadow(color: Color(0x0A181D5A), blurRadius: 10, offset: Offset(0, 3)),
  ];
  static const button = [
    BoxShadow(color: Color(0x3D1D3080), blurRadius: 18, offset: Offset(0, 8)),
  ];
  static const nav = [
    BoxShadow(color: Color(0x2610133C), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x1210133C), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const pill = [
    BoxShadow(color: Color(0x14181D5A), blurRadius: 8, offset: Offset(0, 2)),
  ];
}
