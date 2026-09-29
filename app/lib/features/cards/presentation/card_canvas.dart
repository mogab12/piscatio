import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/brand.dart';
import '../application/card_data.dart';
import '../application/photo_filters.dart';
import 'card_theme.dart';

/// Fixed-size drawing surface for a card: [CardFormat.size] canvas pixels,
/// no system text scaling (the image must look the same for everyone).
class CardCanvas extends StatefulWidget {
  const CardCanvas({
    super.key,
    required this.format,
    required this.child,
    this.palette = CardPalette.redHead,
    this.photoFilter = CardPhotoFilter.none,
    this.photoThemed = false,
    this.photoFrame = CardFrame.fill,
    this.mapFrame = CardFrame.fill,
    this.onFrame,
  });

  final CardFormat format;
  final CardPalette palette;
  final CardPhotoFilter photoFilter;
  final bool photoThemed;
  final CardFrame photoFrame;
  final CardFrame mapFrame;

  /// See [CardPaletteScope.onFrame]. While set, a layer over the whole
  /// card turns drags and pinches into frames for the picture under them.
  final void Function(CardFrameTarget target, CardFrame frame)? onFrame;
  final Widget child;

  @override
  State<CardCanvas> createState() => _CardCanvasState();
}

class _CardCanvasState extends State<CardCanvas> {
  final _frames = CardFrameRegistry();
  CardFrameEntry? _entry;
  CardFrame _start = CardFrame.fill;
  Offset _startLocal = Offset.zero;

  CardFrame _frameOf(CardFrameTarget t) =>
      t == CardFrameTarget.photo ? widget.photoFrame : widget.mapFrame;

  void _onStart(ScaleStartDetails d) {
    final entry = _frames.at(d.focalPoint);
    final box = entry?.box();
    _entry = entry;
    if (entry == null || box == null) return;
    _start = _frameOf(entry.target);
    _startLocal = box.globalToLocal(d.focalPoint);
  }

  void _onUpdate(ScaleUpdateDetails d) {
    final entry = _entry;
    final box = entry?.box();
    final report = widget.onFrame;
    if (entry == null || box == null || report == null || !box.attached) {
      return;
    }
    final zoom = (_start.zoom * d.scale).clamp(
      1.0,
      CardFrame.maxZoomFor(entry.target),
    );
    final delta = box.globalToLocal(d.focalPoint) - _startLocal;
    report(
      entry.target,
      CardFrame(
        zoom: zoom,
        focus: _start.focus + entry.shift(delta, box.size, zoom),
      ).clampFor(entry.target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    final palette = widget.palette;
    Widget card = ColoredBox(color: palette.ground, child: widget.child);
    if (widget.onFrame != null) {
      card = Stack(
        fit: StackFit.expand,
        children: [
          card,
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _onStart,
            onScaleUpdate: _onUpdate,
            onScaleEnd: (_) => _entry = null,
          ),
        ],
      );
    }
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: CardPaletteScope(
        palette: palette,
        photoFilter: widget.photoFilter,
        photoThemed: widget.photoThemed,
        photoFrame: widget.photoFrame,
        mapFrame: widget.mapFrame,
        onFrame: widget.onFrame,
        frames: _frames,
        child: SizedBox.fromSize(
          size: widget.format.size,
          child: ClipRect(
            child: DefaultTextStyle(
              style: CardType.text(32, color: palette.text),
              child: card,
            ),
          ),
        ),
      ),
    );
  }
}

/// Number in the card's locale ("2,5" in Portuguese).
String cardNumber(BuildContext context, double v) {
  final f = NumberFormat.decimalPattern(
    Localizations.localeOf(context).toString(),
  )..maximumFractionDigits = 1;
  return f.format(v);
}

/// The catch photo filling its box, framed as the person chose; the
/// card's ground when there is none or it cannot be read. While framing in
/// the editor, dragging over it moves the photo and pinching zooms it (see
/// [CardCanvas.onFrame]).
class CardPhoto extends StatefulWidget {
  const CardPhoto({super.key, required this.path, this.darken = 0});

  final String? path;

  /// 0–1 veil of the card's ground over the photo (darkens it on dark
  /// palettes, lightens it on light ones).
  final double darken;

  static bool exists(String? path) => path != null && File(path).existsSync();

  /// Focus change for a drag of [delta] (in the photo box's pixels) on a
  /// photo of [image] size in a [box], enlarged [zoom] times. The photo
  /// covers the box, so it only moves along the axes where it overflows.
  static Offset focusShift(Offset delta, Size image, Size box, double zoom) {
    final cover = math.max(box.width / image.width, box.height / image.height);
    double axis(double d, double shown, double room) {
      final overflow = shown * zoom - room;
      return overflow < 1 ? 0 : -2 * d / overflow;
    }

    return Offset(
      axis(delta.dx, image.width * cover, box.width),
      axis(delta.dy, image.height * cover, box.height),
    );
  }

  @override
  State<CardPhoto> createState() => _CardPhotoState();
}

class _CardPhotoState extends State<CardPhoto> {
  Size? _imageSize;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  CardFrameRegistry? _frames;
  late final _entry = CardFrameEntry(
    target: CardFrameTarget.photo,
    box: () => mounted ? context.findRenderObject() as RenderBox? : null,
    shift: (delta, box, zoom) =>
        CardPhoto.focusShift(delta, _imageSize ?? box, box, zoom),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final frames = context.cardFrames;
    if (frames != _frames) {
      _frames?.remove(_entry);
      frames?.add(_entry);
      _frames = frames;
    }
    if (context.cardOnFrame != null) _resolveSize();
  }

  @override
  void didUpdateWidget(CardPhoto old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _stopListening();
      _imageSize = null;
      if (context.cardOnFrame != null) _resolveSize();
    }
  }

  /// The photo's pixel size, to turn drags into focus changes.
  void _resolveSize() {
    if (_stream != null || !CardPhoto.exists(widget.path)) return;
    final stream = FileImage(File(widget.path!))
        .resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      _imageSize = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
    });
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _stopListening() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _frames?.remove(_entry);
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cardPalette;
    final ground = palette.ground;
    if (!CardPhoto.exists(widget.path)) return ColoredBox(color: ground);
    final frame = context.cardFrame(CardFrameTarget.photo);
    final align = Alignment(frame.focus.dx, frame.focus.dy);
    final paint = photoPaint(
      palette,
      context.cardPhotoFilter,
      context.cardPhotoThemed,
    );
    final image = Image.file(
      File(widget.path!),
      fit: BoxFit.cover,
      alignment: align,
      errorBuilder: (_, _, _) => ColoredBox(color: ground),
    );
    final tint = paint.tint;
    final base = paint.base;
    Widget photo = Stack(
      fit: StackFit.expand,
      children: [
        if (base != null) ...[
          // Inks laid one over the other on their ground.
          ColoredBox(color: base),
          for (final layer in paint.layers)
            ColorFiltered(colorFilter: layer, child: image),
        ] else if (tint == null)
          image
        else
          ColorFiltered(colorFilter: tint, child: image),
      ],
    );
    if (frame.zoom != 1) {
      // Enlarged around the kept part: the box stays covered.
      photo = ClipRect(
        child: Transform.scale(
          scale: frame.zoom,
          alignment: align,
          child: photo,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        photo,
        if (widget.darken > 0)
          ColoredBox(color: ground.withValues(alpha: widget.darken)),
      ],
    );
  }
}

/// A sketch map painted by [painter] for the current frame, framed as the
/// person chose. While framing in the editor, dragging over it moves the
/// map and pinching zooms it (see [CardCanvas.onFrame]).
class CardMapFrame extends StatefulWidget {
  const CardMapFrame({
    super.key,
    required this.painter,
    required this.focusShift,
  });

  final CustomPainter Function(CardFrame frame) painter;

  /// Focus change for a drag of `delta` on a `size` frame at `zoom`.
  final Offset Function(Offset delta, Size size, double zoom) focusShift;

  @override
  State<CardMapFrame> createState() => _CardMapFrameState();
}

class _CardMapFrameState extends State<CardMapFrame> {
  CardFrameRegistry? _frames;
  late final _entry = CardFrameEntry(
    target: CardFrameTarget.map,
    box: () => mounted ? context.findRenderObject() as RenderBox? : null,
    shift: (delta, box, zoom) => widget.focusShift(delta, box, zoom),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final frames = context.cardFrames;
    if (frames != _frames) {
      _frames?.remove(_entry);
      frames?.add(_entry);
      _frames = frames;
    }
  }

  @override
  void dispose() {
    _frames?.remove(_entry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: widget.painter(context.cardFrame(CardFrameTarget.map)),
  );
}

/// Small brand mark (float + name) for imprints and printed labels.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    required this.color,
    this.size = 34,
    this.floatBottom,
  });

  final double size;
  final Color color;

  /// Lower half of the float, e.g. the paper it is printed on.
  final Color? floatBottom;

  @override
  Widget build(BuildContext context) =>
      BrandLockup(size: size, color: color, floatBottom: floatBottom);
}

/// Where the brand sits on every card: top left, big enough to read in a
/// story at a glance, with the tagline. Inside the story safe zone (clear
/// of the platform's own header).
class CardSignature extends StatelessWidget {
  const CardSignature({
    super.key,
    required this.format,
    this.color,
    this.floatBottom,
  });

  final CardFormat format;

  /// Defaults to the palette's text color.
  final Color? color;
  final Color? floatBottom;

  /// Top-left corner of the signature.
  static Offset originFor(CardFormat format) => format == CardFormat.story
      ? const Offset(72, CardSafeArea.storyTop)
      : const Offset(60, 56);

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    return BrandLockup(
      size: format == CardFormat.story ? 80 : 60,
      color: color ?? p.text,
      floatBottom: floatBottom ?? floatBottomFor(p),
      tagline: true,
    );
  }

  /// White below the waterline on dark grounds; on light ones the float
  /// takes the paper's color inside its dark outline.
  static Color floatBottomFor(CardPalette p) => p.dark ? p.text : p.ground;
}

/// Stories get covered by the platform's UI: the header (progress bar,
/// profile) at the top and the reply bar at the bottom. Content stays
/// between these lines.
abstract final class CardSafeArea {
  static const storyTop = 230.0;
  static const storyBottom = 250.0;
}

/// Big number with its unit set smaller on the same baseline: "52 cm",
/// "2 lb 3 oz".
class CardHeadline extends StatelessWidget {
  const CardHeadline({
    super.key,
    required this.parts,
    required this.size,
    this.color,
    this.unitColor,
  });

  final List<CardQuantity> parts;
  final double size;

  /// Defaults to the palette's text color.
  final Color? color;
  final Color? unitColor;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.cardPalette.text;
    final number = CardType.numbers(size, color: color);
    final unit = CardType.numbers(
      size * 0.32,
      color: unitColor ?? color,
      weight: FontWeight.w800,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomLeft,
      child: Text.rich(
        TextSpan(
          children: [
            for (final (i, q) in parts.indexed) ...[
              if (i > 0) TextSpan(text: '  ', style: unit),
              TextSpan(text: q.value, style: number),
              TextSpan(text: ' ${q.unit}', style: unit),
            ],
          ],
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
