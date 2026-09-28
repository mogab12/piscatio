// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HourlyWeather {

/// Start of the hour, UTC.
 DateTime get time; double? get temperatureC;/// Reduced to sea level, which is what anglers compare.
 double? get pressureHpa; double? get windSpeedKmh;/// Direction the wind comes from, degrees clockwise from north.
 double? get windDirectionDeg; double? get precipitationMm; double? get humidityPct;
/// Create a copy of HourlyWeather
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HourlyWeatherCopyWith<HourlyWeather> get copyWith => _$HourlyWeatherCopyWithImpl<HourlyWeather>(this as HourlyWeather, _$identity);

  /// Serializes this HourlyWeather to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HourlyWeather;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HourlyWeather&&(identical(other.time, _this.time) || other.time == _this.time)&&(identical(other.temperatureC, _this.temperatureC) || other.temperatureC == _this.temperatureC)&&(identical(other.pressureHpa, _this.pressureHpa) || other.pressureHpa == _this.pressureHpa)&&(identical(other.windSpeedKmh, _this.windSpeedKmh) || other.windSpeedKmh == _this.windSpeedKmh)&&(identical(other.windDirectionDeg, _this.windDirectionDeg) || other.windDirectionDeg == _this.windDirectionDeg)&&(identical(other.precipitationMm, _this.precipitationMm) || other.precipitationMm == _this.precipitationMm)&&(identical(other.humidityPct, _this.humidityPct) || other.humidityPct == _this.humidityPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HourlyWeather;
  return Object.hash(runtimeType,_this.time,_this.temperatureC,_this.pressureHpa,_this.windSpeedKmh,_this.windDirectionDeg,_this.precipitationMm,_this.humidityPct);
}

@override
String toString() {
  final _this = this as HourlyWeather;
  return 'HourlyWeather(time: ${_this.time}, temperatureC: ${_this.temperatureC}, pressureHpa: ${_this.pressureHpa}, windSpeedKmh: ${_this.windSpeedKmh}, windDirectionDeg: ${_this.windDirectionDeg}, precipitationMm: ${_this.precipitationMm}, humidityPct: ${_this.humidityPct})';
}


}

/// @nodoc
abstract mixin class $HourlyWeatherCopyWith<$Res>  {
  factory $HourlyWeatherCopyWith(HourlyWeather value, $Res Function(HourlyWeather) _then) = _$HourlyWeatherCopyWithImpl;
@useResult
$Res call({
 DateTime time, double? temperatureC, double? pressureHpa, double? windSpeedKmh, double? windDirectionDeg, double? precipitationMm, double? humidityPct
});




}
/// @nodoc
class _$HourlyWeatherCopyWithImpl<$Res>
    implements $HourlyWeatherCopyWith<$Res> {
  _$HourlyWeatherCopyWithImpl(this._self, this._then);

  final HourlyWeather _self;
  final $Res Function(HourlyWeather) _then;

/// Create a copy of HourlyWeather
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? temperatureC = freezed,Object? pressureHpa = freezed,Object? windSpeedKmh = freezed,Object? windDirectionDeg = freezed,Object? precipitationMm = freezed,Object? humidityPct = freezed,}) {
  return _then(HourlyWeather(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,temperatureC: freezed == temperatureC ? _self.temperatureC : temperatureC // ignore: cast_nullable_to_non_nullable
as double?,pressureHpa: freezed == pressureHpa ? _self.pressureHpa : pressureHpa // ignore: cast_nullable_to_non_nullable
as double?,windSpeedKmh: freezed == windSpeedKmh ? _self.windSpeedKmh : windSpeedKmh // ignore: cast_nullable_to_non_nullable
as double?,windDirectionDeg: freezed == windDirectionDeg ? _self.windDirectionDeg : windDirectionDeg // ignore: cast_nullable_to_non_nullable
as double?,precipitationMm: freezed == precipitationMm ? _self.precipitationMm : precipitationMm // ignore: cast_nullable_to_non_nullable
as double?,humidityPct: freezed == humidityPct ? _self.humidityPct : humidityPct // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [HourlyWeather].
extension HourlyWeatherPatterns on HourlyWeather {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HourlyWeather value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HourlyWeather() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HourlyWeather value)  $default,){
final _that = this;
switch (_that) {
case _HourlyWeather():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HourlyWeather value)?  $default,){
final _that = this;
switch (_that) {
case _HourlyWeather() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime time,  double? temperatureC,  double? pressureHpa,  double? windSpeedKmh,  double? windDirectionDeg,  double? precipitationMm,  double? humidityPct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HourlyWeather() when $default != null:
return $default(_that.time,_that.temperatureC,_that.pressureHpa,_that.windSpeedKmh,_that.windDirectionDeg,_that.precipitationMm,_that.humidityPct);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime time,  double? temperatureC,  double? pressureHpa,  double? windSpeedKmh,  double? windDirectionDeg,  double? precipitationMm,  double? humidityPct)  $default,) {final _that = this;
switch (_that) {
case _HourlyWeather():
return $default(_that.time,_that.temperatureC,_that.pressureHpa,_that.windSpeedKmh,_that.windDirectionDeg,_that.precipitationMm,_that.humidityPct);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime time,  double? temperatureC,  double? pressureHpa,  double? windSpeedKmh,  double? windDirectionDeg,  double? precipitationMm,  double? humidityPct)?  $default,) {final _that = this;
switch (_that) {
case _HourlyWeather() when $default != null:
return $default(_that.time,_that.temperatureC,_that.pressureHpa,_that.windSpeedKmh,_that.windDirectionDeg,_that.precipitationMm,_that.humidityPct);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HourlyWeather implements HourlyWeather {
  const _HourlyWeather({required this.time, this.temperatureC, this.pressureHpa, this.windSpeedKmh, this.windDirectionDeg, this.precipitationMm, this.humidityPct});
  factory _HourlyWeather.fromJson(Map<String, dynamic> json) => _$HourlyWeatherFromJson(json);

/// Start of the hour, UTC.
@override final  DateTime time;
@override final  double? temperatureC;
/// Reduced to sea level, which is what anglers compare.
@override final  double? pressureHpa;
@override final  double? windSpeedKmh;
/// Direction the wind comes from, degrees clockwise from north.
@override final  double? windDirectionDeg;
@override final  double? precipitationMm;
@override final  double? humidityPct;

/// Create a copy of HourlyWeather
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HourlyWeatherCopyWith<_HourlyWeather> get copyWith => __$HourlyWeatherCopyWithImpl<_HourlyWeather>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HourlyWeatherToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HourlyWeather&&(identical(other.time, time) || other.time == time)&&(identical(other.temperatureC, temperatureC) || other.temperatureC == temperatureC)&&(identical(other.pressureHpa, pressureHpa) || other.pressureHpa == pressureHpa)&&(identical(other.windSpeedKmh, windSpeedKmh) || other.windSpeedKmh == windSpeedKmh)&&(identical(other.windDirectionDeg, windDirectionDeg) || other.windDirectionDeg == windDirectionDeg)&&(identical(other.precipitationMm, precipitationMm) || other.precipitationMm == precipitationMm)&&(identical(other.humidityPct, humidityPct) || other.humidityPct == humidityPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,time,temperatureC,pressureHpa,windSpeedKmh,windDirectionDeg,precipitationMm,humidityPct);
}

@override
String toString() {
    return 'HourlyWeather(time: $time, temperatureC: $temperatureC, pressureHpa: $pressureHpa, windSpeedKmh: $windSpeedKmh, windDirectionDeg: $windDirectionDeg, precipitationMm: $precipitationMm, humidityPct: $humidityPct)';
}


}

/// @nodoc
abstract mixin class _$HourlyWeatherCopyWith<$Res> implements $HourlyWeatherCopyWith<$Res> {
  factory _$HourlyWeatherCopyWith(_HourlyWeather value, $Res Function(_HourlyWeather) _then) = __$HourlyWeatherCopyWithImpl;
@override @useResult
$Res call({
 DateTime time, double? temperatureC, double? pressureHpa, double? windSpeedKmh, double? windDirectionDeg, double? precipitationMm, double? humidityPct
});




}
/// @nodoc
class __$HourlyWeatherCopyWithImpl<$Res>
    implements _$HourlyWeatherCopyWith<$Res> {
  __$HourlyWeatherCopyWithImpl(this._self, this._then);

  final _HourlyWeather _self;
  final $Res Function(_HourlyWeather) _then;

/// Create a copy of HourlyWeather
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? temperatureC = freezed,Object? pressureHpa = freezed,Object? windSpeedKmh = freezed,Object? windDirectionDeg = freezed,Object? precipitationMm = freezed,Object? humidityPct = freezed,}) {
  return _then(_HourlyWeather(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,temperatureC: freezed == temperatureC ? _self.temperatureC : temperatureC // ignore: cast_nullable_to_non_nullable
as double?,pressureHpa: freezed == pressureHpa ? _self.pressureHpa : pressureHpa // ignore: cast_nullable_to_non_nullable
as double?,windSpeedKmh: freezed == windSpeedKmh ? _self.windSpeedKmh : windSpeedKmh // ignore: cast_nullable_to_non_nullable
as double?,windDirectionDeg: freezed == windDirectionDeg ? _self.windDirectionDeg : windDirectionDeg // ignore: cast_nullable_to_non_nullable
as double?,precipitationMm: freezed == precipitationMm ? _self.precipitationMm : precipitationMm // ignore: cast_nullable_to_non_nullable
as double?,humidityPct: freezed == humidityPct ? _self.humidityPct : humidityPct // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$TripWeather {

 String get tripId; WeatherStatus get status; String? get source; DateTime? get fetchedAt; double? get temperatureC; double? get pressureHpa;/// Pressure change over the 3 hours before the trip started (hPa).
/// Falling pressure is the classic "fish bite before the front" signal.
 double? get pressureTrend3hHpa; double? get windSpeedKmh; double? get windDirectionDeg;/// Total rain during the trip.
 double? get precipitationMm; double? get humidityPct; List<HourlyWeather> get hourly;
/// Create a copy of TripWeather
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripWeatherCopyWith<TripWeather> get copyWith => _$TripWeatherCopyWithImpl<TripWeather>(this as TripWeather, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TripWeather;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripWeather&&(identical(other.tripId, _this.tripId) || other.tripId == _this.tripId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.fetchedAt, _this.fetchedAt) || other.fetchedAt == _this.fetchedAt)&&(identical(other.temperatureC, _this.temperatureC) || other.temperatureC == _this.temperatureC)&&(identical(other.pressureHpa, _this.pressureHpa) || other.pressureHpa == _this.pressureHpa)&&(identical(other.pressureTrend3hHpa, _this.pressureTrend3hHpa) || other.pressureTrend3hHpa == _this.pressureTrend3hHpa)&&(identical(other.windSpeedKmh, _this.windSpeedKmh) || other.windSpeedKmh == _this.windSpeedKmh)&&(identical(other.windDirectionDeg, _this.windDirectionDeg) || other.windDirectionDeg == _this.windDirectionDeg)&&(identical(other.precipitationMm, _this.precipitationMm) || other.precipitationMm == _this.precipitationMm)&&(identical(other.humidityPct, _this.humidityPct) || other.humidityPct == _this.humidityPct)&&const DeepCollectionEquality().equals(other.hourly, _this.hourly));
}


@override
int get hashCode {
  final _this = this as TripWeather;
  return Object.hash(runtimeType,_this.tripId,_this.status,_this.source,_this.fetchedAt,_this.temperatureC,_this.pressureHpa,_this.pressureTrend3hHpa,_this.windSpeedKmh,_this.windDirectionDeg,_this.precipitationMm,_this.humidityPct,const DeepCollectionEquality().hash(_this.hourly));
}

@override
String toString() {
  final _this = this as TripWeather;
  return 'TripWeather(tripId: ${_this.tripId}, status: ${_this.status}, source: ${_this.source}, fetchedAt: ${_this.fetchedAt}, temperatureC: ${_this.temperatureC}, pressureHpa: ${_this.pressureHpa}, pressureTrend3hHpa: ${_this.pressureTrend3hHpa}, windSpeedKmh: ${_this.windSpeedKmh}, windDirectionDeg: ${_this.windDirectionDeg}, precipitationMm: ${_this.precipitationMm}, humidityPct: ${_this.humidityPct}, hourly: ${_this.hourly})';
}


}

/// @nodoc
abstract mixin class $TripWeatherCopyWith<$Res>  {
  factory $TripWeatherCopyWith(TripWeather value, $Res Function(TripWeather) _then) = _$TripWeatherCopyWithImpl;
@useResult
$Res call({
 String tripId, WeatherStatus status, String? source, DateTime? fetchedAt, double? temperatureC, double? pressureHpa, double? pressureTrend3hHpa, double? windSpeedKmh, double? windDirectionDeg, double? precipitationMm, double? humidityPct, List<HourlyWeather> hourly
});




}
/// @nodoc
class _$TripWeatherCopyWithImpl<$Res>
    implements $TripWeatherCopyWith<$Res> {
  _$TripWeatherCopyWithImpl(this._self, this._then);

  final TripWeather _self;
  final $Res Function(TripWeather) _then;

/// Create a copy of TripWeather
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tripId = null,Object? status = null,Object? source = freezed,Object? fetchedAt = freezed,Object? temperatureC = freezed,Object? pressureHpa = freezed,Object? pressureTrend3hHpa = freezed,Object? windSpeedKmh = freezed,Object? windDirectionDeg = freezed,Object? precipitationMm = freezed,Object? humidityPct = freezed,Object? hourly = null,}) {
  return _then(TripWeather(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WeatherStatus,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,fetchedAt: freezed == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,temperatureC: freezed == temperatureC ? _self.temperatureC : temperatureC // ignore: cast_nullable_to_non_nullable
as double?,pressureHpa: freezed == pressureHpa ? _self.pressureHpa : pressureHpa // ignore: cast_nullable_to_non_nullable
as double?,pressureTrend3hHpa: freezed == pressureTrend3hHpa ? _self.pressureTrend3hHpa : pressureTrend3hHpa // ignore: cast_nullable_to_non_nullable
as double?,windSpeedKmh: freezed == windSpeedKmh ? _self.windSpeedKmh : windSpeedKmh // ignore: cast_nullable_to_non_nullable
as double?,windDirectionDeg: freezed == windDirectionDeg ? _self.windDirectionDeg : windDirectionDeg // ignore: cast_nullable_to_non_nullable
as double?,precipitationMm: freezed == precipitationMm ? _self.precipitationMm : precipitationMm // ignore: cast_nullable_to_non_nullable
as double?,humidityPct: freezed == humidityPct ? _self.humidityPct : humidityPct // ignore: cast_nullable_to_non_nullable
as double?,hourly: null == hourly ? _self.hourly : hourly // ignore: cast_nullable_to_non_nullable
as List<HourlyWeather>,
  ));
}

}


/// Adds pattern-matching-related methods to [TripWeather].
extension TripWeatherPatterns on TripWeather {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripWeather value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripWeather() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripWeather value)  $default,){
final _that = this;
switch (_that) {
case _TripWeather():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripWeather value)?  $default,){
final _that = this;
switch (_that) {
case _TripWeather() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tripId,  WeatherStatus status,  String? source,  DateTime? fetchedAt,  double? temperatureC,  double? pressureHpa,  double? pressureTrend3hHpa,  double? windSpeedKmh,  double? windDirectionDeg,  double? precipitationMm,  double? humidityPct,  List<HourlyWeather> hourly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripWeather() when $default != null:
return $default(_that.tripId,_that.status,_that.source,_that.fetchedAt,_that.temperatureC,_that.pressureHpa,_that.pressureTrend3hHpa,_that.windSpeedKmh,_that.windDirectionDeg,_that.precipitationMm,_that.humidityPct,_that.hourly);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tripId,  WeatherStatus status,  String? source,  DateTime? fetchedAt,  double? temperatureC,  double? pressureHpa,  double? pressureTrend3hHpa,  double? windSpeedKmh,  double? windDirectionDeg,  double? precipitationMm,  double? humidityPct,  List<HourlyWeather> hourly)  $default,) {final _that = this;
switch (_that) {
case _TripWeather():
return $default(_that.tripId,_that.status,_that.source,_that.fetchedAt,_that.temperatureC,_that.pressureHpa,_that.pressureTrend3hHpa,_that.windSpeedKmh,_that.windDirectionDeg,_that.precipitationMm,_that.humidityPct,_that.hourly);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tripId,  WeatherStatus status,  String? source,  DateTime? fetchedAt,  double? temperatureC,  double? pressureHpa,  double? pressureTrend3hHpa,  double? windSpeedKmh,  double? windDirectionDeg,  double? precipitationMm,  double? humidityPct,  List<HourlyWeather> hourly)?  $default,) {final _that = this;
switch (_that) {
case _TripWeather() when $default != null:
return $default(_that.tripId,_that.status,_that.source,_that.fetchedAt,_that.temperatureC,_that.pressureHpa,_that.pressureTrend3hHpa,_that.windSpeedKmh,_that.windDirectionDeg,_that.precipitationMm,_that.humidityPct,_that.hourly);case _:
  return null;

}
}

}

/// @nodoc


class _TripWeather extends TripWeather {
  const _TripWeather({required this.tripId, required this.status, this.source, this.fetchedAt, this.temperatureC, this.pressureHpa, this.pressureTrend3hHpa, this.windSpeedKmh, this.windDirectionDeg, this.precipitationMm, this.humidityPct,  List<HourlyWeather> hourly = const <HourlyWeather>[]}): _hourly = hourly,super._();
  

@override final  String tripId;
@override final  WeatherStatus status;
@override final  String? source;
@override final  DateTime? fetchedAt;
@override final  double? temperatureC;
@override final  double? pressureHpa;
/// Pressure change over the 3 hours before the trip started (hPa).
/// Falling pressure is the classic "fish bite before the front" signal.
@override final  double? pressureTrend3hHpa;
@override final  double? windSpeedKmh;
@override final  double? windDirectionDeg;
/// Total rain during the trip.
@override final  double? precipitationMm;
@override final  double? humidityPct;
 final  List<HourlyWeather> _hourly;
@override@JsonKey() List<HourlyWeather> get hourly {
  if (_hourly is EqualUnmodifiableListView) return _hourly;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hourly);
}


/// Create a copy of TripWeather
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripWeatherCopyWith<_TripWeather> get copyWith => __$TripWeatherCopyWithImpl<_TripWeather>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripWeather&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.status, status) || other.status == status)&&(identical(other.source, source) || other.source == source)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.temperatureC, temperatureC) || other.temperatureC == temperatureC)&&(identical(other.pressureHpa, pressureHpa) || other.pressureHpa == pressureHpa)&&(identical(other.pressureTrend3hHpa, pressureTrend3hHpa) || other.pressureTrend3hHpa == pressureTrend3hHpa)&&(identical(other.windSpeedKmh, windSpeedKmh) || other.windSpeedKmh == windSpeedKmh)&&(identical(other.windDirectionDeg, windDirectionDeg) || other.windDirectionDeg == windDirectionDeg)&&(identical(other.precipitationMm, precipitationMm) || other.precipitationMm == precipitationMm)&&(identical(other.humidityPct, humidityPct) || other.humidityPct == humidityPct)&&const DeepCollectionEquality().equals(other.hourly, _hourly));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tripId,status,source,fetchedAt,temperatureC,pressureHpa,pressureTrend3hHpa,windSpeedKmh,windDirectionDeg,precipitationMm,humidityPct,const DeepCollectionEquality().hash(_hourly));
}

@override
String toString() {
    return 'TripWeather(tripId: $tripId, status: $status, source: $source, fetchedAt: $fetchedAt, temperatureC: $temperatureC, pressureHpa: $pressureHpa, pressureTrend3hHpa: $pressureTrend3hHpa, windSpeedKmh: $windSpeedKmh, windDirectionDeg: $windDirectionDeg, precipitationMm: $precipitationMm, humidityPct: $humidityPct, hourly: $hourly)';
}


}

/// @nodoc
abstract mixin class _$TripWeatherCopyWith<$Res> implements $TripWeatherCopyWith<$Res> {
  factory _$TripWeatherCopyWith(_TripWeather value, $Res Function(_TripWeather) _then) = __$TripWeatherCopyWithImpl;
@override @useResult
$Res call({
 String tripId, WeatherStatus status, String? source, DateTime? fetchedAt, double? temperatureC, double? pressureHpa, double? pressureTrend3hHpa, double? windSpeedKmh, double? windDirectionDeg, double? precipitationMm, double? humidityPct, List<HourlyWeather> hourly
});




}
/// @nodoc
class __$TripWeatherCopyWithImpl<$Res>
    implements _$TripWeatherCopyWith<$Res> {
  __$TripWeatherCopyWithImpl(this._self, this._then);

  final _TripWeather _self;
  final $Res Function(_TripWeather) _then;

/// Create a copy of TripWeather
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tripId = null,Object? status = null,Object? source = freezed,Object? fetchedAt = freezed,Object? temperatureC = freezed,Object? pressureHpa = freezed,Object? pressureTrend3hHpa = freezed,Object? windSpeedKmh = freezed,Object? windDirectionDeg = freezed,Object? precipitationMm = freezed,Object? humidityPct = freezed,Object? hourly = null,}) {
  return _then(_TripWeather(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WeatherStatus,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,fetchedAt: freezed == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,temperatureC: freezed == temperatureC ? _self.temperatureC : temperatureC // ignore: cast_nullable_to_non_nullable
as double?,pressureHpa: freezed == pressureHpa ? _self.pressureHpa : pressureHpa // ignore: cast_nullable_to_non_nullable
as double?,pressureTrend3hHpa: freezed == pressureTrend3hHpa ? _self.pressureTrend3hHpa : pressureTrend3hHpa // ignore: cast_nullable_to_non_nullable
as double?,windSpeedKmh: freezed == windSpeedKmh ? _self.windSpeedKmh : windSpeedKmh // ignore: cast_nullable_to_non_nullable
as double?,windDirectionDeg: freezed == windDirectionDeg ? _self.windDirectionDeg : windDirectionDeg // ignore: cast_nullable_to_non_nullable
as double?,precipitationMm: freezed == precipitationMm ? _self.precipitationMm : precipitationMm // ignore: cast_nullable_to_non_nullable
as double?,humidityPct: freezed == humidityPct ? _self.humidityPct : humidityPct // ignore: cast_nullable_to_non_nullable
as double?,hourly: null == hourly ? _self._hourly : hourly // ignore: cast_nullable_to_non_nullable
as List<HourlyWeather>,
  ));
}


}

// dart format on
