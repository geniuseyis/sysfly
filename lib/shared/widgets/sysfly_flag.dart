import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Circular country flag painted on canvas, keyed by ISO 3166-1 alpha-2 code.
/// Details are simplified to read well at about 40 pt.
class SysflyFlag extends StatelessWidget {
  const SysflyFlag({super.key, required this.countryCode, this.size = 40});

  final String countryCode;
  final double size;

  /// Flags drawn by hand; every other country uses its emoji flag.
  static const _painted = {'SG', 'MY', 'TH', 'VN', 'PH', 'CN', 'KR', 'JP', 'TW', 'ID', 'AU'};

  static String _emoji(String code) =>
      String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41));

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x1A10133C), blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: ClipOval(
            child: _painted.contains(countryCode)
                ? RepaintBoundary(child: CustomPaint(painter: _FlagPainter(countryCode)))
                : ColoredBox(
                    color: const Color(0xFFE9EBFA),
                    child: FittedBox(fit: BoxFit.cover, child: Text(_emoji(countryCode), textScaler: TextScaler.noScaling)),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.code);
  final String code;

  static const _red = Color(0xFFE0252D);
  static const _white = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF1B3A8C);
  static const _yellow = Color(0xFFFFD43A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    void band(double top, double bottom, Color color) =>
        canvas.drawRect(Rect.fromLTRB(0, h * top, w, h * bottom), Paint()..color = color);
    void star(Offset c, double r, Color color, {int points = 5}) {
      final path = Path();
      for (var i = 0; i < points * 2; i++) {
        final radius = i.isEven ? r : r * 0.42;
        final a = -math.pi / 2 + i * math.pi / points;
        final p = c + Offset(math.cos(a), math.sin(a)) * radius;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), Paint()..color = color);
    }

    switch (code) {
      case 'SG':
        band(0, 0.5, _red);
        band(0.5, 1, _white);
        canvas.drawCircle(Offset(w * 0.34, h * 0.27), w * 0.13, Paint()..color = _white);
        canvas.drawCircle(Offset(w * 0.39, h * 0.27), w * 0.11, Paint()..color = _red);
        for (final p in const [Offset(0.5, 0.2), Offset(0.44, 0.3), Offset(0.56, 0.3), Offset(0.47, 0.37), Offset(0.53, 0.37)]) {
          star(Offset(w * p.dx, h * p.dy), w * 0.03, _white);
        }
      case 'MY':
        for (var i = 0; i < 14; i++) {
          band(i / 14, (i + 1) / 14, i.isEven ? _red : _white);
        }
        canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.56, h * 0.57), Paint()..color = const Color(0xFF12277A));
        canvas.drawCircle(Offset(w * 0.3, h * 0.3), w * 0.15, Paint()..color = _yellow);
        canvas.drawCircle(Offset(w * 0.345, h * 0.3), w * 0.125, Paint()..color = const Color(0xFF12277A));
        star(Offset(w * 0.4, h * 0.3), w * 0.085, _yellow, points: 7);
      case 'TH':
        band(0, 1 / 6, _red);
        band(1 / 6, 2 / 6, _white);
        band(2 / 6, 4 / 6, const Color(0xFF2D2A5C));
        band(4 / 6, 5 / 6, _white);
        band(5 / 6, 1, _red);
      case 'VN':
        band(0, 1, const Color(0xFFDA251D));
        star(Offset(w / 2, h / 2), w * 0.24, _yellow);
      case 'PH':
        band(0, 0.5, const Color(0xFF0038A8));
        band(0.5, 1, const Color(0xFFCE1126));
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(w * 0.6, h / 2)
            ..lineTo(0, h)
            ..close(),
          Paint()..color = _white,
        );
        star(Offset(w * 0.24, h / 2), w * 0.1, _yellow, points: 8);
      case 'CN':
        band(0, 1, const Color(0xFFDE2910));
        star(Offset(w * 0.32, h * 0.34), w * 0.14, _yellow);
        for (final p in const [Offset(0.52, 0.2), Offset(0.6, 0.3), Offset(0.6, 0.43), Offset(0.52, 0.52)]) {
          star(Offset(w * p.dx, h * p.dy), w * 0.045, _yellow);
        }
      case 'KR':
        band(0, 1, _white);
        final c = Offset(w / 2, h / 2);
        final r = w * 0.22;
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi, math.pi, true, Paint()..color = const Color(0xFFCD2E3A));
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), 0, math.pi, true, Paint()..color = const Color(0xFF0047A0));
        canvas.drawCircle(c - Offset(r / 2, 0), r / 2, Paint()..color = const Color(0xFFCD2E3A));
        canvas.drawCircle(c + Offset(r / 2, 0), r / 2, Paint()..color = const Color(0xFF0047A0));
        final bar = Paint()
          ..color = const Color(0xFF1A1A1A)
          ..strokeWidth = w * 0.035;
        for (final corner in const [Offset(-1, -1), Offset(1, -1), Offset(-1, 1), Offset(1, 1)]) {
          final mid = c + Offset(corner.dx * w * 0.3, corner.dy * h * 0.3);
          final dir = Offset(-corner.dy, corner.dx) * (w * 0.07) * (corner.dx * corner.dy);
          for (var i = -1; i <= 1; i++) {
            final shift = Offset(corner.dx, corner.dy) * (i * w * 0.045);
            canvas.drawLine(mid + shift - dir, mid + shift + dir, bar);
          }
        }
      case 'JP':
        band(0, 1, _white);
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.26, Paint()..color = const Color(0xFFBC002D));
      case 'TW':
        band(0, 1, const Color(0xFFFE0000));
        canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.56, h * 0.52), Paint()..color = const Color(0xFF000095));
        star(Offset(w * 0.29, h * 0.27), w * 0.14, _white, points: 12);
        canvas.drawCircle(Offset(w * 0.29, h * 0.27), w * 0.075, Paint()..color = const Color(0xFF000095));
        canvas.drawCircle(Offset(w * 0.29, h * 0.27), w * 0.06, Paint()..color = _white);
      case 'ID':
        band(0, 0.5, const Color(0xFFE70011));
        band(0.5, 1, _white);
      case 'AU':
        band(0, 1, const Color(0xFF012169));
        final cross = Paint()
          ..color = _white
          ..strokeWidth = w * 0.07;
        canvas.drawLine(Offset(0, h * 0.25), Offset(w * 0.5, h * 0.25), cross);
        canvas.drawLine(Offset(w * 0.25, 0), Offset(w * 0.25, h * 0.5), cross);
        final inner = Paint()
          ..color = const Color(0xFFE4002B)
          ..strokeWidth = w * 0.035;
        canvas.drawLine(Offset(0, h * 0.25), Offset(w * 0.5, h * 0.25), inner);
        canvas.drawLine(Offset(w * 0.25, 0), Offset(w * 0.25, h * 0.5), inner);
        star(Offset(w * 0.27, h * 0.72), w * 0.09, _white, points: 7);
        for (final p in const [Offset(0.7, 0.24), Offset(0.6, 0.48), Offset(0.8, 0.44), Offset(0.7, 0.76)]) {
          star(Offset(w * p.dx, h * p.dy), w * 0.045, _white, points: 7);
        }
      default:
        band(0, 1, _blue);
    }
  }

  @override
  bool shouldRepaint(_FlagPainter oldDelegate) => oldDelegate.code != code;
}
