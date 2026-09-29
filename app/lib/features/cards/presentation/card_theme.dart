import 'package:flutter/widgets.dart';

import '../../../core/theme/tokens.dart';
import '../application/card_data.dart';
import '../application/photo_filters.dart';

/// Makes the card's palette (and how its photo is drawn) available to
/// everything on it, whatever the app theme: a shared card must look the
/// same for everyone.
class CardPaletteScope extends InheritedWidget {
  const CardPaletteScope({
    super.key,
    required this.palette,
    this.photoFilter = CardPhotoFilter.none,
    this.photoFrame = CardFrame.fill,
    this.mapFrame = CardFrame.fill,
    this.onFrame,
    this.frames,
    required super.child,
  });

  final CardPalette palette;

  /// The photo given to the card is this filter's separation image.
  final CardPhotoFilter photoFilter;

  /// How the photo and the map are framed.
  final CardFrame photoFrame;
  final CardFrame mapFrame;

  /// Set while the person frames the card in the editor: dragging and
  /// pinching the photo or the map report the new frame here.
  final void Function(CardFrameTarget target, CardFrame frame)? onFrame;

  /// Where the framable pictures are on this card (see [CardFrameRegistry]).
  final CardFrameRegistry? frames;

  static CardPaletteScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardPaletteScope>();

  static CardPalette of(BuildContext context) =>
      _of(context)?.palette ?? CardPalette.redHead;

  @override
  bool updateShouldNotify(CardPaletteScope old) =>
      old.palette != palette ||
      old.photoFilter != photoFilter ||
      old.photoFrame != photoFrame ||
      old.mapFrame != mapFrame ||
      (old.onFrame == null) != (onFrame == null);
}

extension CardPaletteContext on BuildContext {
  CardPalette get cardPalette => CardPaletteScope.of(this);

  CardPhotoFilter get cardPhotoFilter =>
      CardPaletteScope._of(this)?.photoFilter ?? CardPhotoFilter.none;

  CardFrame cardFrame(CardFrameTarget target) {
    final scope = CardPaletteScope._of(this);
    if (scope == null) return CardFrame.fill;
    return target == CardFrameTarget.photo ? scope.photoFrame : scope.mapFrame;
  }

  void Function(CardFrameTarget target, CardFrame frame)? get cardOnFrame =>
      CardPaletteScope._of(this)?.onFrame;

  CardFrameRegistry? get cardFrames => CardPaletteScope._of(this)?.frames;
}

/// A picture on the card that can be framed: its box on screen and how a
/// drag inside it changes its focus.
class CardFrameEntry {
  CardFrameEntry({
    required this.target,
    required this.box,
    required this.shift,
  });

  final CardFrameTarget target;
  final RenderBox? Function() box;

  /// Focus change for a drag of `delta` (in the box's pixels) at `zoom`.
  final Offset Function(Offset delta, Size box, double zoom) shift;
}

/// The framable pictures of one card. The card's gesture layer asks it
/// which picture is under the finger: overlays drawn above the photo (text,
/// veils) must not swallow the gesture.
class CardFrameRegistry {
  final _entries = <CardFrameEntry>[];

  void add(CardFrameEntry e) => _entries.add(e);

  void remove(CardFrameEntry e) => _entries.remove(e);

  /// The smallest picture containing [global] (a photo window wins over the
  /// map behind it), or null.
  CardFrameEntry? at(Offset global) {
    CardFrameEntry? best;
    var bestArea = double.infinity;
    for (final e in _entries) {
      final box = e.box();
      if (box == null || !box.attached || !box.hasSize) continue;
      if (!(Offset.zero & box.size).contains(box.globalToLocal(global))) {
        continue;
      }
      final area = box.size.width * box.size.height;
      if (area < bestArea) {
        best = e;
        bestArea = area;
      }
    }
    return best;
  }
}

/// Inks a one-ink filtered photo in the palette's colors: drawings in the
/// board's ink on its white, the duotone from the palette's shadow to its
/// light. Null for the plain photo and for layered filters ([rupestreInks]).
ColorFilter? photoTint(CardPalette p, CardPhotoFilter filter) {
  int argb(Color c) => c.toARGB32();
  final matrix = switch (filter) {
    CardPhotoFilter.none || CardPhotoFilter.rupestre => null,
    CardPhotoFilter.duotone => filterTint(
      base: argb(p.shadow),
      first: argb(p.highlight),
    ),
    CardPhotoFilter.engraving || CardPhotoFilter.halftone => filterTint(
      base: argb(p.board),
      first: argb(p.boardInk),
    ),
  };
  return matrix == null ? null : ColorFilter.matrix(matrix);
}

/// The cave painting in the theme's materials: its stone is the tag's card
/// stock (sand, bone, moonlit grey…), the ochre its accent ink, the
/// charcoal its typewriter ribbon.
({Color stone, Color relief, Color ochre, Color charcoal}) rupestreInks(
  CardPalette p,
) {
  final stone = Color.lerp(p.stock, p.board, 0.2)!;
  return (
    stone: stone,
    relief: Color.lerp(stone, p.typed, 0.5)!,
    ochre: p.accentInk,
    charcoal: p.typed,
  );
}

/// Text styles on the fixed card canvas (sizes in canvas pixels). Without a
/// color they take the palette's text color from the canvas.
abstract final class CardType {
  /// Big numbers: Archivo Expanded heavy italic, the "boat decal" voice.
  static TextStyle numbers(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w900,
  }) => TextStyle(
    fontFamily: PiscatioFonts.expanded,
    fontStyle: FontStyle.italic,
    fontWeight: weight,
    fontSize: size,
    height: 0.9,
    letterSpacing: -size * 0.02,
    color: color,
  );

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    FontStyle style = FontStyle.normal,
    double height = 1.2,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: PiscatioFonts.text,
    fontWeight: weight,
    fontStyle: style,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  /// Dense labels and table heads.
  static TextStyle condensed(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.1,
  }) => TextStyle(
    fontFamily: PiscatioFonts.condensed,
    fontWeight: weight,
    fontSize: size,
    height: height,
    color: color,
  );

  /// Typewriter, only on the specimen tag.
  static TextStyle typed(
    double size, {
    Color? color,
    bool italic = false,
    bool bold = false,
  }) => TextStyle(
    fontFamily: PiscatioFonts.typed,
    fontSize: size,
    height: 1.15,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    color: color,
  );
}
