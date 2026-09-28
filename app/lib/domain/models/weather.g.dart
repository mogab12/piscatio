// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HourlyWeather _$HourlyWeatherFromJson(Map<String, dynamic> json) =>
    _HourlyWeather(
      time: DateTime.parse(json['time'] as String),
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      pressureHpa: (json['pressureHpa'] as num?)?.toDouble(),
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble(),
      windDirectionDeg: (json['windDirectionDeg'] as num?)?.toDouble(),
      precipitationMm: (json['precipitationMm'] as num?)?.toDouble(),
      humidityPct: (json['humidityPct'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$HourlyWeatherToJson(_HourlyWeather instance) =>
    <String, dynamic>{
      'time': instance.time.toIso8601String(),
      'temperatureC': instance.temperatureC,
      'pressureHpa': instance.pressureHpa,
      'windSpeedKmh': instance.windSpeedKmh,
      'windDirectionDeg': instance.windDirectionDeg,
      'precipitationMm': instance.precipitationMm,
      'humidityPct': instance.humidityPct,
    };
