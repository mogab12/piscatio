import 'dart:ui';

import '../../../domain/models/enums.dart';
import '../../../domain/services/map_sketch.dart';
import '../../../domain/services/ruler_scale.dart';
import 'photo_filters.dart';

enum CardStyle { board, cover, chart, tag, map }

enum CardFormat {
  story(Size(1080, 1920)),
  square(Size(1080, 1080));

  const CardFormat(this.size);

  final Size size;
}

/// A card's whole color scheme: the ground it is printed on, its text, the
/// accent, the record color and the materials (measuring board, specimen
/// tag). Each is named after something from the water.
///
/// Only the key colors are set by hand; the rest are mixed from them so
/// every palette stays coherent.
enum CardPalette {
  /// The brand: red-head lure over deep water.
  redHead(
    dark: true,
    ground: Color(0xFF0B2A33),
    text: Color(0xFFFFFFFF),
    line: Color(0xFF1C4854),
    accent: Color(0xFFFF6A5E),
    accentInk: Color(0xFFE4262C),
    record: Color(0xFFF4B400),
    board: Color(0xFFF7F9F8),
    boardInk: Color(0xFF0B2A33),
    stock: Color(0xFFE4D29E),
    typed: Color(0xFF1D2326),
    string: Color(0xFFEFE8D6),
  ),

  /// Logbook paper: deep water ink, red pencil.
  paper(
    dark: false,
    ground: Color(0xFFF3EFE6),
    text: Color(0xFF0B2A33),
    line: Color(0xFFDCD6C8),
    accent: Color(0xFFE4262C),
    accentInk: Color(0xFFD0202A),
    record: Color(0xFF8F6400),
    board: Color(0xFFFFFFFF),
    boardInk: Color(0xFF0B2A33),
    stock: Color(0xFFD6C49B),
    typed: Color(0xFF0B2A33),
    string: Color(0xFF8C7B5A),
  ),

  /// Peacock bass: olive and gold, the red of its eye for records.
  tucunare(
    dark: true,
    ground: Color(0xFF1A2310),
    text: Color(0xFFF5EFD8),
    line: Color(0xFF2E3A1C),
    accent: Color(0xFFF2B705),
    accentInk: Color(0xFFB7410F),
    record: Color(0xFFFF7A45),
    board: Color(0xFFF3ECD2),
    boardInk: Color(0xFF1A2310),
    stock: Color(0xFFDCCB8C),
    typed: Color(0xFF1A2310),
    string: Color(0xFFEDE3C4),
  ),

  /// First light on the water: peach sky, plum ink.
  dawn(
    dark: false,
    ground: Color(0xFFF7E3D2),
    text: Color(0xFF2B1B3E),
    line: Color(0xFFEBCDB8),
    accent: Color(0xFFE0502B),
    accentInk: Color(0xFFCB4020),
    record: Color(0xFF8A5800),
    board: Color(0xFFFFFAF4),
    boardInk: Color(0xFF2B1B3E),
    stock: Color(0xFFEBC9A4),
    typed: Color(0xFF2B1B3E),
    string: Color(0xFF7A5A6E),
  ),

  /// Night fishing: moonlight blue, the moon's gold for records.
  moon(
    dark: true,
    ground: Color(0xFF0A0E1C),
    text: Color(0xFFEAEEF7),
    line: Color(0xFF1A2340),
    accent: Color(0xFF9DB9FF),
    accentInk: Color(0xFF3355CC),
    record: Color(0xFFF3D46B),
    board: Color(0xFFE6EAF3),
    boardInk: Color(0xFF0A0E1C),
    stock: Color(0xFFCDD3E0),
    typed: Color(0xFF0A0E1C),
    string: Color(0xFFD8DDE8),
  ),

  /// River green and a chartreuse lure.
  river(
    dark: true,
    ground: Color(0xFF1F352D),
    text: Color(0xFFF3F0E4),
    line: Color(0xFF2D4A3F),
    accent: Color(0xFFCBDD3F),
    accentInk: Color(0xFF5E7A0A),
    record: Color(0xFFF4B400),
    board: Color(0xFFF3F0E4),
    boardInk: Color(0xFF1F352D),
    stock: Color(0xFFE3D5AE),
    typed: Color(0xFF1F352D),
    string: Color(0xFFEFE8D6),
  );

  const CardPalette({
    required this.dark,
    required this.ground,
    required this.text,
    required this.line,
    required this.accent,
    required this.accentInk,
    required this.record,
    required this.board,
    required this.boardInk,
    required this.stock,
    required this.typed,
    required this.string,
  });

  /// Light text on a dark ground (scrims darken photos) or the opposite.
  final bool dark;

  /// What the card is printed on; also the scrim over photos.
  final Color ground;
  final Color text;

  /// Faint linework on the ground (chart contours).
  final Color line;

  /// Accent on the ground.
  final Color accent;

  /// Accent printed on the light materials (board mark, stamp ink).
  final Color accentInk;
  final Color record;

  /// Measuring board plastic and the ink printed on it.
  final Color board;
  final Color boardInk;

  /// Specimen tag card stock and the typewriter ribbon.
  final Color stock;
  final Color typed;
  final Color string;

  Color get ground2 => Color.lerp(ground, text, 0.05)!;
  Color get ground3 => Color.lerp(ground, text, 0.10)!;

  /// Secondary text, still readable.
  Color get soft => Color.lerp(text, ground, 0.06)!;
  Color get muted => Color.lerp(text, ground, dark ? 0.36 : 0.32)!;
  Color get lineStrong => Color.lerp(line, text, 0.08)!;
  Color get sounding => Color.lerp(line, text, 0.18)!;

  /// Record color on the light materials.
  Color get recordInk => dark ? Color.lerp(record, boardInk, 0.28)! : record;
  Color get boardStop => Color.lerp(boardInk, board, 0.15)!;
  Color get boardFill => Color.lerp(board, boardInk, 0.1)!;
  Color get stockShade => Color.lerp(stock, typed, 0.08)!;
  Color get stockEdge => Color.lerp(stock, typed, 0.16)!;

  /// The dark and light ends of the palette, for photo filters.
  Color get shadow =>
      dark ? Color.lerp(ground, const Color(0xFF000000), 0.2)! : text;
  Color get highlight => dark ? soft : board;
}

/// What the person chose in the card editor.
class CardOptions {
  const CardOptions({
    this.palette = CardPalette.redHead,
    this.showPlace = true,
    this.showWeather = true,
    this.showBait = true,
    this.showMap = true,
    this.caption,
    this.photoChosen = false,
    this.photoPath,
    this.photoFilter = CardPhotoFilter.none,
    this.filteredPath,
    this.photoFrame = CardFrame.fill,
    this.mapFrame = CardFrame.fill,
    this.photoThemed = false,
    this.audience = CardAudience.everyone,
  });

  final CardPalette palette;
  final bool showPlace;

  /// Weather and moon.
  final bool showWeather;
  final bool showBait;

  /// The sketch map of the place, when the trip's privacy allows one.
  final bool showMap;

  /// Free text written by the person; empty or null shows nothing.
  final String? caption;

  /// When true, [photoPath] replaces the card's default photo (null = the
  /// card goes without a photo).
  final bool photoChosen;
  final String? photoPath;

  /// The look chosen for the photo, and its separation image once it is
  /// ready (until then the card shows the plain photo).
  final CardPhotoFilter photoFilter;
  final String? filteredPath;

  /// Zoom and position of the photo and of the map, set by the person.
  final CardFrame photoFrame;
  final CardFrame mapFrame;

  /// The photo (plain or filtered) painted in the theme's colors instead
  /// of natural ones.
  final bool photoThemed;

  /// Who will see the card: a card for friends may show more of the place.
  final CardAudience audience;

  /// The filter the card draws right now.
  CardPhotoFilter get activeFilter =>
      filteredPath == null ? CardPhotoFilter.none : photoFilter;

  /// The photo shown before any filter, given the card's default one.
  String? sourcePhoto(String? defaultPath) =>
      photoChosen ? photoPath : defaultPath;

  String? _shownPhoto(String? defaultPath) {
    final source = sourcePhoto(defaultPath);
    return source == null ? null : filteredPath ?? source;
  }

  String? get _caption {
    final c = caption?.trim();
    return c == null || c.isEmpty ? null : c;
  }

  CardOptions copyWith({
    CardPalette? palette,
    bool? showPlace,
    bool? showWeather,
    bool? showBait,
    bool? showMap,
    String? caption,
    CardFrame? photoFrame,
    CardFrame? mapFrame,
    bool? photoThemed,
    CardAudience? audience,
  }) => CardOptions(
    palette: palette ?? this.palette,
    showPlace: showPlace ?? this.showPlace,
    showWeather: showWeather ?? this.showWeather,
    showBait: showBait ?? this.showBait,
    showMap: showMap ?? this.showMap,
    caption: caption ?? this.caption,
    photoChosen: photoChosen,
    photoPath: photoPath,
    photoFilter: photoFilter,
    filteredPath: filteredPath,
    photoFrame: photoFrame ?? this.photoFrame,
    mapFrame: mapFrame ?? this.mapFrame,
    photoThemed: photoThemed ?? this.photoThemed,
    audience: audience ?? this.audience,
  );

  /// Another photo: its filtered version has to be made again, and it is
  /// framed afresh.
  CardOptions withPhoto(String? path) => CardOptions(
    palette: palette,
    showPlace: showPlace,
    showWeather: showWeather,
    showBait: showBait,
    showMap: showMap,
    caption: caption,
    photoChosen: true,
    photoPath: path,
    photoFilter: photoFilter,
    mapFrame: mapFrame,
    photoThemed: photoThemed,
    audience: audience,
  );

  CardOptions withFilter(CardPhotoFilter filter, {String? filteredPath}) =>
      CardOptions(
        palette: palette,
        showPlace: showPlace,
        showWeather: showWeather,
        showBait: showBait,
        showMap: showMap,
        caption: caption,
        photoChosen: photoChosen,
        photoPath: photoPath,
        photoFilter: filter,
        filteredPath: filter == CardPhotoFilter.none ? null : filteredPath,
        photoFrame: photoFrame,
        mapFrame: mapFrame,
        photoThemed: photoThemed,
        audience: audience,
      );
}

/// What a [CardFrame] applies to.
enum CardFrameTarget { photo, map }

/// How the person framed a picture on the card: [zoom] (1 fills the frame)
/// and [focus], the part kept in view, from -1 to 1 on each axis like an
/// alignment (0, 0 is the middle).
class CardFrame {
  const CardFrame({this.zoom = 1, this.focus = Offset.zero});

  /// The picture filling its frame, centered.
  static const fill = CardFrame();

  /// Photos can be enlarged further than maps: map lines are simplified
  /// for about one pixel of detail at full size.
  static double maxZoomFor(CardFrameTarget target) =>
      target == CardFrameTarget.photo ? 4 : 2.5;

  final double zoom;
  final Offset focus;

  bool get isFill => zoom == 1 && focus == Offset.zero;

  /// Within the zoom range of [target] and the focus range.
  CardFrame clampFor(CardFrameTarget target) => CardFrame(
    zoom: zoom.clamp(1.0, maxZoomFor(target)),
    focus: Offset(focus.dx.clamp(-1.0, 1.0), focus.dy.clamp(-1.0, 1.0)),
  );

  @override
  bool operator ==(Object other) =>
      other is CardFrame && other.zoom == zoom && other.focus == focus;

  @override
  int get hashCode => Object.hash(zoom, focus);

  @override
  String toString() => 'CardFrame($zoom, $focus)';
}

/// Record content, already localized.
class CardRecord {
  const CardRecord.first() : isFirst = true, improvement = null;

  const CardRecord.record({this.improvement}) : isFirst = false;

  final bool isFirst;

  /// "+14%"; null when there was no earlier measurement to compare.
  final String? improvement;
}

class CardMoon {
  const CardMoon({
    required this.illumination,
    required this.waxing,
    required this.label,
    this.southern = false,
  });

  final double illumination;
  final bool waxing;
  final String label;

  /// Seen from the southern hemisphere the lit side is mirrored. Only the
  /// hemisphere is known here, never the coordinates.
  final bool southern;
}

/// A number and its unit, styled apart on cards ("52" big, "cm" small).
class CardQuantity {
  const CardQuantity(this.value, this.unit);

  final String value;
  final String unit;

  @override
  String toString() => '$value $unit';
}

class CardWind {
  const CardWind({required this.fromDegrees, required this.label});

  final double fromDegrees;

  /// "9 km/h SE".
  final String label;
}

/// The map's scale bar: a round distance in the user's units.
class CardMapScale {
  const CardMapScale(this.meters, this.label, {this.steps = const []});

  final double meters;

  /// "2 km", "1 mi".
  final String label;

  /// Every round distance offered, shortest first, for zoomed-in maps.
  final List<CardMapScale> steps;

  /// The scale for a map enlarged [zoom] times: about a third of the
  /// visible half-width, like at full size.
  CardMapScale forZoom(double metersPerUnit, double zoom) {
    if (zoom <= 1 || steps.isEmpty) return this;
    final target = metersPerUnit * 0.4 / zoom;
    return steps.lastWhere(
      (s) => s.meters <= target,
      orElse: () => steps.first,
    );
  }
}

/// Everything a catch card shows, localized and in the user's units.
///
/// Deliberately has **no coordinates**: a card cannot leak the spot, only
/// the [place] text allowed by the trip's privacy level.
class CatchCardData {
  const CatchCardData({
    required this.id,
    required this.speciesName,
    required this.dateLabel,
    required this.timeLabel,
    required this.romanDate,
    required this.catchNumber,
    required this.ruler,
    required this.rulerUnit,
    this.moon,
    this.headline = const [],
    this.scientificName,
    this.place,
    this.friendsPlace,
    this.lengthLabel,
    this.weightLabel,
    this.baitLabel,
    this.released,
    this.photoPath,
    this.photoOptions = const [],
    this.record,
    this.previousRecordLabel,
    this.wind,
    this.temperatureLabel,
    this.pressureLabel,
    this.caption,
    this.map,
    this.mapScale,
  });

  final String id;
  final String speciesName;
  final String? scientificName;
  final String dateLabel;
  final String timeLabel;
  final String romanDate;
  final String? place;

  /// The place allowed on a card shown only to friends (see [cardPlace]).
  final String? friendsPlace;
  final String? lengthLabel;
  final String? weightLabel;
  final String? baitLabel;
  final bool? released;

  /// Position of this catch in the user's whole logbook (1-based).
  final int catchNumber;

  /// Absolute path of the photo (EXIF already stripped at import).
  final String? photoPath;

  /// Every photo the person may pick for this card.
  final List<String> photoOptions;
  final RulerScale ruler;

  /// Unit printed at the end of the board ("cm", "lb", "h").
  final String rulerUnit;

  /// The featured measure (length, else weight), split for styling; empty
  /// when the catch was not measured.
  final List<CardQuantity> headline;
  final CardRecord? record;

  /// "46 cm": the best before this catch, for the board's record mark.
  final String? previousRecordLabel;
  final CardMoon? moon;
  final CardWind? wind;
  final String? temperatureLabel;
  final String? pressureLabel;

  /// The person's own words for this card.
  final String? caption;

  /// The place as a sketch map: relative shapes and a ring, no coordinates.
  /// Null for private trips.
  final MapSketch? map;
  final CardMapScale? mapScale;

  /// The card as the person set it up: hidden details removed, the chosen
  /// photo and caption applied. Privacy only ever removes information.
  CatchCardData customized(CardOptions o) => CatchCardData(
    id: id,
    speciesName: speciesName,
    scientificName: scientificName,
    dateLabel: dateLabel,
    timeLabel: timeLabel,
    romanDate: romanDate,
    catchNumber: catchNumber,
    ruler: ruler,
    rulerUnit: rulerUnit,
    headline: headline,
    moon: o.showWeather ? moon : null,
    place: o.showPlace
        ? (o.audience == CardAudience.friends ? friendsPlace : place)
        : null,
    lengthLabel: lengthLabel,
    weightLabel: weightLabel,
    baitLabel: o.showBait ? baitLabel : null,
    released: released,
    photoPath: o._shownPhoto(photoPath),
    photoOptions: photoOptions,
    record: record,
    previousRecordLabel: previousRecordLabel,
    wind: o.showWeather ? wind : null,
    temperatureLabel: o.showWeather ? temperatureLabel : null,
    pressureLabel: o.showWeather ? pressureLabel : null,
    caption: o._caption,
    map: o.showMap ? map : null,
    mapScale: mapScale,
  );
}

/// One catch as a line of a trip card.
class TripCardCatch {
  const TripCardCatch({
    required this.speciesName,
    required this.timeLabel,
    required this.offset,
    this.measureLabel,
    this.isRecord = false,
  });

  final String speciesName;
  final String timeLabel;
  final String? measureLabel;

  /// Position on the trip's time scale, 0–1.
  final double offset;
  final bool isRecord;
}

class TripCardData {
  const TripCardData({
    required this.id,
    required this.dateLabel,
    required this.romanDate,
    required this.durationLabel,
    required this.timeRangeLabel,
    required this.catchCount,
    required this.speciesCount,
    required this.catches,
    required this.speciesTally,
    required this.spanHours,
    required this.elapsedFraction,
    this.moon,
    this.place,
    this.friendsPlace,
    this.biggestLabel,
    this.topBaitLabel,
    this.photoPath,
    this.photoOptions = const [],
    this.recordCount = 0,
    this.wind,
    this.temperatureLabel,
    this.pressureLabel,
    this.caption,
    this.map,
    this.mapScale,
  });

  final String id;
  final String dateLabel;
  final String romanDate;
  final String? place;

  /// The place allowed on a card shown only to friends (see [cardPlace]).
  final String? friendsPlace;
  final String durationLabel;
  final String timeRangeLabel;
  final int catchCount;
  final int speciesCount;

  /// Chronological.
  final List<TripCardCatch> catches;

  /// Species with their catch counts, most caught first.
  final List<(String, int)> speciesTally;

  /// Length of the time board in hours and how much of it the trip used.
  final double spanHours;
  final double elapsedFraction;
  final String? biggestLabel;
  final String? topBaitLabel;
  final String? photoPath;

  /// Every photo of the trip's catches, for the editor to offer.
  final List<String> photoOptions;
  final int recordCount;
  final CardMoon? moon;
  final CardWind? wind;
  final String? temperatureLabel;
  final String? pressureLabel;
  final String? caption;
  final MapSketch? map;
  final CardMapScale? mapScale;

  TripCardData customized(CardOptions o) => TripCardData(
    id: id,
    dateLabel: dateLabel,
    romanDate: romanDate,
    durationLabel: durationLabel,
    timeRangeLabel: timeRangeLabel,
    catchCount: catchCount,
    speciesCount: speciesCount,
    catches: catches,
    speciesTally: speciesTally,
    spanHours: spanHours,
    elapsedFraction: elapsedFraction,
    moon: o.showWeather ? moon : null,
    place: o.showPlace
        ? (o.audience == CardAudience.friends ? friendsPlace : place)
        : null,
    biggestLabel: biggestLabel,
    topBaitLabel: o.showBait ? topBaitLabel : null,
    photoPath: o._shownPhoto(photoPath),
    photoOptions: photoOptions,
    recordCount: recordCount,
    wind: o.showWeather ? wind : null,
    temperatureLabel: o.showWeather ? temperatureLabel : null,
    pressureLabel: o.showWeather ? pressureLabel : null,
    caption: o._caption,
    map: o.showMap ? map : null,
    mapScale: mapScale,
  );
}
