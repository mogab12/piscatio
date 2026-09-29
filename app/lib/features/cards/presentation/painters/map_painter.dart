import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../../../core/widgets/brand.dart';
import '../../../../domain/models/place_map.dart';
import '../../../../domain/services/map_sketch.dart';

/// Colors of a sketch map.
class MapInks {
  const MapInks({
    required this.land,
    required this.water,
    required this.contour,
    required this.road,
    required this.ring,
    required this.label,
    this.float,
  });

  final Color land;
  final Color water;

  /// Depth lines inside the water, parallel to the shore.
  final Color contour;
  final Color road;
  final Color ring;
  final Color label;

  /// Colors of the float marking the place (outline, lower half); none
  /// when null.
  final (Color, Color)? float;
}

/// Draws a [MapSketch]: the view's center in the middle of the frame, its
/// half-width fitting the frame's short side. Water with depth lines like a
/// nautical chart, rivers, main roads, the ring around the place, a scale
/// bar, north, and the OpenStreetMap credit (required by its license).
class MapPainter extends CustomPainter {
  MapPainter({
    required this.sketch,
    required this.inks,
    required this.labelStyle,
    required this.attribution,
    this.scaleMeters,
    this.scaleLabel,
    this.north,
    this.ring = true,
    this.contours = true,
    this.zoom = 1,
    this.focus = Offset.zero,
  });

  final MapSketch sketch;
  final MapInks inks;
  final TextStyle labelStyle;
  final String attribution;
  final double? scaleMeters;
  final String? scaleLabel;

  /// Letter of the north mark; no mark when null.
  final String? north;
  final bool ring;
  final bool contours;

  /// Framing chosen by the person: enlarged [zoom] times, moved toward
  /// [focus] (-1 to 1 per axis) as far as the sketch's shapes reach.
  final double zoom;
  final Offset focus;

  /// How far the view's center may move, in view units, on each axis of a
  /// [size] frame at [zoom]: the frame never leaves the shapes.
  static Offset panRange(Size size, double zoom) {
    final unit = size.shortestSide / 2 * zoom;
    return Offset(
      math.max(MapSketch.extent - size.width / 2 / unit, 0),
      math.max(MapSketch.extent - size.height / 2 / unit, 0),
    );
  }

  /// Focus change for a drag of [delta] pixels on a [size] frame at [zoom].
  static Offset focusShift(Offset delta, Size size, double zoom) {
    final unit = size.shortestSide / 2 * zoom;
    final range = panRange(size, zoom);
    double axis(double d, double room) => room < 1e-3 ? 0 : -d / unit / room;
    return Offset(axis(delta.dx, range.dx), axis(delta.dy, range.dy));
  }

  static Path _path(
    List<SketchShape> shapes,
    double unit, {
    bool close = false,
  }) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final s in shapes) {
      for (final part in s.parts) {
        if (part.length < 4) continue;
        path.moveTo(part[0] * unit, part[1] * unit);
        for (var i = 2; i + 1 < part.length; i += 2) {
          path.lineTo(part[i] * unit, part[i + 1] * unit);
        }
        if (close) path.close();
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 2 * zoom;
    // Line widths in pixels of a 1080 px card, whatever the frame and zoom.
    final px = size.shortestSide / 900;
    final range = panRange(size, zoom);
    final center = Offset(focus.dx * range.dx, focus.dy * range.dy);
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawRect(Offset.zero & size, Paint()..color = inks.land)
      ..translate(
        size.width / 2 - center.dx * unit,
        size.height / 2 - center.dy * unit,
      );

    List<SketchShape> of(bool Function(MapFeatureKind k) test) => [
      for (final s in sketch.shapes)
        if (test(s.kind)) s,
    ];

    final roads = _path(of((k) => k == MapFeatureKind.road), unit);
    canvas.drawPath(
      roads,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * px
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = inks.road,
    );

    final water = _path(of((k) => k.isArea), unit, close: true);
    canvas.drawPath(water, Paint()..color = inks.water);
    if (contours) {
      // Lines at growing distances from the shore: a wide stroke of the
      // shore, clipped to the water, drawn from the outside in.
      canvas
        ..save()
        ..clipPath(water);
      final t = 1.6 * px;
      for (final d in [60.0, 36.0, 18.0, 7.0]) {
        final w = d * 2 * px;
        canvas
          ..drawPath(
            water,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = w + t
              ..color = inks.contour,
          )
          ..drawPath(
            water,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = w - t
              ..color = inks.water,
          );
      }
      canvas.restore();
    }

    for (final (kind, width) in [
      (MapFeatureKind.coast, 4.0),
      (MapFeatureKind.stream, 2.6),
      (MapFeatureKind.canal, 4.5),
      (MapFeatureKind.river, 7.0),
    ]) {
      final lines = _path(of((k) => k == kind), unit);
      canvas.drawPath(
        lines,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * px
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = inks.water,
      );
    }

    if (ring) _ring(canvas, unit, px);
    canvas.restore();
    _furniture(canvas, size, unit, px);
  }

  void _ring(Canvas canvas, double unit, double px) {
    final r = sketch.ringRadius * unit;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = inks.ring.withValues(alpha: 0.16),
    );
    // Dashed edge: it marks an area, not a line on the ground.
    final circle = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    final dashed = Path();
    for (final metric in circle.computeMetrics()) {
      final dash = 18 * px;
      final count = math.max((metric.length / (dash * 1.8)).floor(), 8);
      final step = metric.length / count;
      for (var i = 0; i < count; i++) {
        dashed.addPath(
          metric.extractPath(i * step, i * step + step * 0.58),
          Offset.zero,
        );
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * px
        ..strokeCap = StrokeCap.round
        ..color = inks.ring,
    );
    final float = inks.float;
    if (float != null) {
      final h = 78 * px;
      final w = h * FloatPainter.aspect;
      canvas
        ..save()
        ..translate(-w / 2, -h * 0.72);
      FloatPainter(
        ink: float.$1,
        top: const Color(0xFFE4262C),
        bottom: float.$2,
      ).paint(canvas, Size(w, h));
      canvas.restore();
    }
  }

  TextPainter _text(String text, {double scale = 1}) => TextPainter(
    text: TextSpan(
      text: text,
      style: labelStyle.copyWith(
        color: inks.label,
        fontSize: (labelStyle.fontSize ?? 24) * scale,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();

  /// Labels sit on a small plate of land color so they read over water.
  void _plate(Canvas canvas, Rect r, double px) => canvas.drawRRect(
    RRect.fromRectAndRadius(r.inflate(8 * px), Radius.circular(6 * px)),
    Paint()..color = inks.land.withValues(alpha: 0.9),
  );

  void _furniture(Canvas canvas, Size size, double unit, double px) {
    final margin = 26 * px;
    final credit = _text(attribution, scale: 0.72);
    if (attribution.isNotEmpty) {
      final at = Offset(
        size.width - margin - credit.width,
        size.height - margin - credit.height,
      );
      _plate(canvas, at & credit.size, px);
      credit.paint(canvas, at);
    }

    final meters = scaleMeters;
    final label = scaleLabel;
    if (meters != null && label != null) {
      final length = meters / sketch.metersPerUnit * unit;
      final text = _text(label);
      final y = size.height - margin - text.height * 0.5;
      final x0 = margin;
      _plate(
        canvas,
        Rect.fromLTRB(
          x0,
          y - text.height * 0.55,
          x0 + length + 12 * px + text.width,
          y + text.height * 0.45,
        ),
        px,
      );
      final stroke = Paint()
        ..color = inks.label
        ..strokeWidth = 3 * px
        ..strokeCap = StrokeCap.square;
      canvas
        ..drawLine(Offset(x0, y), Offset(x0 + length, y), stroke)
        ..drawLine(Offset(x0, y - 9 * px), Offset(x0, y + 1), stroke)
        ..drawLine(
          Offset(x0 + length, y - 9 * px),
          Offset(x0 + length, y + 1),
          stroke,
        );
      text.paint(canvas, Offset(x0 + length + 12 * px, y - text.height * 0.55));
    }

    final n = north;
    if (n != null) {
      final letter = _text(n);
      // Top left: the top right corner is where cards pin the photo.
      final cx = margin + 14 * px;
      final top = margin;
      _plate(
        canvas,
        Rect.fromLTRB(
          cx - 14 * px,
          top,
          cx + 14 * px,
          top + 34 * px + letter.height,
        ),
        px,
      );
      final arrow = Path()
        ..moveTo(cx, top)
        ..lineTo(cx + 12 * px, top + 30 * px)
        ..lineTo(cx, top + 23 * px)
        ..lineTo(cx - 12 * px, top + 30 * px)
        ..close();
      canvas.drawPath(arrow, Paint()..color = inks.label);
      letter.paint(canvas, Offset(cx - letter.width / 2, top + 34 * px));
    }
  }

  @override
  bool shouldRepaint(MapPainter old) =>
      old.sketch != sketch ||
      old.inks.land != inks.land ||
      old.inks.water != inks.water ||
      old.inks.ring != inks.ring ||
      old.inks.label != inks.label ||
      old.scaleLabel != scaleLabel ||
      old.attribution != attribution ||
      old.zoom != zoom ||
      old.focus != focus;
}
