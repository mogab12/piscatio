import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piscatio/data/remote/nasa_power_client.dart';
import 'package:piscatio/domain/models/geo_point.dart';

final _fixture = File('test/fixtures/power_hourly.json').readAsStringSync();

void main() {
  group('hourlyUri', () {
    test('rounds coordinates to two decimals and formats UTC days', () {
      final uri = NasaPowerClient.hourlyUri(
        const GeoPoint(-16.523456, -56.419999),
        DateTime.utc(2026, 9, 10, 3),
        DateTime.utc(2026, 9, 11, 22),
      );
      expect(uri.host, 'power.larc.nasa.gov');
      expect(uri.path, '/api/temporal/hourly/point');
      expect(uri.queryParameters['latitude'], '-16.52');
      expect(uri.queryParameters['longitude'], '-56.42');
      expect(uri.queryParameters['start'], '20260910');
      expect(uri.queryParameters['end'], '20260911');
      expect(uri.queryParameters['time-standard'], 'UTC');
      expect(uri.queryParameters['community'], 'RE');
      expect(
        uri.queryParameters['parameters'],
        'T2M,PS,WS10M,WD10M,PRECTOTCORR,RH2M',
      );
    });
  });

  group('parseHourly', () {
    final hours = NasaPowerClient.parseHourly(_fixture);

    test('reads every hour in UTC order', () {
      expect(hours, hasLength(24));
      expect(hours.first.time, DateTime.utc(2026, 9, 10));
      expect(hours.last.time, DateTime.utc(2026, 9, 10, 23));
    });

    test('converts units: kPa to sea-level hPa, m/s to km/h', () {
      final h = hours[6];
      expect(h.temperatureC, 27.0);
      // 98.98 kPa at 190 m reduces to about 1011 hPa at sea level.
      expect(h.pressureHpa, closeTo(1011.4, 0.5));
      expect(h.windSpeedKmh, closeTo(9.0, 1e-9));
      expect(h.windDirectionDeg, 135);
      expect(h.humidityPct, 70);
      expect(hours[7].precipitationMm, 0.4);
    });

    test('fill values become null', () {
      final late = hours[22];
      expect(late.temperatureC, isNull);
      expect(late.pressureHpa, isNull);
      expect(late.windSpeedKmh, isNull);
    });

    test('rejects responses without a parameter block', () {
      expect(
        () => NasaPowerClient.parseHourly('{"messages": ["error"]}'),
        throwsFormatException,
      );
      expect(() => NasaPowerClient.parseHourly('[]'), throwsFormatException);
    });
  });

  group('fetchHourly', () {
    test('returns parsed hours on 200', () async {
      late Uri seen;
      final client = NasaPowerClient(
        MockClient((req) async {
          seen = req.url;
          return http.Response(_fixture, 200);
        }),
      );
      final hours = await client.fetchHourly(
        const GeoPoint(-16.52, -56.41),
        DateTime.utc(2026, 9, 10),
        DateTime.utc(2026, 9, 10),
      );
      expect(hours, hasLength(24));
      expect(seen.queryParameters['format'], 'JSON');
    });

    test('422, 429 and 5xx are retryable; other 4xx are not', () async {
      Future<PowerException> fail(int code) async {
        final client = NasaPowerClient(
          MockClient((_) async => http.Response('{}', code)),
        );
        try {
          await client.fetchHourly(
            const GeoPoint(0, 0),
            DateTime.utc(2026),
            DateTime.utc(2026),
          );
        } on PowerException catch (e) {
          return e;
        }
        throw StateError('expected failure');
      }

      expect((await fail(422)).retryable, isTrue);
      expect((await fail(429)).retryable, isTrue);
      expect((await fail(503)).retryable, isTrue);
      expect((await fail(400)).retryable, isFalse);
    });

    test('network errors are retryable', () async {
      final client = NasaPowerClient(
        MockClient((_) async => throw const SocketException('offline')),
      );
      await expectLater(
        client.fetchHourly(
          const GeoPoint(0, 0),
          DateTime.utc(2026),
          DateTime.utc(2026),
        ),
        throwsA(
          isA<PowerException>().having((e) => e.retryable, 'retryable', true),
        ),
      );
    });
  });
}
