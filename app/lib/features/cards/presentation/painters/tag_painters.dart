import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// A manila specimen tag: chamfered top corners, a reinforced hole, paper
/// speckle and fibres (seeded, so the same card always looks the same).
class TagPainter extends CustomPainter {
  TagPainter({
    required this.seed,
    required this.paper,
    required this.shade,
    required this.edge,
    required this.hole,
  });

  final int seed;
  final Color paper;
  final Color shade;
  final Color edge;

  /// What shows through the hole.
  final Color hole;

  static double chamferFor(Size s) => s.width * 0.15;
  static Offset holeCenterFor(Size s) => Offset(s.width / 2, s.width * 0.1);
  static double holeRadiusFor(Size s) => s.width * 0.022;

  static Path shape(Size s) {
    final c = chamferFor(s);
    return Path()
      ..moveTo(c, 0)
      ..lineTo(s.width - c, 0)
      ..lineTo(s.width, c)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..lineTo(0, c)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape(size);
    canvas
      ..drawShadow(
        path.shift(const Offset(0, 10)),
        const Color(0xFF000000),
        22,
        false,
      )
      ..drawPath(path, Paint()..color = paper)
      ..save()
      ..clipPath(path);

    final rnd = math.Random(seed);
    // Speckle: tiny darker and lighter flecks in the card stock.
    final dot = Paint();
    for (var i = 0; i < 1400; i++) {
      final dark = rnd.nextDouble() < 0.7;
      dot.color = (dark ? const Color(0xFF6B5320) : const Color(0xFFFFF6DA))
          .withValues(alpha: 0.06 + rnd.nextDouble() * 0.12);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.6 + rnd.nextDouble() * 1.6,
        dot,
      );
    }
    // Fibres: short, faint strokes.
    final fibre = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 90; i++) {
      final p = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height,
      );
      final a = rnd.nextDouble() * math.pi;
      final len = 8 + rnd.nextDouble() * 18;
      fibre.color = const Color(0xFF7A6230).withValues(alpha: 0.10);
      canvas.drawLine(p, p + Offset(math.cos(a), math.sin(a)) * len, fibre);
    }
    // Slightly darker, handled edges.
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = shade.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..restore()
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = edge,
      );

    // Reinforcement ring and the hole.
    final c = holeCenterFor(size);
    final r = holeRadiusFor(size);
    canvas
      ..drawCircle(c, r * 2.3, Paint()..color = shade)
      ..drawCircle(
        c,
        r * 2.3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = edge,
      )
      ..drawCircle(c, r, Paint()..color = hole);
  }

  @override
  bool shouldRepaint(TagPainter old) => old.seed != seed || old.hole != hole;
}

/// Cotton string looped through the tag's hole: two strands that meet in
/// a knot above, then run off the top of the card.
class StringPainter extends CustomPainter {
  StringPainter({
    required this.hole,
    required this.holeRadius,
    required this.color,
    required this.angle,
  });

  /// Hole centre in this painter's coordinates.
  final Offset hole;
  final double holeRadius;
  final Color color;

  /// Tag rotation (radians), so the strands leave the hole square to it.
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final knot = Offset(hole.dx + (hole.dy * 0.08), hole.dy * 0.42);
    final strand = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final shadow = Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final along = Offset(math.sin(angle), -math.cos(angle));
    final across = Offset(math.cos(angle), math.sin(angle));
    for (final side in [-1.0, 1.0]) {
      final start = hole + across * (holeRadius * 0.55 * side);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          (start + along * 60 + across * (18 * side)).dx,
          (start + along * 60 + across * (18 * side)).dy,
          knot.dx,
          knot.dy,
        );
      canvas
        ..drawPath(path.shift(const Offset(4, 6)), shadow)
        ..drawPath(path, strand);
    }
    // Single strand to the top, with a gentle sag.
    // Leans right, clear of the brand in the top-left corner.
    final top = Offset(knot.dx + 90, -20);
    final rest = Path()
      ..moveTo(knot.dx, knot.dy)
      ..quadraticBezierTo(knot.dx + 10, (knot.dy + top.dy) / 2, top.dx, top.dy);
    canvas
      ..drawPath(rest.shift(const Offset(4, 6)), shadow)
      ..drawPath(rest, strand..strokeWidth = 6)
      ..drawCircle(knot, 9, Paint()..color = color);
    // Twist: faint darker dashes along the strands.
    final twist = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 2;
    for (final metric in rest.computeMetrics()) {
      for (var d = 6.0; d < metric.length; d += 14) {
        final t = metric.getTangentForOffset(d)!;
        final n = Offset(-t.vector.dy, t.vector.dx);
        canvas.drawLine(
          t.position - n * 2.5 - t.vector * 2,
          t.position + n * 2.5 + t.vector * 2,
          twist,
        );
      }
    }
  }

  @override
  bool shouldRepaint(StringPainter old) =>
      old.hole != hole || old.angle != angle;
}

/// A rubber stamp: double border and text in one ink, with gaps where the
/// ink did not take.
class StampPainter extends CustomPainter {
  StampPainter({required this.lines, required this.color, required this.seed});

  /// Laid-out lines, top to bottom.
  final List<TextPainter> lines;
  final Color color;
  final int seed;

  static const padding = EdgeInsets.symmetric(horizontal: 30, vertical: 18);
  static const border = 6.0;
  static const gap = 5.0;

  static Size sizeFor(List<TextPainter> lines) {
    final w = lines.map((l) => l.width).fold(0.0, math.max);
    final h = lines.fold(0.0, (sum, l) => sum + l.height);
    return Size(
      w + padding.horizontal + (border + gap) * 2,
      h + padding.vertical + (border + gap) * 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    final outer = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(border / 2),
      const Radius.circular(10),
    );
    canvas
      ..drawRRect(outer, ink..strokeWidth = border)
      ..drawRRect(outer.deflate(border / 2 + gap), ink..strokeWidth = 2.5);
    var y = border + gap + padding.top;
    for (final l in lines) {
      l.paint(canvas, Offset((size.width - l.width) / 2, y));
      y += l.height;
    }
    // Where the ink did not take.
    final rnd = math.Random(seed);
    final gapPaint = Paint()..blendMode = BlendMode.dstOut;
    for (var i = 0; i < 420; i++) {
      gapPaint.color = const Color(0xFF000000)
          .withValues(alpha: 0.25 + rnd.nextDouble() * 0.6);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.8 + rnd.nextDouble() * 2.6,
        gapPaint,
      );
    }
    // Uneven pressure: one side a little lighter.
    canvas
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(size.width, size.height),
            [const Color(0x00000000), const Color(0x40000000)],
          ),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(StampPainter old) => old.lines != lines;
}
