import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

/// An icon the app can draw: either vector outlines (the Hugeicons rounded
/// stroke set, which is the family the reference uses) or a glyph from an
/// icon font.
@immutable
class SysflyIconData {
  /// Vector icon on a 24 x 24 grid.
  ///
  /// Elements listed in [fill] are filled, which is how the solid variants
  /// for selected states are made from the same outlines. Elements listed in
  /// [cut] are stroked in the background colour so they read as cut-outs of a
  /// filled shape, for example the door line of the filled house.
  const SysflyIconData.vector(List<List<dynamic>> this.elements, {this.fill = const {}, this.cut = const {}, this.mirrored = false})
      : glyph = null;

  /// Glyph from an icon font.
  const SysflyIconData.glyph(IconData this.glyph)
      : elements = null,
        fill = const {},
        cut = const {},
        mirrored = false;

  final List<List<dynamic>>? elements;
  final IconData? glyph;
  final Set<int> fill;
  final Set<int> cut;

  /// Flip horizontally.
  final bool mirrored;
}

/// Draws a [SysflyIconData]. Vector icons are painted synchronously from
/// cached paths, so they are present in the very first frame.
class SysflyIcon extends StatelessWidget {
  const SysflyIcon(this.icon, {super.key, this.size = 24, this.color, this.cutColor, this.strokeWidth});

  final SysflyIconData icon;
  final double size;

  /// Defaults to the ambient [IconTheme] colour.
  final Color? color;

  /// Colour of cut-out details in filled icons; defaults to transparent.
  final Color? cutColor;

  /// Stroke width on the 24 pt grid; defaults to the icon's own (1.5).
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    final glyph = icon.glyph;
    if (glyph != null) {
      return ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text.rich(
              TextSpan(
                text: String.fromCharCode(glyph.codePoint),
                style: TextStyle(
                  inherit: false,
                  color: resolved,
                  fontSize: size,
                  fontFamily: glyph.fontFamily,
                  package: glyph.fontPackage,
                  height: 1,
                ),
              ),
              textScaler: TextScaler.noScaling,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      );
    }
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        // Centred so the icon keeps its size when a parent forces a larger box.
        child: Center(
          child: CustomPaint(
            size: Size.square(size),
            painter: _VectorIconPainter(icon, resolved, cutColor, strokeWidth),
          ),
        ),
      ),
    );
  }
}

class _Shape {
  _Shape(this.path, this.strokeWidth, this.filled, this.stroked);

  final Path path;
  final double strokeWidth;

  /// The source element is a filled shape (for example a dot).
  final bool filled;
  final bool stroked;
}

class _PathBuilder extends PathProxy {
  final Path path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

/// Parsed shapes per icon, keyed by the identity of the constant data.
final Expando<List<_Shape>> _cache = Expando<List<_Shape>>('sysfly-icon-shapes');

double _number(Object? value, [double fallback = 0]) => value == null ? fallback : double.tryParse(value.toString()) ?? fallback;

List<_Shape> _shapesOf(List<List<dynamic>> elements) {
  final cached = _cache[elements];
  if (cached != null) return cached;
  final shapes = <_Shape>[];
  for (final element in elements) {
    final tag = element[0] as String;
    final attributes = (element[1] as Map).cast<String, dynamic>();
    Path? path;
    switch (tag) {
      case 'path':
        final builder = _PathBuilder();
        writeSvgPathDataToPath(attributes['d'] as String?, builder);
        path = builder.path;
        if (attributes['fillRule'] == 'evenodd') path.fillType = PathFillType.evenOdd;
      case 'circle':
        path = Path()
          ..addOval(Rect.fromCircle(
            center: Offset(_number(attributes['cx']), _number(attributes['cy'])),
            radius: _number(attributes['r']),
          ));
      case 'ellipse':
        path = Path()
          ..addOval(Rect.fromCenter(
            center: Offset(_number(attributes['cx']), _number(attributes['cy'])),
            width: _number(attributes['rx']) * 2,
            height: _number(attributes['ry']) * 2,
          ));
      case 'rect':
        final rect = Rect.fromLTWH(
          _number(attributes['x']),
          _number(attributes['y']),
          _number(attributes['width']),
          _number(attributes['height']),
        );
        final radius = _number(attributes['rx'] ?? attributes['ry']);
        path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
      case 'line':
        path = Path()
          ..moveTo(_number(attributes['x1']), _number(attributes['y1']))
          ..lineTo(_number(attributes['x2']), _number(attributes['y2']));
    }
    if (path == null) continue;
    final fill = attributes['fill'];
    shapes.add(_Shape(
      path,
      _number(attributes['strokeWidth'], 1.5),
      fill != null && fill != 'none',
      attributes['stroke'] != null && attributes['stroke'] != 'none',
    ));
  }
  _cache[elements] = shapes;
  return shapes;
}

class _VectorIconPainter extends CustomPainter {
  const _VectorIconPainter(this.icon, this.color, this.cutColor, this.strokeWidth);

  final SysflyIconData icon;
  final Color color;
  final Color? cutColor;
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final shapes = _shapesOf(icon.elements!);
    final scale = size.width / 24;
    canvas.save();
    if (icon.mirrored) {
      canvas.translate(size.width, 0);
      canvas.scale(-scale, scale);
    } else {
      canvas.scale(scale);
    }

    Paint stroke(Color c, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..color = c
      ..strokeWidth = strokeWidth ?? width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final solid = Paint()..color = color;

    // Filled shapes first, then ordinary strokes, then cut-outs on top.
    for (var i = 0; i < shapes.length; i++) {
      if (!icon.fill.contains(i)) continue;
      canvas.drawPath(shapes[i].path, solid);
      canvas.drawPath(shapes[i].path, stroke(color, shapes[i].strokeWidth));
    }
    for (var i = 0; i < shapes.length; i++) {
      if (icon.fill.contains(i) || icon.cut.contains(i)) continue;
      final shape = shapes[i];
      if (shape.filled) canvas.drawPath(shape.path, solid);
      if (shape.stroked) canvas.drawPath(shape.path, stroke(color, shape.strokeWidth));
    }
    final cut = cutColor;
    if (cut != null) {
      for (var i = 0; i < shapes.length; i++) {
        if (icon.cut.contains(i)) canvas.drawPath(shapes[i].path, stroke(cut, shapes[i].strokeWidth));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VectorIconPainter old) =>
      old.icon != icon || old.color != color || old.cutColor != cutColor || old.strokeWidth != strokeWidth;
}

