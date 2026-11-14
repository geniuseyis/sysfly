import 'package:flutter/widgets.dart';

/// Dotted world map used as a watermark on headers, tickets and boarding
/// passes. Land is stored as column ranges on a coarse 48 x 21 grid (7.5
/// degrees of longitude per column) and drawn as a grid of small squares.
class SysflyWorldDots extends StatelessWidget {
  const SysflyWorldDots({
    super.key,
    required this.color,
    this.zoom = 1,
    this.alignment = Alignment.center,
    this.detail = 2,
  });

  final Color color;

  /// Map width relative to the available width.
  final double zoom;

  /// Which part of the zoomed map is shown.
  final Alignment alignment;

  /// Dots per grid cell along each axis.
  final int detail;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WorldDotsPainter(color: color, zoom: zoom, alignment: alignment, detail: detail),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WorldDotsPainter extends CustomPainter {
  const _WorldDotsPainter({required this.color, required this.zoom, required this.alignment, required this.detail});

  final Color color;
  final double zoom;
  final Alignment alignment;
  final int detail;

  static const int _columns = 48;

  /// Land as [start, end] column ranges for each row, north to south.
  static const List<List<int>> _land = [
    [15, 21, 26, 26, 33, 37],
    [2, 5, 8, 15, 17, 21, 27, 47],
    [2, 15, 17, 19, 21, 21, 25, 47],
    [3, 10, 14, 15, 23, 23, 25, 46],
    [7, 16, 23, 23, 25, 43, 45, 45],
    [7, 15, 24, 43],
    [7, 14, 23, 40, 42, 42],
    [8, 13, 23, 40, 42, 42],
    [9, 10, 13, 13, 22, 40],
    [10, 14, 22, 31, 33, 38, 40, 40],
    [12, 12, 22, 30, 34, 34, 37, 38, 40, 40],
    [14, 17, 23, 30, 37, 37, 39, 40],
    [13, 17, 25, 29, 37, 41],
    [13, 19, 25, 29, 38, 39, 41, 43],
    [13, 18, 25, 30, 41, 42],
    [14, 18, 25, 28, 30, 30, 40, 43],
    [14, 17, 26, 28, 39, 44],
    [14, 17, 26, 27, 39, 44],
    [14, 15, 42, 43, 47, 47],
    [14, 15, 46, 46],
    [14, 14],
  ];

  static bool _isLand(int row, int column) {
    if (row < 0 || row >= _land.length || column < 0 || column >= _columns) return false;
    final ranges = _land[row];
    for (var i = 0; i < ranges.length; i += 2) {
      if (column >= ranges[i] && column <= ranges[i + 1]) return true;
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mapWidth = size.width * zoom;
    final pitch = mapWidth / (_columns * detail);
    final mapHeight = pitch * _land.length * detail;
    final dx = (size.width - mapWidth) * (alignment.x + 1) / 2;
    final dy = (size.height - mapHeight) * (alignment.y + 1) / 2;
    final dot = pitch * 0.62;
    final paint = Paint()..color = color;
    final radius = Radius.circular(dot * 0.22);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var row = 0; row < _land.length; row++) {
      for (var column = 0; column < _columns; column++) {
        if (!_isLand(row, column)) continue;
        for (var sy = 0; sy < detail; sy++) {
          for (var sx = 0; sx < detail; sx++) {
            // Soften the coast: drop the outer corner of a cell that has no
            // land beside it on both adjoining sides.
            if (detail > 1) {
              final nx = sx == 0 ? -1 : (sx == detail - 1 ? 1 : 0);
              final ny = sy == 0 ? -1 : (sy == detail - 1 ? 1 : 0);
              if (nx != 0 && ny != 0 && !_isLand(row, column + nx) && !_isLand(row + ny, column)) continue;
            }
            final x = dx + (column * detail + sx) * pitch;
            final y = dy + (row * detail + sy) * pitch;
            if (x < -pitch || y < -pitch || x > size.width || y > size.height) continue;
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, dot, dot), radius), paint);
          }
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WorldDotsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.zoom != zoom || oldDelegate.alignment != alignment || oldDelegate.detail != detail;
}
