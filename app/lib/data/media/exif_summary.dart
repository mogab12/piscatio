import 'package:exif/exif.dart';

import '../../domain/models/geo_point.dart';

/// What we keep from a photo's EXIF before stripping it: when and where it
/// was taken (used to suggest the date and place of a past trip).
class ExifSummary {
  const ExifSummary({this.takenAt, this.location});

  /// UTC. EXIF times usually have no zone; they are read as device local
  /// time unless an OffsetTimeOriginal tag says otherwise.
  final DateTime? takenAt;
  final GeoPoint? location;

  static const empty = ExifSummary();
}

Future<ExifSummary> readExifSummary(List<int> bytes) async {
  try {
    final tags = await readExifFromBytes(bytes);
    if (tags.isEmpty) return ExifSummary.empty;
    return ExifSummary(takenAt: _takenAt(tags), location: _location(tags));
  } on Object {
    return ExifSummary.empty;
  }
}

DateTime? _takenAt(Map<String, IfdTag> tags) {
  final raw =
      (tags['EXIF DateTimeOriginal'] ?? tags['Image DateTime'])?.printable;
  if (raw == null) return null;
  final m = RegExp(r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})')
      .firstMatch(raw.trim());
  if (m == null) return null;
  final parts = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
  if (parts[0] < 1900) return null;
  final offset = tags['EXIF OffsetTimeOriginal']?.printable.trim();
  final om = offset == null
      ? null
      : RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(offset);
  if (om != null) {
    final sign = om.group(1) == '-' ? -1 : 1;
    final shift = Duration(
      hours: int.parse(om.group(2)!),
      minutes: int.parse(om.group(3)!),
    );
    final asUtc = DateTime.utc(
      parts[0],
      parts[1],
      parts[2],
      parts[3],
      parts[4],
      parts[5],
    );
    return sign > 0 ? asUtc.subtract(shift) : asUtc.add(shift);
  }
  return DateTime(
    parts[0],
    parts[1],
    parts[2],
    parts[3],
    parts[4],
    parts[5],
  ).toUtc();
}

GeoPoint? _location(Map<String, IfdTag> tags) {
  final lat = _degrees(tags['GPS GPSLatitude']);
  final lon = _degrees(tags['GPS GPSLongitude']);
  if (lat == null || lon == null) return null;
  final latRef = tags['GPS GPSLatitudeRef']?.printable.trim().toUpperCase();
  final lonRef = tags['GPS GPSLongitudeRef']?.printable.trim().toUpperCase();
  final signedLat = latRef == 'S' ? -lat : lat;
  final signedLon = lonRef == 'W' ? -lon : lon;
  if (signedLat.abs() > 90 || signedLon.abs() > 180) return null;
  if (signedLat == 0 && signedLon == 0) return null;
  return GeoPoint(signedLat, signedLon);
}

double? _degrees(IfdTag? tag) {
  if (tag == null) return null;
  final values = tag.values.toList();
  if (values.length < 3) return null;
  double part(Object? v) => switch (v) {
    final Ratio r when r.denominator != 0 => r.toDouble(),
    final num n => n.toDouble(),
    _ => double.nan,
  };
  final d = part(values[0]) + part(values[1]) / 60 + part(values[2]) / 3600;
  return d.isNaN ? null : d;
}
