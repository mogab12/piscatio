import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/services/past_trip.dart';

final _now = DateTime.utc(2026, 9, 20, 12);

void main() {
  test('no photo time, no suggestion', () {
    expect(
      suggestFromPhotos([(takenAt: null, location: null)], now: _now),
      isNull,
    );
  });

  test('spans first to last photo with margins; first place wins', () {
    final s = suggestFromPhotos([
      (takenAt: DateTime.utc(2026, 9, 10, 8), location: null),
      (
        takenAt: DateTime.utc(2026, 9, 10, 6, 30),
        location: const GeoPoint(-16.5, -56.4),
      ),
      (takenAt: null, location: const GeoPoint(-1, -1)),
    ], now: _now)!;
    expect(s.start, DateTime.utc(2026, 9, 10, 6, 15));
    expect(s.end, DateTime.utc(2026, 9, 10, 8, 15));
    expect(s.location, const GeoPoint(-16.5, -56.4));
  });

  test('a single photo gives an hour; never ends in the future', () {
    final one = suggestFromPhotos([
      (takenAt: DateTime.utc(2026, 9, 10, 7), location: null),
    ], now: _now)!;
    expect(one.end.difference(one.start), const Duration(hours: 1));
    final recent = suggestFromPhotos([
      (takenAt: _now.subtract(const Duration(minutes: 5)), location: null),
    ], now: _now)!;
    expect(recent.end, _now);
    expect(recent.start, _now.subtract(const Duration(hours: 1)));
  });
}
