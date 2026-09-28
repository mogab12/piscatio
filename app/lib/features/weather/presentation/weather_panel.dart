import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/background.dart';
import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/weather.dart';
import '../../../l10n/generated/app_localizations.dart';

/// A trip's weather: the values when ready, otherwise an honest status
/// (NASA POWER publishes 2–3 days late). Credits the source.
class WeatherPanel extends ConsumerWidget {
  const WeatherPanel({super.key, required this.tripId, this.onDark = false});

  final String tripId;

  /// Colors for the deep-water summary screen.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(tripWeatherProvider(tripId)).value;
    if (weather == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final muted = onDark ? PiscatioColors.reedOnDark : context.palette.muted;
    final ink = onDark ? PiscatioColors.foam : null;

    if (!weather.hasData) {
      final pending = weather.status == WeatherStatus.pending;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            pending ? Icons.cloud_sync_outlined : Icons.cloud_off_outlined,
            size: 20,
            color: muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pending ? l10n.weatherPending : l10n.weatherUnavailable,
              style: text.bodyMedium!.copyWith(color: muted),
            ),
          ),
        ],
      );
    }

    final f = context.formatters(ref);
    final items = <(IconData, String, String)>[
      (
        Icons.thermostat_rounded,
        f.temperature(weather.temperatureC!),
        l10n.weatherTemperature,
      ),
      if (weather.pressureHpa != null)
        (
          _trendIcon(weather.pressureTrend3hHpa),
          f.pressure(weather.pressureHpa!),
          _trendLabel(l10n, weather.pressureTrend3hHpa),
        ),
      if (weather.windSpeedKmh != null)
        (
          Icons.air_rounded,
          weather.windDirectionDeg == null
              ? f.windSpeed(weather.windSpeedKmh!)
              : '${f.windSpeed(weather.windSpeedKmh!)} ${f.compass(weather.windDirectionDeg!)}',
          l10n.weatherWind,
        ),
      if (weather.precipitationMm != null)
        (
          Icons.water_drop_outlined,
          f.precipitation(weather.precipitationMm!),
          l10n.weatherRain,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            for (final (icon, value, label) in items)
              Semantics(
                label: '$label: $value',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: muted),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: text.titleMedium!.copyWith(
                            fontFamily: PiscatioFonts.expanded,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        Text(
                          label,
                          style: text.labelSmall!.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.weatherSource,
          style: text.labelSmall!.copyWith(color: muted),
        ),
      ],
    );
  }

  static IconData _trendIcon(double? trend) => switch (trend) {
    null => Icons.speed_rounded,
    < -1 => Icons.south_east_rounded,
    > 1 => Icons.north_east_rounded,
    _ => Icons.east_rounded,
  };

  static String _trendLabel(AppLocalizations l10n, double? trend) =>
      switch (trend) {
        null => l10n.weatherPressure,
        < -1 => l10n.weatherPressureFalling,
        > 1 => l10n.weatherPressureRising,
        _ => l10n.weatherPressureSteady,
      };
}
