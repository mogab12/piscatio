import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../domain/services/ruler_scale.dart';

class BoardTick {
  const BoardTick(this.fraction, this.level, [this.label]);

  /// Position along the scale, 0–1.
  final double fraction;

  /// 0 minor, 1 middle, 2 major (numbered).
  final int level;
  final String? label;
}

class BoardMark {
  const BoardMark(this.fraction, this.color, {this.notch = true, this.label});

  final double fraction;
  final Color color;

  /// Notch: a triangle cut into the top edge plus a line across the board.
  /// Otherwise just the line (e.g. the previous record).
  final bool notch;

  /// Printed along the bottom edge, next to the line.
  final String? label;
}

/// Ticks for a measuring scale: minor every [RulerScale.minor], a middle
/// tick halfway between numbers, numbers every [RulerScale.major].
List<BoardTick> scaleTicks(RulerScale s, String Function(double) number) {
  final ticks = <BoardTick>[];
  final steps = (s.max / s.minor).round();
  final perMajor = (s.major / s.minor).round();
  for (var i = 0; i <= steps; i++) {
    final v = i * s.minor;
    final isMajor = i % perMajor == 0;
    final isMiddle = perMajor.isEven && i % (perMajor ~/ 2) == 0;
    ticks.add(
      BoardTick(
        v / s.max,
        isMajor ? 2 : (isMiddle ? 1 : 0),
        isMajor && i > 0 ? number(v) : null,
      ),
    );
  }
  return ticks;
}

/// Ticks for a trip's time board: 5-minute steps (15 on long trips),
/// hours numbered.
List<BoardTick> hourTicks(double spanHours) {
  final totalMinutes = (spanHours * 60).round();
  final step = totalMinutes > 240 ? 15 : 5;
  return [
    for (var m = 0; m <= totalMinutes; m += step)
      BoardTick(
        m / totalMinutes,
        m % 60 == 0 ? 2 : (m % 30 == 0 ? 1 : 0),
        m % 60 == 0 && m > 0 ? '${m ~/ 60}' : null,
      ),
  ];
}

/// A fish measuring board, drawn flat: the dark stop at zero where the
/// fish's nose rests, ticks from the top edge, numbers, notches, and the
/// maker's mark printed near the stop.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.ticks,
    required this.marks,
    required this.numberStyle,
    required this.printStyle,
    required this.unitLabel,
    required this.brand,
    this.board = const Color(0xFFF7F9F8),
    this.ink = const Color(0xFF0B2A33),
    this.stop = const Color(0xFF2E4D56),
    this.fillFraction,
    this.fillColor,
    this.notchScale = 1,
  });

  final List<BoardTick> ticks;
  final List<BoardMark> marks;
  final TextStyle numberStyle;

  /// Small print along the bottom edge (brand, mark labels).
  final TextStyle printStyle;
  final String unitLabel;
  final String brand;
  final Color board;
  final Color ink;
  final Color stop;

  /// Time boards shade the part already fished.
  final double? fillFraction;
  final Color? fillColor;

  /// Smaller notches when there are many marks (a trip's catches).
  final double notchScale;

  static double notchDepthFor(Size size) => size.height * 0.17;
  static double stopWidthFor(Size size) => size.height * 0.24;

  /// Horizontal range of the scale inside [size].
  static (double, double) scaleRange(Size size) =>
      (stopWidthFor(size) + 24, size.width - 40);

  /// Board color under [px] (shaded where a time board is filled).
  Color _backgroundAt(double px, double x0, double x1) {
    final filled =
        fillFraction != null &&
        fillColor != null &&
        px <= x0 + (x1 - x0) * fillFraction!;
    return filled ? fillColor! : board;
  }

  TextPainter _text(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final notchDepth = notchDepthFor(size);
    final stopWidth = stopWidthFor(size);
    final body = Rect.fromLTWH(
      0,
      notchDepth,
      size.width,
      size.height - notchDepth,
    );
    final bodyShape = RRect.fromRectAndCorners(
      body,
      topRight: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );
    // A real object lying on the photo: one soft shadow under it.
    canvas.drawShadow(
      Path()..addRRect(bodyShape.shift(const Offset(0, 6))),
      const Color(0xFF000000),
      14,
      false,
    );
    canvas.drawRRect(bodyShape, Paint()..color = board);
    final (x0, x1) = scaleRange(size);
    double x(double f) => x0 + (x1 - x0) * f;

    if (fillFraction != null && fillColor != null) {
      canvas.drawRect(
        Rect.fromLTRB(x0, body.top, x(fillFraction!), body.bottom),
        Paint()..color = fillColor!,
      );
    }

    // The stop: a raised block at zero, taller than the board.
    final stopRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, notchDepth * 0.35, stopWidth, size.height),
      topLeft: const Radius.circular(8),
      bottomLeft: const Radius.circular(8),
      topRight: const Radius.circular(3),
    );
    canvas
      ..drawRRect(stopRect, Paint()..color = stop)
      ..drawRect(
        Rect.fromLTWH(stopWidth - 5, stopRect.top + 3, 5, stopRect.height),
        Paint()..color = const Color(0x33000000),
      );

    // Mark lines first, so the printed numbers stay readable over them.
    for (final m in marks) {
      final px = x(m.fraction);
      canvas.drawLine(
        Offset(px, body.top),
        Offset(px, body.bottom),
        Paint()
          ..color = m.color
          ..strokeWidth = (m.notch ? 6 : 5) * (0.6 + 0.4 * notchScale),
      );
    }

    final h = body.height;
    final tickPaint = Paint()
      ..color = ink
      ..strokeCap = StrokeCap.butt;
    for (final t in ticks) {
      final px = x(t.fraction);
      tickPaint.strokeWidth = switch (t.level) {
        2 => 4,
        1 => 3,
        _ => 2,
      };
      final len =
          h *
          switch (t.level) {
            2 => 0.36,
            1 => 0.26,
            _ => 0.16,
          };
      canvas.drawLine(
        Offset(px, body.top),
        Offset(px, body.top + len),
        tickPaint,
      );
      if (t.label != null) {
        final tp = _text(t.label!, numberStyle.copyWith(color: ink));
        final at = Offset(px - tp.width / 2, body.top + len + 4);
        canvas.drawRect(
          (at & tp.size).inflate(3),
          Paint()..color = _backgroundAt(px, x0, x1),
        );
        tp.paint(canvas, at);
      }
    }
    // Unit printed at the zero end, in the number row.
    final unit = _text(unitLabel, numberStyle.copyWith(color: ink));
    unit.paint(canvas, Offset(x0 + 8, body.top + h * 0.36 + 4));

    // Maker's mark near the stop, along the bottom edge.
    final bottomY = body.bottom - h * 0.1;
    final brandText = _text(
      brand,
      printStyle.copyWith(
        color: ink,
        fontFamily: PiscatioFonts.brand,
        fontWeight: FontWeight.w400,
      ),
    );
    final floatH = brandText.height * 1.05;
    final floatSize = Size(floatH * FloatPainter.aspect, floatH);
    final bx = x0 + 8;
    final by = bottomY - brandText.height;
    canvas
      ..save()
      ..translate(bx, by - floatH * 0.04);
    FloatPainter(
      ink: ink,
      top: const Color(0xFFE4262C),
      bottom: board,
      line: false,
    ).paint(canvas, floatSize);
    canvas.restore();
    brandText.paint(canvas, Offset(bx + floatSize.width + 8, by));
    final brandRight = bx + floatSize.width + 8 + brandText.width;

    // Notches and labels on top of the print.
    for (final m in marks) {
      final px = x(m.fraction);
      if (m.notch) {
        final w = notchDepth * 0.75 * notchScale;
        final depth = (notchDepth + 8) * (0.4 + 0.6 * notchScale);
        canvas.drawPath(
          Path()
            ..moveTo(px - w, notchDepth - depth + 8)
            ..lineTo(px + w, notchDepth - depth + 8)
            ..lineTo(px, notchDepth + 8)
            ..close(),
          Paint()..color = m.color,
        );
      }
      if (m.label != null) {
        final tp = _text(m.label!, printStyle.copyWith(color: ink));
        final left = px - 12 - tp.width;
        final lx = left > brandRight + 24
            ? left
            : math.min(px + 12, size.width - 16 - tp.width);
        tp.paint(canvas, Offset(lx, bottomY - tp.height));
      }
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) => true;
}
