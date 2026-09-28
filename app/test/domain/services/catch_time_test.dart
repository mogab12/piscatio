import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/trip.dart';
import 'package:piscatio/domain/services/catch_time.dart';
import 'package:piscatio/domain/services/moon.dart';

final _start = DateTime.utc(2026, 9, 12, 6);

Trip _trip({DateTime? end}) => Trip(
  id: 't',
  startedAt: _start,
  endedAt: end,
  timezone: 'UTC',
  privacyLevel: PrivacyLevel.private,
  moonPhase: MoonPhase.newMoon,
  moonIllumination: 0,
  createdAt: _start,
  updatedAt: _start,
);

void main() {
  final now = _start.add(const Duration(hours: 2));

  test('photo time inside the trip wins', () {
    final shot = _start.add(const Duration(minutes: 40));
    expect(defaultCatchTime(trip: _trip(), now: now, photoTakenAt: shot), shot);
  });

  test('running trip without usable photo time uses now', () {
    expect(defaultCatchTime(trip: _trip(), now: now), now);
    expect(
      defaultCatchTime(
        trip: _trip(),
        now: now,
        photoTakenAt: DateTime.utc(2025, 3, 2),
      ),
      now,
    );
  });

  test('past trip: photo inside the window, else the trip end', () {
    final end = _start.add(const Duration(hours: 4));
    final trip = _trip(end: end);
    final later = DateTime.utc(2026, 9, 20);
    expect(defaultCatchTime(trip: trip, now: later), end);
    final shot = _start.add(const Duration(hours: 3));
    expect(defaultCatchTime(trip: trip, now: later, photoTakenAt: shot), shot);
    expect(
      defaultCatchTime(
        trip: trip,
        now: later,
        photoTakenAt: end.add(const Duration(hours: 1)),
      ),
      end,
    );
  });
}
