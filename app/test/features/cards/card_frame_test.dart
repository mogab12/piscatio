import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/services/map_sketch.dart';
import 'package:piscatio/features/cards/application/card_data.dart';
import 'package:piscatio/features/cards/presentation/card_canvas.dart';
import 'package:piscatio/features/cards/presentation/painters/map_painter.dart';

void main() {
  group('photo', () {
    // A portrait photo on a story: it overflows sideways only.
    const image = Size(1200, 1600);
    const box = Size(1080, 1920);

    test('at full size it moves only where it overflows', () {
      final shift = CardPhoto.focusShift(const Offset(-36, 50), image, box, 1);
      // Shown 1440 wide in 1080: 360 px of room for a focus range of 2.
      expect(shift.dx, closeTo(0.2, 1e-9));
      expect(shift.dy, 0);
    });

    test('zoomed in, it moves both ways, slower per pixel', () {
      final shift = CardPhoto.focusShift(const Offset(-36, -48), image, box, 2);
      expect(shift.dx, closeTo(72 / 1800, 1e-9));
      expect(shift.dy, closeTo(96 / 1920, 1e-9));
    });
  });

  group('map', () {
    test('its frame never leaves the shapes', () {
      final rng = Random(2);
      for (var n = 0; n < 500; n++) {
        final size = Size(
          300 + rng.nextDouble() * 800,
          300 + rng.nextDouble() * 1200,
        );
        final zoom = 1 + rng.nextDouble() * 1.5;
        final focus = Offset(
          rng.nextDouble() * 2 - 1,
          rng.nextDouble() * 2 - 1,
        );
        final unit = size.shortestSide / 2 * zoom;
        final range = MapPainter.panRange(size, zoom);
        final cx = focus.dx * range.dx, cy = focus.dy * range.dy;
        final halfW = size.width / 2 / unit, halfH = size.height / 2 / unit;
        // Where the frame fits in the shapes at all, it stays inside.
        if (halfW <= MapSketch.extent) {
          expect(cx.abs() + halfW, lessThanOrEqualTo(MapSketch.extent + 1e-9));
        }
        if (halfH <= MapSketch.extent) {
          expect(cy.abs() + halfH, lessThanOrEqualTo(MapSketch.extent + 1e-9));
        }
      }
    });

    test('a drag moves it by the same distance on screen', () {
      const size = Size(1000, 1000);
      // Unit 500 px, room 0.45 units: a 50 px drag is 0.1 units of 0.45.
      final shift = MapPainter.focusShift(const Offset(-50, 0), size, 1);
      expect(shift.dx, closeTo(0.1 / 0.45, 1e-9));
      expect(shift.dy, 0);
    });

    test('the scale bar gets shorter distances when zoomed in', () {
      const steps = [
        CardMapScale(100, '100 m'),
        CardMapScale(200, '200 m'),
        CardMapScale(500, '500 m'),
        CardMapScale(1000, '1 km'),
        CardMapScale(2000, '2 km'),
      ];
      const scale = CardMapScale(2000, '2 km', steps: steps);
      expect(scale.forZoom(9500, 1).label, '2 km');
      expect(scale.forZoom(9500, 2).label, '1 km');
      expect(scale.forZoom(600, 2.5).label, '100 m');
    });
  });

  test('frames stay within their zoom and focus ranges', () {
    const wild = CardFrame(zoom: 9, focus: Offset(3, -2));
    expect(
      wild.clampFor(CardFrameTarget.photo),
      const CardFrame(zoom: 4, focus: Offset(1, -1)),
    );
    expect(wild.clampFor(CardFrameTarget.map).zoom, 2.5);
    expect(const CardFrame(zoom: 0.5).clampFor(CardFrameTarget.map).zoom, 1);
    expect(CardFrame.fill.isFill, isTrue);
  });
}
