import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'contours.dart';

/// Isobaths of an imaginary bottom, generated from [seed] (never from the
/// real place), with faint italic soundings like a nautical chart.
class ContourPainter extends CustomPainter {
  ContourPainter({
    required this.seed,
    required this.line,
    required this.strongLine,
    required this.soundingStyle,
  });

  final int seed;
  final Color line;
  final Color strongLine;
  final TextStyle soundingStyle;

  static const levels = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final noise = GradientNoise(seed);
    const scale = 1 / 760;
    double field(double x, double y) =>
        noise.fbm(x * scale, y * scale, octaves: 3);
    final grid = ScalarGrid.sample(size, 18, field);

    final thin = Paint()
      ..color = line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final strong = Paint()
      ..color = strongLine
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < levels; i++) {
      final level = 0.2 + i * 0.6 / levels;
      final paint = i % 4 == 0 ? strong : thin;
      final path = Path();
      for (final (a, b) in isoSegments(grid, level)) {
        path
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy);
      }
      canvas.drawPath(path, paint);
    }

    // Soundings: depth grows where the field is low (deeper water).
    final rnd = math.Random(seed ^ 0x5eed);
    for (var i = 0; i < 26; i++) {
      final x = 60 + rnd.nextDouble() * (size.width - 120);
      final y = 60 + rnd.nextDouble() * (size.height - 120);
      final depth = (4 + (1 - field(x, y)) * 34).round();
      final tp = TextPainter(
        text: TextSpan(text: '$depth', style: soundingStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(ContourPainter old) =>
      old.seed != seed || old.line != line;
}

/// Chart neatline with the graduated border (alternating minute bars).
class ChartBorderPainter extends CustomPainter {
  ChartBorderPainter({required this.ink, required this.paper});

  final Color ink;
  final Color paper;

  static const inset = 34.0;
  static const bar = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final inner = outer.deflate(bar);
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas
      ..drawRect(outer, stroke)
      ..drawRect(inner, stroke);
    final fill = Paint()..color = ink;
    const seg = 54.0;
    void run(Offset from, Offset to, bool horizontal) {
      final length = horizontal ? to.dx - from.dx : to.dy - from.dy;
      final n = (length / seg).floor();
      for (var i = 0; i < n; i += 2) {
        final r = horizontal
            ? Rect.fromLTWH(from.dx + i * seg, from.dy, seg, bar)
            : Rect.fromLTWH(from.dx, from.dy + i * seg, bar, seg);
        canvas.drawRect(r, fill);
      }
    }

    run(
      outer.topLeft + const Offset(bar, 0),
      outer.topRight - const Offset(bar, 0),
      true,
    );
    run(
      Offset(outer.left + bar, outer.bottom - bar),
      Offset(outer.right - bar, outer.bottom - bar),
      true,
    );
    run(
      outer.topLeft + const Offset(0, bar),
      outer.bottomLeft - const Offset(0, bar),
      false,
    );
    run(
      Offset(outer.right - bar, outer.top + bar),
      Offset(outer.right - bar, outer.bottom - bar),
      false,
    );
    // Corner squares.
    for (final c in [
      outer.topLeft,
      outer.topRight - const Offset(bar, 0),
      outer.bottomLeft - const Offset(0, bar),
      outer.bottomRight - const Offset(bar, bar),
    ]) {
      canvas.drawRect(
        Rect.fromLTWH(c.dx, c.dy, bar, bar),
        Paint()..color = paper,
      );
      canvas.drawRect(Rect.fromLTWH(c.dx, c.dy, bar, bar), stroke);
    }
  }

  @override
  bool shouldRepaint(ChartBorderPainter old) => old.ink != ink;
}

/// Compass rose with bearing ticks; when the wind is known, an arrow
/// shows where it blew to (drawn from the side it came from).
class CompassRosePainter extends CustomPainter {
  CompassRosePainter({
    required this.ink,
    required this.accent,
    required this.letterStyle,
    required this.letters,
    this.windFromDegrees,
  });

  final Color ink;
  final Color accent;
  final TextStyle letterStyle;

  /// N, E, S, W in the active language.
  final List<String> letters;
  final double? windFromDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 40;
    final ring = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas
      ..drawCircle(c, r, ring)
      ..drawCircle(c, r - 22, ring..strokeWidth = 1.5);
    for (var d = 0; d < 360; d += 5) {
      final a = (d - 90) * math.pi / 180;
      final len = d % 30 == 0 ? 22.0 : (d % 10 == 0 ? 14.0 : 7.0);
      final p1 = c + Offset(math.cos(a), math.sin(a)) * r;
      final p2 = c + Offset(math.cos(a), math.sin(a)) * (r - len);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = ink
          ..strokeWidth = d % 30 == 0 ? 3 : 1.5,
      );
    }
    // Cardinal letters outside the ring; north gets the accent notch.
    for (var i = 0; i < 4; i++) {
      final a = (i * 90 - 90) * math.pi / 180;
      final pos = c + Offset(math.cos(a), math.sin(a)) * (r + 24);
      final tp = TextPainter(
        text: TextSpan(text: letters[i], style: letterStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
    final north = Path()
      ..moveTo(c.dx - 14, c.dy - r - 2)
      ..lineTo(c.dx + 14, c.dy - r - 2)
      ..lineTo(c.dx, c.dy - r + 26)
      ..close();
    canvas.drawPath(north, Paint()..color = accent);

    final from = windFromDegrees;
    if (from != null) {
      // Arrow on the side the wind came from, pointing in: it stops short
      // of the centre, where the moon sits.
      final a = (from - 90) * math.pi / 180;
      final dir = Offset(math.cos(a), math.sin(a));
      final tail = c + dir * (r - 30);
      final head = c + dir * (r * 0.42);
      canvas.drawLine(
        tail,
        head + dir * 24,
        Paint()
          ..color = accent
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      final side = Offset(-dir.dy, dir.dx);
      final back = head + dir * 34;
      canvas.drawPath(
        Path()
          ..moveTo(head.dx, head.dy)
          ..lineTo((back + side * 17).dx, (back + side * 17).dy)
          ..lineTo((back - side * 17).dx, (back - side * 17).dy)
          ..close(),
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(CompassRosePainter old) =>
      old.windFromDegrees != windFromDegrees;
}
