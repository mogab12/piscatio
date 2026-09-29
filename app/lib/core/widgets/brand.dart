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

/// The full logo: the float, the name in the wordmark face, and the float's
/// line running under the name to a hook. Optionally the tagline under the
/// line. Drawn as one piece, so it looks the same everywhere (and does not
/// grow with the system text size: it is a picture).
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.size = 28,
    this.color = PiscatioColors.paper,
    this.floatBottom,
    this.tagline = false,
    this.taglineColor,
    this.wordColor,
  });

  /// Font size of the name.
  final double size;

  /// Float outline, line and hook (and the name, unless [wordColor]).
  final Color color;

  /// Lower half of the float (defaults to [color]).
  final Color? floatBottom;
  final bool tagline;
  final Color? taglineColor;
  final Color? wordColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final layout = BrandLayout(
      fontSize: size,
      word: l10n.appTitle,
      wordColor: wordColor ?? color,
      tagline: tagline ? l10n.brandTagline : null,
      taglineColor: taglineColor ?? color.withValues(alpha: 0.78),
    );
    return Semantics(
      label: l10n.appTitle,
      excludeSemantics: true,
      // Never wider than its slot (narrow phones, large system text).
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: CustomPaint(
          size: layout.size,
          painter: BrandPainter(
            layout: layout,
            ink: color,
            floatBottom: floatBottom ?? color,
          ),
        ),
      ),
    );
  }
}

/// Where each part of the logo goes, for a name set at [fontSize].
class BrandLayout {
  BrandLayout({
    required this.fontSize,
    required String word,
    required Color wordColor,
    String? tagline,
    Color? taglineColor,
  }) : wordPainter = TextPainter(
         text: TextSpan(
           text: word,
           style: TextStyle(
             fontFamily: PiscatioFonts.brand,
             fontSize: fontSize,
             height: 1.08,
             color: wordColor,
           ),
         ),
         textDirection: TextDirection.ltr,
         textScaler: TextScaler.noScaling,
       )..layout(),
       taglinePainter = tagline == null
           ? null
           : (TextPainter(
               text: TextSpan(
                 text: tagline,
                 style: TextStyle(
                   fontFamily: PiscatioFonts.text,
                   fontWeight: FontWeight.w600,
                   fontSize: fontSize * 0.36,
                   height: 1,
                   color: taglineColor,
                 ),
               ),
               textDirection: TextDirection.ltr,
               textScaler: TextScaler.noScaling,
             )..layout()) {
    baseline = wordPainter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    floatSize = Size(fontSize * 1.12 * FloatPainter.aspect, fontSize * 1.12);
    floatTop = baseline - floatSize.height * 0.97;
    wordLeft = floatSize.width + fontSize * 0.2;
    stroke = math.max(1.2, fontSize * 0.062);
    lineY = baseline + fontSize * 0.2;
    hookX = wordLeft + wordPainter.width + fontSize * 0.04;
    hookShank = fontSize * 0.38;
    hookBend = fontSize * 0.15;
    taglineTop = lineY + fontSize * 0.2;
    final hookBottom = lineY + hookShank + hookBend + stroke;
    final taglineBottom = taglinePainter == null
        ? 0.0
        : taglineTop + taglinePainter!.height;
    size = Size(
      hookX + stroke * 1.5,
      math.max(math.max(hookBottom, taglineBottom), wordPainter.height),
    );
  }

  final double fontSize;
  final TextPainter wordPainter;
  final TextPainter? taglinePainter;
  late final double baseline;
  late final Size floatSize;
  late final double floatTop;
  late final double wordLeft;
  late final double stroke;
  late final double lineY;
  late final double hookX;
  late final double hookShank;
  late final double hookBend;
  late final double taglineTop;

  /// The whole logo.
  late final Size size;
}

/// Paints a [BrandLayout].
class BrandPainter extends CustomPainter {
  BrandPainter({
    required this.layout,
    required this.ink,
    required this.floatBottom,
    this.top = PiscatioColors.redHead,
  });

  final BrandLayout layout;
  final Color ink;
  final Color floatBottom;
  final Color top;

  /// The fishing line from under the float to the hook's point.
  static Path linePath(BrandLayout l) {
    final fh = l.floatSize.height;
    // The float leans with the italic: its bottom sits a little right.
    final start = Offset(
      l.floatSize.width / 2 + fh * 0.07,
      l.floatTop + fh * 0.99,
    );
    final r = l.fontSize * 0.2;
    final y = l.lineY;
    final x = l.hookX;
    final shankEnd = y + l.hookShank;
    final pointX = x - 2 * l.hookBend;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(start.dx, y - r)
      ..quadraticBezierTo(start.dx, y, start.dx + r, y)
      ..lineTo(x - r * 0.5, y)
      ..quadraticBezierTo(x, y, x, y + r * 0.5)
      ..lineTo(x, shankEnd)
      ..arcToPoint(
        Offset(pointX, shankEnd),
        radius: Radius.circular(l.hookBend),
      )
      ..lineTo(pointX, shankEnd - l.hookShank * 0.62);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final l = layout;
    canvas.save();
    // Scale when the widget is given another size (FittedBox handles it,
    // but the painter stays correct on its own).
    final sx = size.width / l.size.width;
    final sy = size.height / l.size.height;
    canvas.scale(sx, sy);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = l.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;
    final path = linePath(l);
    canvas.drawPath(path, line);
    // The barb: a short spur back from the point.
    final metric = path.computeMetrics().last;
    final tip = metric.getTangentForOffset(metric.length)!.position;
    canvas.drawLine(
      tip,
      tip + Offset(l.hookBend * 0.9, l.hookShank * 0.32),
      line,
    );

    canvas
      ..save()
      ..translate(0, l.floatTop);
    FloatPainter(
      ink: ink,
      top: top,
      bottom: floatBottom,
      line: false,
    ).paint(canvas, l.floatSize);
    canvas.restore();

    l.wordPainter.paint(canvas, Offset(l.wordLeft, 0));
    l.taglinePainter?.paint(
      canvas,
      Offset(l.wordLeft + l.fontSize * 0.06, l.taglineTop),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandPainter old) =>
      old.ink != ink ||
      old.floatBottom != floatBottom ||
      old.top != top ||
      old.layout.fontSize != layout.fontSize ||
      old.layout.wordPainter.text != layout.wordPainter.text ||
      old.layout.taglinePainter?.text != layout.taglinePainter?.text;
}
