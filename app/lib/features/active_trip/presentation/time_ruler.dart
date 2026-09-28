import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/formatting/l10n.dart';
import '../../../core/theme/tokens.dart';

/// The trip as a measuring board: the scale is time, the filled part is how
/// long you have been fishing and every catch is a red notch where it
/// happened. It is the one decorative flourish of the screen, and it carries
/// real information.
class TimeRuler extends StatelessWidget {
  const TimeRuler({
    super.key,
    required this.start,
    required this.now,
    required this.catchTimes,
    this.height = 72,
  });

  final DateTime start;
  final DateTime now;
  final List<DateTime> catchTimes;
  final double height;

  /// Scale length: at least one hour, then the elapsed time plus a little
  /// room, rounded up to half hours.
  static Duration spanFor(Duration elapsed) {
    final minutes = math.max(60, elapsed.inMinutes + 10);
    return Duration(minutes: (minutes / 30).ceil() * 30);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final elapsed = now.difference(start);
    final span = spanFor(elapsed);
    final hourLabel = l10n.rulerHour;
    return Semantics(
      label: l10n.rulerSemantics(catchTimes.length),
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _RulerPainter(
              elapsed: elapsed,
              span: span,
              notches: [
                for (final t in catchTimes)
                  t.difference(start).inSeconds / span.inSeconds,
              ],
              board: scheme.surfaceContainer,
              filled: scheme.onSurface,
              tick: context.palette.ruleStrong,
              tickOnFilled: scheme.surface,
              notch: scheme.primary,
              labelStyle: TextStyle(
                fontFamily: PiscatioFonts.condensed,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: context.palette.muted,
              ),
              hourLabel: hourLabel,
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.elapsed,
    required this.span,
    required this.notches,
    required this.board,
    required this.filled,
    required this.tick,
    required this.tickOnFilled,
    required this.notch,
    required this.labelStyle,
    required this.hourLabel,
  });

  final Duration elapsed;
  final Duration span;
  final List<double> notches;
  final Color board;
  final Color filled;
  final Color tick;
  final Color tickOnFilled;
  final Color notch;
  final TextStyle labelStyle;
  final String Function(int hours) hourLabel;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 18.0;
    final boardRect = Rect.fromLTWH(
      0,
      10,
      size.width,
      size.height - 10 - labelHeight,
    );
    final rrect = RRect.fromRectAndRadius(boardRect, const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = board);

    final progress = (elapsed.inSeconds / span.inSeconds).clamp(0.0, 1.0);
    final filledRect = Rect.fromLTWH(
      boardRect.left,
      boardRect.top,
      boardRect.width * progress,
      boardRect.height,
    );
    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawRect(filledRect, Paint()..color = filled)
      ..restore();

    // Ticks every 5 min (short), 15 min (medium) and hour (long), from the
    // top edge like a real board.
    final totalMinutes = span.inMinutes;
    final step = totalMinutes > 240 ? 15 : 5;
    for (var m = step; m < totalMinutes; m += step) {
      final x = boardRect.left + boardRect.width * m / totalMinutes;
      final isHour = m % 60 == 0;
      final isQuarter = m % 15 == 0;
      final length =
          boardRect.height *
          (isHour
              ? 0.62
              : isQuarter
              ? 0.4
              : 0.22);
      final paint = Paint()
        ..color = x <= filledRect.right ? tickOnFilled : tick
        ..strokeWidth = isHour ? 2 : 1.2;
      canvas.drawLine(
        Offset(x, boardRect.top),
        Offset(x, boardRect.top + length),
        paint,
      );
    }

    // Hour labels under the board.
    for (var h = 0; h * 60 <= totalMinutes; h++) {
      final x = boardRect.left + boardRect.width * h * 60 / totalMinutes;
      final tp = TextPainter(
        text: TextSpan(text: hourLabel(h), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(dx, boardRect.bottom + 3));
    }

    // Catches: red notches cut into the top edge.
    final notchPaint = Paint()..color = notch;
    for (final n in notches) {
      final x = boardRect.left + boardRect.width * n.clamp(0.0, 1.0);
      final path = Path()
        ..moveTo(x - 7, 0)
        ..lineTo(x + 7, 0)
        ..lineTo(x, 16)
        ..close();
      canvas.drawPath(path, notchPaint);
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.elapsed != elapsed ||
      old.span != span ||
      old.notches.length != notches.length ||
      old.filled != filled ||
      old.board != board;
}
