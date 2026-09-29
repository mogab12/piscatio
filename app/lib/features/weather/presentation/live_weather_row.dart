import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/theme/tokens.dart';
import '../application/live_weather.dart';

/// "Weather now" on the trip in progress: temperature, pressure, wind and
/// rain in the next hour, with MET Norway's credit. Takes no space when
/// there is nothing to show (signed out, no place, offline).
class LiveWeatherRow extends ConsumerWidget {
  const LiveWeatherRow({
    super.key,
    required this.tripId,
    this.padding = EdgeInsets.zero,
  });

  final String tripId;

  /// Around the row when it shows.
  final EdgeInsets padding;

  static IconData symbolIcon(String? symbol) => switch (symbol ?? '') {
    final s when s.contains('thunder') => Icons.thunderstorm_outlined,
    final s when s.contains('snow') || s.contains('sleet') =>
      Icons.ac_unit_rounded,
    final s when s.contains('rain') => Icons.grain_rounded,
    final s when s.contains('fog') => Icons.foggy,
    final s when s.startsWith('cloudy') => Icons.cloud_outlined,
    final s when s.contains('night') => Icons.nights_stay_outlined,
    final s when s.startsWith('clearsky') => Icons.wb_sunny_outlined,
    final s when s.isNotEmpty => Icons.wb_cloudy_outlined,
    _ => Icons.thermostat_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(liveWeatherProvider(tripId)).value;
    if (weather == null || weather.temperatureC == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final rain = weather.precipitationNextHourMm;
    final items = <(IconData, String, String)>[
      (
        symbolIcon(weather.symbol),
        f.temperature(weather.temperatureC!),
        l10n.weatherTemperature,
      ),
      if (weather.pressureHpa != null)
        (
          Icons.speed_rounded,
          f.pressure(weather.pressureHpa!),
          l10n.weatherPressure,
        ),
      if (weather.windSpeedKmh != null)
        (
          Icons.air_rounded,
          weather.windFromDeg == null
              ? f.windSpeed(weather.windSpeedKmh!)
              : '${f.windSpeed(weather.windSpeedKmh!)} '
                    '${f.compass(weather.windFromDeg!)}',
          l10n.weatherWind,
        ),
      if (rain != null && rain > 0)
        (
          Icons.water_drop_outlined,
          f.precipitation(rain),
          l10n.liveWeatherRainNextHour,
        ),
    ];
    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.liveWeatherTitle,
            style: text.titleSmall!.copyWith(color: muted),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            for (final (icon, value, label) in items)
              Semantics(
                label: '$label: $value',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: muted),
                    const SizedBox(width: 6),
                    Text(
                      value,
                      style: text.titleMedium!.copyWith(
                        fontFamily: PiscatioFonts.expanded,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.liveWeatherSource,
          style: text.labelSmall!.copyWith(color: muted),
        ),
      ],
    );
    return Padding(padding: padding, child: row);
  }
}
