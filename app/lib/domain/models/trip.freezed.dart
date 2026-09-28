// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Trip {

 String get id;/// UTC.
 DateTime get startedAt;/// UTC. Null while the trip is in progress.
 DateTime? get endedAt;/// IANA time zone where the trip happened, for display.
 String get timezone; GeoPoint? get location; double? get locationAccuracyMeters; String? get locationName;/// City/state level description, the most a card may show for
/// approximate privacy.
 String? get locationRegion; PrivacyLevel get privacyLevel; MoonPhase get moonPhase; double get moonIllumination; String? get notes; bool get isRetroactive; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCopyWith<Trip> get copyWith => _$TripCopyWithImpl<Trip>(this as Trip, _$identity);

  /// Serializes this Trip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Trip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trip&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.timezone, _this.timezone) || other.timezone == _this.timezone)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.locationAccuracyMeters, _this.locationAccuracyMeters) || other.locationAccuracyMeters == _this.locationAccuracyMeters)&&(identical(other.locationName, _this.locationName) || other.locationName == _this.locationName)&&(identical(other.locationRegion, _this.locationRegion) || other.locationRegion == _this.locationRegion)&&(identical(other.privacyLevel, _this.privacyLevel) || other.privacyLevel == _this.privacyLevel)&&(identical(other.moonPhase, _this.moonPhase) || other.moonPhase == _this.moonPhase)&&(identical(other.moonIllumination, _this.moonIllumination) || other.moonIllumination == _this.moonIllumination)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.isRetroactive, _this.isRetroactive) || other.isRetroactive == _this.isRetroactive)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Trip;
  return Object.hash(runtimeType,_this.id,_this.startedAt,_this.endedAt,_this.timezone,_this.location,_this.locationAccuracyMeters,_this.locationName,_this.locationRegion,_this.privacyLevel,_this.moonPhase,_this.moonIllumination,_this.notes,_this.isRetroactive,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Trip;
  return 'Trip(id: ${_this.id}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, timezone: ${_this.timezone}, location: ${_this.location}, locationAccuracyMeters: ${_this.locationAccuracyMeters}, locationName: ${_this.locationName}, locationRegion: ${_this.locationRegion}, privacyLevel: ${_this.privacyLevel}, moonPhase: ${_this.moonPhase}, moonIllumination: ${_this.moonIllumination}, notes: ${_this.notes}, isRetroactive: ${_this.isRetroactive}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $TripCopyWith<$Res>  {
  factory $TripCopyWith(Trip value, $Res Function(Trip) _then) = _$TripCopyWithImpl;
@useResult
$Res call({
 String id, DateTime startedAt, DateTime? endedAt, String timezone, GeoPoint? location, double? locationAccuracyMeters, String? locationName, String? locationRegion, PrivacyLevel privacyLevel, MoonPhase moonPhase, double moonIllumination, String? notes, bool isRetroactive, DateTime createdAt, DateTime updatedAt
});


$GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class _$TripCopyWithImpl<$Res>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._self, this._then);

  final Trip _self;
  final $Res Function(Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startedAt = null,Object? endedAt = freezed,Object? timezone = null,Object? location = freezed,Object? locationAccuracyMeters = freezed,Object? locationName = freezed,Object? locationRegion = freezed,Object? privacyLevel = null,Object? moonPhase = null,Object? moonIllumination = null,Object? notes = freezed,Object? isRetroactive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,locationAccuracyMeters: freezed == locationAccuracyMeters ? _self.locationAccuracyMeters : locationAccuracyMeters // ignore: cast_nullable_to_non_nullable
as double?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,locationRegion: freezed == locationRegion ? _self.locationRegion : locationRegion // ignore: cast_nullable_to_non_nullable
as String?,privacyLevel: null == privacyLevel ? _self.privacyLevel : privacyLevel // ignore: cast_nullable_to_non_nullable
as PrivacyLevel,moonPhase: null == moonPhase ? _self.moonPhase : moonPhase // ignore: cast_nullable_to_non_nullable
as MoonPhase,moonIllumination: null == moonIllumination ? _self.moonIllumination : moonIllumination // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isRetroactive: null == isRetroactive ? _self.isRetroactive : isRetroactive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [Trip].
extension TripPatterns on Trip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trip value)  $default,){
final _that = this;
switch (_that) {
case _Trip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trip value)?  $default,){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime startedAt,  DateTime? endedAt,  String timezone,  GeoPoint? location,  double? locationAccuracyMeters,  String? locationName,  String? locationRegion,  PrivacyLevel privacyLevel,  MoonPhase moonPhase,  double moonIllumination,  String? notes,  bool isRetroactive,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.startedAt,_that.endedAt,_that.timezone,_that.location,_that.locationAccuracyMeters,_that.locationName,_that.locationRegion,_that.privacyLevel,_that.moonPhase,_that.moonIllumination,_that.notes,_that.isRetroactive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime startedAt,  DateTime? endedAt,  String timezone,  GeoPoint? location,  double? locationAccuracyMeters,  String? locationName,  String? locationRegion,  PrivacyLevel privacyLevel,  MoonPhase moonPhase,  double moonIllumination,  String? notes,  bool isRetroactive,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Trip():
return $default(_that.id,_that.startedAt,_that.endedAt,_that.timezone,_that.location,_that.locationAccuracyMeters,_that.locationName,_that.locationRegion,_that.privacyLevel,_that.moonPhase,_that.moonIllumination,_that.notes,_that.isRetroactive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime startedAt,  DateTime? endedAt,  String timezone,  GeoPoint? location,  double? locationAccuracyMeters,  String? locationName,  String? locationRegion,  PrivacyLevel privacyLevel,  MoonPhase moonPhase,  double moonIllumination,  String? notes,  bool isRetroactive,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.startedAt,_that.endedAt,_that.timezone,_that.location,_that.locationAccuracyMeters,_that.locationName,_that.locationRegion,_that.privacyLevel,_that.moonPhase,_that.moonIllumination,_that.notes,_that.isRetroactive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trip extends Trip {
  const _Trip({required this.id, required this.startedAt, this.endedAt, required this.timezone, this.location, this.locationAccuracyMeters, this.locationName, this.locationRegion, required this.privacyLevel, required this.moonPhase, required this.moonIllumination, this.notes, this.isRetroactive = false, required this.createdAt, required this.updatedAt}): super._();
  factory _Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

@override final  String id;
/// UTC.
@override final  DateTime startedAt;
/// UTC. Null while the trip is in progress.
@override final  DateTime? endedAt;
/// IANA time zone where the trip happened, for display.
@override final  String timezone;
@override final  GeoPoint? location;
@override final  double? locationAccuracyMeters;
@override final  String? locationName;
/// City/state level description, the most a card may show for
/// approximate privacy.
@override final  String? locationRegion;
@override final  PrivacyLevel privacyLevel;
@override final  MoonPhase moonPhase;
@override final  double moonIllumination;
@override final  String? notes;
@override@JsonKey() final  bool isRetroactive;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCopyWith<_Trip> get copyWith => __$TripCopyWithImpl<_Trip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.location, location) || other.location == location)&&(identical(other.locationAccuracyMeters, locationAccuracyMeters) || other.locationAccuracyMeters == locationAccuracyMeters)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.locationRegion, locationRegion) || other.locationRegion == locationRegion)&&(identical(other.privacyLevel, privacyLevel) || other.privacyLevel == privacyLevel)&&(identical(other.moonPhase, moonPhase) || other.moonPhase == moonPhase)&&(identical(other.moonIllumination, moonIllumination) || other.moonIllumination == moonIllumination)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isRetroactive, isRetroactive) || other.isRetroactive == isRetroactive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,startedAt,endedAt,timezone,location,locationAccuracyMeters,locationName,locationRegion,privacyLevel,moonPhase,moonIllumination,notes,isRetroactive,createdAt,updatedAt);
}

@override
String toString() {
    return 'Trip(id: $id, startedAt: $startedAt, endedAt: $endedAt, timezone: $timezone, location: $location, locationAccuracyMeters: $locationAccuracyMeters, locationName: $locationName, locationRegion: $locationRegion, privacyLevel: $privacyLevel, moonPhase: $moonPhase, moonIllumination: $moonIllumination, notes: $notes, isRetroactive: $isRetroactive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TripCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$TripCopyWith(_Trip value, $Res Function(_Trip) _then) = __$TripCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime startedAt, DateTime? endedAt, String timezone, GeoPoint? location, double? locationAccuracyMeters, String? locationName, String? locationRegion, PrivacyLevel privacyLevel, MoonPhase moonPhase, double moonIllumination, String? notes, bool isRetroactive, DateTime createdAt, DateTime updatedAt
});


@override $GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class __$TripCopyWithImpl<$Res>
    implements _$TripCopyWith<$Res> {
  __$TripCopyWithImpl(this._self, this._then);

  final _Trip _self;
  final $Res Function(_Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startedAt = null,Object? endedAt = freezed,Object? timezone = null,Object? location = freezed,Object? locationAccuracyMeters = freezed,Object? locationName = freezed,Object? locationRegion = freezed,Object? privacyLevel = null,Object? moonPhase = null,Object? moonIllumination = null,Object? notes = freezed,Object? isRetroactive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,locationAccuracyMeters: freezed == locationAccuracyMeters ? _self.locationAccuracyMeters : locationAccuracyMeters // ignore: cast_nullable_to_non_nullable
as double?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,locationRegion: freezed == locationRegion ? _self.locationRegion : locationRegion // ignore: cast_nullable_to_non_nullable
as String?,privacyLevel: null == privacyLevel ? _self.privacyLevel : privacyLevel // ignore: cast_nullable_to_non_nullable
as PrivacyLevel,moonPhase: null == moonPhase ? _self.moonPhase : moonPhase // ignore: cast_nullable_to_non_nullable
as MoonPhase,moonIllumination: null == moonIllumination ? _self.moonIllumination : moonIllumination // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isRetroactive: null == isRetroactive ? _self.isRetroactive : isRetroactive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

/// @nodoc
mixin _$TripOverview {

 Trip get trip; int get catchCount; int get speciesCount; int? get maxWeightGrams; int? get maxLengthMillimeters;/// Relative path of a photo to illustrate the trip, if any.
 String? get coverPhotoPath;
/// Create a copy of TripOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripOverviewCopyWith<TripOverview> get copyWith => _$TripOverviewCopyWithImpl<TripOverview>(this as TripOverview, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TripOverview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripOverview&&(identical(other.trip, _this.trip) || other.trip == _this.trip)&&(identical(other.catchCount, _this.catchCount) || other.catchCount == _this.catchCount)&&(identical(other.speciesCount, _this.speciesCount) || other.speciesCount == _this.speciesCount)&&(identical(other.maxWeightGrams, _this.maxWeightGrams) || other.maxWeightGrams == _this.maxWeightGrams)&&(identical(other.maxLengthMillimeters, _this.maxLengthMillimeters) || other.maxLengthMillimeters == _this.maxLengthMillimeters)&&(identical(other.coverPhotoPath, _this.coverPhotoPath) || other.coverPhotoPath == _this.coverPhotoPath));
}


@override
int get hashCode {
  final _this = this as TripOverview;
  return Object.hash(runtimeType,_this.trip,_this.catchCount,_this.speciesCount,_this.maxWeightGrams,_this.maxLengthMillimeters,_this.coverPhotoPath);
}

@override
String toString() {
  final _this = this as TripOverview;
  return 'TripOverview(trip: ${_this.trip}, catchCount: ${_this.catchCount}, speciesCount: ${_this.speciesCount}, maxWeightGrams: ${_this.maxWeightGrams}, maxLengthMillimeters: ${_this.maxLengthMillimeters}, coverPhotoPath: ${_this.coverPhotoPath})';
}


}

/// @nodoc
abstract mixin class $TripOverviewCopyWith<$Res>  {
  factory $TripOverviewCopyWith(TripOverview value, $Res Function(TripOverview) _then) = _$TripOverviewCopyWithImpl;
@useResult
$Res call({
 Trip trip, int catchCount, int speciesCount, int? maxWeightGrams, int? maxLengthMillimeters, String? coverPhotoPath
});


$TripCopyWith<$Res> get trip;

}
/// @nodoc
class _$TripOverviewCopyWithImpl<$Res>
    implements $TripOverviewCopyWith<$Res> {
  _$TripOverviewCopyWithImpl(this._self, this._then);

  final TripOverview _self;
  final $Res Function(TripOverview) _then;

/// Create a copy of TripOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trip = null,Object? catchCount = null,Object? speciesCount = null,Object? maxWeightGrams = freezed,Object? maxLengthMillimeters = freezed,Object? coverPhotoPath = freezed,}) {
  return _then(TripOverview(
trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip,catchCount: null == catchCount ? _self.catchCount : catchCount // ignore: cast_nullable_to_non_nullable
as int,speciesCount: null == speciesCount ? _self.speciesCount : speciesCount // ignore: cast_nullable_to_non_nullable
as int,maxWeightGrams: freezed == maxWeightGrams ? _self.maxWeightGrams : maxWeightGrams // ignore: cast_nullable_to_non_nullable
as int?,maxLengthMillimeters: freezed == maxLengthMillimeters ? _self.maxLengthMillimeters : maxLengthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,coverPhotoPath: freezed == coverPhotoPath ? _self.coverPhotoPath : coverPhotoPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of TripOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res> get trip {
  
  return $TripCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripOverview].
extension TripOverviewPatterns on TripOverview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripOverview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripOverview value)  $default,){
final _that = this;
switch (_that) {
case _TripOverview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripOverview value)?  $default,){
final _that = this;
switch (_that) {
case _TripOverview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Trip trip,  int catchCount,  int speciesCount,  int? maxWeightGrams,  int? maxLengthMillimeters,  String? coverPhotoPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripOverview() when $default != null:
return $default(_that.trip,_that.catchCount,_that.speciesCount,_that.maxWeightGrams,_that.maxLengthMillimeters,_that.coverPhotoPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Trip trip,  int catchCount,  int speciesCount,  int? maxWeightGrams,  int? maxLengthMillimeters,  String? coverPhotoPath)  $default,) {final _that = this;
switch (_that) {
case _TripOverview():
return $default(_that.trip,_that.catchCount,_that.speciesCount,_that.maxWeightGrams,_that.maxLengthMillimeters,_that.coverPhotoPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Trip trip,  int catchCount,  int speciesCount,  int? maxWeightGrams,  int? maxLengthMillimeters,  String? coverPhotoPath)?  $default,) {final _that = this;
switch (_that) {
case _TripOverview() when $default != null:
return $default(_that.trip,_that.catchCount,_that.speciesCount,_that.maxWeightGrams,_that.maxLengthMillimeters,_that.coverPhotoPath);case _:
  return null;

}
}

}

/// @nodoc


class _TripOverview implements TripOverview {
  const _TripOverview({required this.trip, required this.catchCount, required this.speciesCount, this.maxWeightGrams, this.maxLengthMillimeters, this.coverPhotoPath});
  

@override final  Trip trip;
@override final  int catchCount;
@override final  int speciesCount;
@override final  int? maxWeightGrams;
@override final  int? maxLengthMillimeters;
/// Relative path of a photo to illustrate the trip, if any.
@override final  String? coverPhotoPath;

/// Create a copy of TripOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripOverviewCopyWith<_TripOverview> get copyWith => __$TripOverviewCopyWithImpl<_TripOverview>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripOverview&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.catchCount, catchCount) || other.catchCount == catchCount)&&(identical(other.speciesCount, speciesCount) || other.speciesCount == speciesCount)&&(identical(other.maxWeightGrams, maxWeightGrams) || other.maxWeightGrams == maxWeightGrams)&&(identical(other.maxLengthMillimeters, maxLengthMillimeters) || other.maxLengthMillimeters == maxLengthMillimeters)&&(identical(other.coverPhotoPath, coverPhotoPath) || other.coverPhotoPath == coverPhotoPath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,trip,catchCount,speciesCount,maxWeightGrams,maxLengthMillimeters,coverPhotoPath);
}

@override
String toString() {
    return 'TripOverview(trip: $trip, catchCount: $catchCount, speciesCount: $speciesCount, maxWeightGrams: $maxWeightGrams, maxLengthMillimeters: $maxLengthMillimeters, coverPhotoPath: $coverPhotoPath)';
}


}

/// @nodoc
abstract mixin class _$TripOverviewCopyWith<$Res> implements $TripOverviewCopyWith<$Res> {
  factory _$TripOverviewCopyWith(_TripOverview value, $Res Function(_TripOverview) _then) = __$TripOverviewCopyWithImpl;
@override @useResult
$Res call({
 Trip trip, int catchCount, int speciesCount, int? maxWeightGrams, int? maxLengthMillimeters, String? coverPhotoPath
});


@override $TripCopyWith<$Res> get trip;

}
/// @nodoc
class __$TripOverviewCopyWithImpl<$Res>
    implements _$TripOverviewCopyWith<$Res> {
  __$TripOverviewCopyWithImpl(this._self, this._then);

  final _TripOverview _self;
  final $Res Function(_TripOverview) _then;

/// Create a copy of TripOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trip = null,Object? catchCount = null,Object? speciesCount = null,Object? maxWeightGrams = freezed,Object? maxLengthMillimeters = freezed,Object? coverPhotoPath = freezed,}) {
  return _then(_TripOverview(
trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip,catchCount: null == catchCount ? _self.catchCount : catchCount // ignore: cast_nullable_to_non_nullable
as int,speciesCount: null == speciesCount ? _self.speciesCount : speciesCount // ignore: cast_nullable_to_non_nullable
as int,maxWeightGrams: freezed == maxWeightGrams ? _self.maxWeightGrams : maxWeightGrams // ignore: cast_nullable_to_non_nullable
as int?,maxLengthMillimeters: freezed == maxLengthMillimeters ? _self.maxLengthMillimeters : maxLengthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,coverPhotoPath: freezed == coverPhotoPath ? _self.coverPhotoPath : coverPhotoPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of TripOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res> get trip {
  
  return $TripCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}

// dart format on
