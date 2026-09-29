import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// The Moon as it looks that night: lit fraction and side. From the
/// southern hemisphere the lit side is mirrored.
class MoonPainter extends CustomPainter {
  MoonPainter({
    required this.illumination,
    required this.waxing,
    required this.southern,
    required this.lit,
    required this.dark,
  });

  final double illumination;
  final bool waxing;
  final bool southern;
  final Color lit;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final c = size.center(Offset.zero);
    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, Paint()..color = dark);

    final k = illumination.clamp(0.0, 1.0);
    if (k <= 0.005) return;
    if (k >= 0.995) {
      canvas.drawCircle(c, r, Paint()..color = lit);
      return;
    }
    // Northern hemisphere: waxing is lit on the right.
    final litRight = waxing != southern;
    final litPaint = Paint()..color = lit;
    final half = Path()
      ..addArc(disc, litRight ? -math.pi / 2 : math.pi / 2, math.pi)
      ..close();
    canvas.drawPath(half, litPaint);
    // Terminator: an ellipse whose half-width shrinks to 0 at half moon.
    final w = r * (2 * k - 1).abs();
    final ellipse = Rect.fromCenter(center: c, width: w * 2, height: r * 2);
    canvas.drawOval(ellipse, Paint()..color = k < 0.5 ? dark : lit);
  }

  @override
  bool shouldRepaint(MoonPainter old) =>
      old.illumination != illumination ||
      old.waxing != waxing ||
      old.southern != southern ||
      old.lit != lit ||
      old.dark != dark;
}
