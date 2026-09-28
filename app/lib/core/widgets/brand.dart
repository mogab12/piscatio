import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../formatting/l10n.dart';
import '../theme/tokens.dart';

/// The Piscatio symbol: a fishing float. Red above the waterline, white
/// below, antenna on top and the line running down, drawn at the italic
/// angle of the wordmark.
class FloatMark extends StatelessWidget {
  const FloatMark({
    super.key,
    required this.height,
    this.ink = PiscatioColors.paper,
    this.top = PiscatioColors.redHead,
    this.bottom = PiscatioColors.paper,
    this.line = true,
  });

  final double height;

  /// Antenna, outline, waist band and line.
  final Color ink;
  final Color top;
  final Color bottom;

  /// Draw the fishing line under the float.
  final bool line;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(height * FloatPainter.aspect, height),
      painter: FloatPainter(ink: ink, top: top, bottom: bottom, line: line),
    );
  }
}

class FloatPainter extends CustomPainter {
  FloatPainter({
    required this.ink,
    required this.top,
    required this.bottom,
    this.line = true,
    this.tilt = -0.14,
  });

  /// Width / height of the symbol box.
  static const aspect = 0.46;

  final Color ink;
  final Color top;
  final Color bottom;
  final bool line;

  /// Radians; matches the wordmark's italic.
  final double tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    canvas
      ..save()
      ..translate(w / 2, h / 2)
      ..rotate(tilt)
      ..translate(-w / 2, -h / 2);

    final bodyW = w * 0.8;
    final antennaH = h * 0.2;
    final bodyTop = antennaH;
    final bodyH = line ? h * 0.62 : h * 0.8;
    final body = Rect.fromLTWH((w - bodyW) / 2, bodyTop, bodyW, bodyH);
    final stroke = math.max(1.2, bodyW * 0.09);

    // Antenna: a stick with a bright tip.
    final stick = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, antennaH / 2 + stroke),
        width: stroke * 1.3,
        height: antennaH + stroke * 2,
      ),
      Radius.circular(stroke),
    );
    canvas.drawRRect(stick, Paint()..color = ink);

    // Body: an egg, fuller at the bottom, split at the waterline.
    final egg = _egg(body);
    canvas
      ..save()
      ..clipPath(egg)
      ..drawRect(
        Rect.fromLTRB(body.left, body.top, body.right, body.top + bodyH * 0.5),
        Paint()..color = top,
      )
      ..drawRect(
        Rect.fromLTRB(
          body.left,
          body.top + bodyH * 0.5,
          body.right,
          body.bottom,
        ),
        Paint()..color = bottom,
      )
      ..drawRect(
        Rect.fromCenter(
          center: Offset(w / 2, body.top + bodyH * 0.5),
          width: bodyW,
          height: stroke * 0.9,
        ),
        Paint()..color = ink,
      )
      ..restore()
      ..drawPath(
        egg,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = ink,
      );

    if (line) {
      canvas.drawLine(
        Offset(w / 2, body.bottom),
        Offset(w / 2, h),
        Paint()
          ..color = ink
          ..strokeWidth = math.max(1, stroke * 0.55)
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  /// A float's profile: narrow shoulders, round belly.
  static Path _egg(Rect r) {
    final cx = r.center.dx;
    final belly = r.top + r.height * 0.62;
    return Path()
      ..moveTo(cx, r.top)
      ..cubicTo(
        cx + r.width * 0.34,
        r.top,
        r.right,
        belly - r.height * 0.3,
        r.right,
        belly,
      )
      ..cubicTo(
        r.right,
        r.bottom - r.height * 0.1,
        cx + r.width * 0.3,
        r.bottom,
        cx,
        r.bottom,
      )
      ..cubicTo(
        cx - r.width * 0.3,
        r.bottom,
        r.left,
        r.bottom - r.height * 0.1,
        r.left,
        belly,
      )
      ..cubicTo(
        r.left,
        belly - r.height * 0.3,
        cx - r.width * 0.34,
        r.top,
        cx,
        r.top,
      )
      ..close();
  }

  @override
  bool shouldRepaint(FloatPainter old) =>
      old.ink != ink || old.top != top || old.bottom != bottom;
}

/// Float + wordmark, optionally with the tagline under the name.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.size = 28,
    this.color = PiscatioColors.paper,
    this.floatBottom,
    this.tagline = false,
    this.taglineColor,
  });

  /// Cap height-ish size of the wordmark.
  final double size;
  final Color color;

  /// Lower half of the float (defaults to [color]).
  final Color? floatBottom;
  final bool tagline;
  final Color? taglineColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final word = TextStyle(
      fontFamily: PiscatioFonts.expanded,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w800,
      fontSize: size,
      height: 1,
      letterSpacing: -size * 0.02,
      color: color,
    );
    return Semantics(
      label: l10n.appTitle,
      excludeSemantics: true,
      // Never wider than its slot (narrow phones, large system text).
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatMark(
              height: size * (tagline ? 2.1 : 1.55),
              ink: color,
              bottom: floatBottom ?? color,
            ),
            SizedBox(width: size * 0.34),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.appTitle, style: word),
                if (tagline) ...[
                  SizedBox(height: size * 0.18),
                  Text(
                    l10n.brandTagline,
                    style: TextStyle(
                      fontFamily: PiscatioFonts.text,
                      fontWeight: FontWeight.w600,
                      fontSize: size * 0.46,
                      height: 1,
                      color: taglineColor ?? color.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
