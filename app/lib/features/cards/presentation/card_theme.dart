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
    this.photoThemed = false,
    this.photoFrame = CardFrame.fill,
    this.mapFrame = CardFrame.fill,
    this.onFrame,
    this.frames,
    required super.child,
  });

  final CardPalette palette;

  /// The photo given to the card is this filter's separation image.
  final CardPhotoFilter photoFilter;

  /// The photo is painted in the palette's colors (see [photoPaint]).
  final bool photoThemed;

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
      old.photoThemed != photoThemed ||
      old.photoFrame != photoFrame ||
      old.mapFrame != mapFrame ||
      (old.onFrame == null) != (onFrame == null);
}

extension CardPaletteContext on BuildContext {
  CardPalette get cardPalette => CardPaletteScope.of(this);

  CardPhotoFilter get cardPhotoFilter =>
      CardPaletteScope._of(this)?.photoFilter ?? CardPhotoFilter.none;

  bool get cardPhotoThemed => CardPaletteScope._of(this)?.photoThemed ?? false;

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

/// How the card paints its photo: straight ([tint] null, no [base]),
/// through one color matrix ([tint]), or as layers of ink over a [base]
/// color, each reading one channel of the filter's separation.
class PhotoPaint {
  const PhotoPaint({this.tint, this.base, this.layers = const []});

  static const plain = PhotoPaint();

  final ColorFilter? tint;
  final Color? base;
  final List<ColorFilter> layers;
}

/// Natural inks, the same on every theme: black on paper, the earth
/// pigments of a real cave.
abstract final class NaturalInks {
  static const paper = Color(0xFFF5F2EA);
  static const ink = Color(0xFF1C1B1A);
  static const stone = Color(0xFFDCC7A2);
  static const stoneShade = Color(0xFF3B2A1E);
  static const yellowOchre = Color(0xFFC4893F);
  static const redOchre = Color(0xFF94391F);
  static const charcoal = Color(0xFF241C18);
}

/// The two ends of a one-ink print in the theme: its accent on its ground.
/// On dark themes the accent is the light end, so the print stays a
/// positive (light where the photo is light).
({Color light, Color dark}) themeInks(CardPalette p) => p.dark
    ? (light: p.accent, dark: p.ground)
    : (light: p.ground, dark: p.accentInk);

/// The photo painted for [filter], in natural colors or, when [themed], in
/// the palette's.
PhotoPaint photoPaint(CardPalette p, CardPhotoFilter filter, bool themed) {
  int argb(Color c) => c.toARGB32();
  ColorFilter matrix(List<double> m) => ColorFilter.matrix(m);
  switch (filter) {
    case CardPhotoFilter.none:
      return themed
          ? PhotoPaint(
              tint: matrix(
                photoGrade(
                  shadow: argb(p.shadow),
                  light: argb(Color.lerp(p.highlight, p.accent, 0.25)!),
                ),
              ),
            )
          : PhotoPaint.plain;
    case CardPhotoFilter.engraving || CardPhotoFilter.halftone:
      final (:light, :dark) = themed
          ? themeInks(p)
          : (light: NaturalInks.paper, dark: NaturalInks.ink);
      return PhotoPaint(
        tint: matrix(filterTint(base: argb(light), first: argb(dark))),
      );
    case CardPhotoFilter.duotone:
      if (!themed) {
        return PhotoPaint(
          tint: matrix(
            filterTint(
              base: argb(NaturalInks.ink),
              first: argb(NaturalInks.paper),
            ),
          ),
        );
      }
      // Three tones of the theme: its shadow, its accent in the middle, its
      // light.
      return PhotoPaint(
        base: p.shadow,
        layers: [
          matrix(channelInk(color: argb(p.accent), channel: 0, scale: 2)),
          matrix(
            channelInk(
              color: argb(p.highlight),
              channel: 0,
              scale: 2,
              offset: -1,
            ),
          ),
        ],
      );
    case CardPhotoFilter.rupestre:
      final inks = rupestreInks(p, themed: themed);
      // The paint level (green) sets how far down the pigments go: light
      // ochre above 0.7, dark ochre above 0.4, charcoal at the bottom.
      ColorFilter level(Color c, double top) => matrix(
        channelInk(
          color: argb(c),
          channel: 1,
          scale: -1 / 0.3,
          offset: top / 0.3,
        ),
      );
      return PhotoPaint(
        base: inks.stone,
        layers: [
          level(inks.lightOchre, 1.0),
          level(inks.darkOchre, 0.7),
          level(inks.charcoal, 0.4),
          matrix(channelInk(color: argb(inks.charcoal), channel: 0)),
          matrix(channelInk(color: argb(inks.shade), channel: 2)),
        ],
      );
  }
}

/// The cave painting's materials. Natural: sandstone, yellow and red
/// ochre, charcoal. Themed: the stone is the tag's card stock (sand, bone,
/// moonlit grey…), the ochres its accents, the charcoal its ribbon.
({Color stone, Color shade, Color lightOchre, Color darkOchre, Color charcoal})
rupestreInks(CardPalette p, {required bool themed}) {
  if (!themed) {
    return (
      stone: NaturalInks.stone,
      shade: NaturalInks.stoneShade,
      lightOchre: NaturalInks.yellowOchre,
      darkOchre: NaturalInks.redOchre,
      charcoal: NaturalInks.charcoal,
    );
  }
  final stone = Color.lerp(p.stock, p.board, 0.2)!;
  return (
    stone: stone,
    shade: Color.lerp(stone, p.typed, 0.65)!,
    lightOchre: Color.lerp(p.accent, stone, 0.35)!,
    darkOchre: Color.lerp(p.accentInk, p.typed, 0.15)!,
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
