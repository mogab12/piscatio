// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatchPhoto {

 String get id; String get catchId;/// Relative to the app's photo directory (absolute paths change on iOS).
 String get relativePath; int get width; int get height;/// Original capture time read from EXIF before it was stripped.
 DateTime? get takenAt;
/// Create a copy of CatchPhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatchPhotoCopyWith<CatchPhoto> get copyWith => _$CatchPhotoCopyWithImpl<CatchPhoto>(this as CatchPhoto, _$identity);

  /// Serializes this CatchPhoto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatchPhoto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatchPhoto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.catchId, _this.catchId) || other.catchId == _this.catchId)&&(identical(other.relativePath, _this.relativePath) || other.relativePath == _this.relativePath)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.takenAt, _this.takenAt) || other.takenAt == _this.takenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatchPhoto;
  return Object.hash(runtimeType,_this.id,_this.catchId,_this.relativePath,_this.width,_this.height,_this.takenAt);
}

@override
String toString() {
  final _this = this as CatchPhoto;
  return 'CatchPhoto(id: ${_this.id}, catchId: ${_this.catchId}, relativePath: ${_this.relativePath}, width: ${_this.width}, height: ${_this.height}, takenAt: ${_this.takenAt})';
}


}

/// @nodoc
abstract mixin class $CatchPhotoCopyWith<$Res>  {
  factory $CatchPhotoCopyWith(CatchPhoto value, $Res Function(CatchPhoto) _then) = _$CatchPhotoCopyWithImpl;
@useResult
$Res call({
 String id, String catchId, String relativePath, int width, int height, DateTime? takenAt
});




}
/// @nodoc
class _$CatchPhotoCopyWithImpl<$Res>
    implements $CatchPhotoCopyWith<$Res> {
  _$CatchPhotoCopyWithImpl(this._self, this._then);

  final CatchPhoto _self;
  final $Res Function(CatchPhoto) _then;

/// Create a copy of CatchPhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? catchId = null,Object? relativePath = null,Object? width = null,Object? height = null,Object? takenAt = freezed,}) {
  return _then(CatchPhoto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,catchId: null == catchId ? _self.catchId : catchId // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,takenAt: freezed == takenAt ? _self.takenAt : takenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatchPhoto].
extension CatchPhotoPatterns on CatchPhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatchPhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatchPhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatchPhoto value)  $default,){
final _that = this;
switch (_that) {
case _CatchPhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatchPhoto value)?  $default,){
final _that = this;
switch (_that) {
case _CatchPhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String catchId,  String relativePath,  int width,  int height,  DateTime? takenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatchPhoto() when $default != null:
return $default(_that.id,_that.catchId,_that.relativePath,_that.width,_that.height,_that.takenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String catchId,  String relativePath,  int width,  int height,  DateTime? takenAt)  $default,) {final _that = this;
switch (_that) {
case _CatchPhoto():
return $default(_that.id,_that.catchId,_that.relativePath,_that.width,_that.height,_that.takenAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String catchId,  String relativePath,  int width,  int height,  DateTime? takenAt)?  $default,) {final _that = this;
switch (_that) {
case _CatchPhoto() when $default != null:
return $default(_that.id,_that.catchId,_that.relativePath,_that.width,_that.height,_that.takenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatchPhoto implements CatchPhoto {
  const _CatchPhoto({required this.id, required this.catchId, required this.relativePath, required this.width, required this.height, this.takenAt});
  factory _CatchPhoto.fromJson(Map<String, dynamic> json) => _$CatchPhotoFromJson(json);

@override final  String id;
@override final  String catchId;
/// Relative to the app's photo directory (absolute paths change on iOS).
@override final  String relativePath;
@override final  int width;
@override final  int height;
/// Original capture time read from EXIF before it was stripped.
@override final  DateTime? takenAt;

/// Create a copy of CatchPhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatchPhotoCopyWith<_CatchPhoto> get copyWith => __$CatchPhotoCopyWithImpl<_CatchPhoto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatchPhotoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatchPhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.catchId, catchId) || other.catchId == catchId)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.takenAt, takenAt) || other.takenAt == takenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,catchId,relativePath,width,height,takenAt);
}

@override
String toString() {
    return 'CatchPhoto(id: $id, catchId: $catchId, relativePath: $relativePath, width: $width, height: $height, takenAt: $takenAt)';
}


}

/// @nodoc
abstract mixin class _$CatchPhotoCopyWith<$Res> implements $CatchPhotoCopyWith<$Res> {
  factory _$CatchPhotoCopyWith(_CatchPhoto value, $Res Function(_CatchPhoto) _then) = __$CatchPhotoCopyWithImpl;
@override @useResult
$Res call({
 String id, String catchId, String relativePath, int width, int height, DateTime? takenAt
});




}
/// @nodoc
class __$CatchPhotoCopyWithImpl<$Res>
    implements _$CatchPhotoCopyWith<$Res> {
  __$CatchPhotoCopyWithImpl(this._self, this._then);

  final _CatchPhoto _self;
  final $Res Function(_CatchPhoto) _then;

/// Create a copy of CatchPhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? catchId = null,Object? relativePath = null,Object? width = null,Object? height = null,Object? takenAt = freezed,}) {
  return _then(_CatchPhoto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,catchId: null == catchId ? _self.catchId : catchId // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,takenAt: freezed == takenAt ? _self.takenAt : takenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Catch {

 String get id; String get tripId;/// Null when the species was not identified.
 String? get speciesId;/// UTC.
 DateTime get caughtAt; int? get weightGrams; int? get lengthMillimeters;/// Null means "not informed", which is different from "kept".
 bool? get released; String? get baitId; String? get gearId; int? get depthMillimeters; GeoPoint? get location; String? get notes; List<CatchPhoto> get photos; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Catch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatchCopyWith<Catch> get copyWith => _$CatchCopyWithImpl<Catch>(this as Catch, _$identity);

  /// Serializes this Catch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Catch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Catch&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.tripId, _this.tripId) || other.tripId == _this.tripId)&&(identical(other.speciesId, _this.speciesId) || other.speciesId == _this.speciesId)&&(identical(other.caughtAt, _this.caughtAt) || other.caughtAt == _this.caughtAt)&&(identical(other.weightGrams, _this.weightGrams) || other.weightGrams == _this.weightGrams)&&(identical(other.lengthMillimeters, _this.lengthMillimeters) || other.lengthMillimeters == _this.lengthMillimeters)&&(identical(other.released, _this.released) || other.released == _this.released)&&(identical(other.baitId, _this.baitId) || other.baitId == _this.baitId)&&(identical(other.gearId, _this.gearId) || other.gearId == _this.gearId)&&(identical(other.depthMillimeters, _this.depthMillimeters) || other.depthMillimeters == _this.depthMillimeters)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&const DeepCollectionEquality().equals(other.photos, _this.photos)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Catch;
  return Object.hash(runtimeType,_this.id,_this.tripId,_this.speciesId,_this.caughtAt,_this.weightGrams,_this.lengthMillimeters,_this.released,_this.baitId,_this.gearId,_this.depthMillimeters,_this.location,_this.notes,const DeepCollectionEquality().hash(_this.photos),_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Catch;
  return 'Catch(id: ${_this.id}, tripId: ${_this.tripId}, speciesId: ${_this.speciesId}, caughtAt: ${_this.caughtAt}, weightGrams: ${_this.weightGrams}, lengthMillimeters: ${_this.lengthMillimeters}, released: ${_this.released}, baitId: ${_this.baitId}, gearId: ${_this.gearId}, depthMillimeters: ${_this.depthMillimeters}, location: ${_this.location}, notes: ${_this.notes}, photos: ${_this.photos}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $CatchCopyWith<$Res>  {
  factory $CatchCopyWith(Catch value, $Res Function(Catch) _then) = _$CatchCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String? speciesId, DateTime caughtAt, int? weightGrams, int? lengthMillimeters, bool? released, String? baitId, String? gearId, int? depthMillimeters, GeoPoint? location, String? notes, List<CatchPhoto> photos, DateTime createdAt, DateTime updatedAt
});


$GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class _$CatchCopyWithImpl<$Res>
    implements $CatchCopyWith<$Res> {
  _$CatchCopyWithImpl(this._self, this._then);

  final Catch _self;
  final $Res Function(Catch) _then;

/// Create a copy of Catch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? speciesId = freezed,Object? caughtAt = null,Object? weightGrams = freezed,Object? lengthMillimeters = freezed,Object? released = freezed,Object? baitId = freezed,Object? gearId = freezed,Object? depthMillimeters = freezed,Object? location = freezed,Object? notes = freezed,Object? photos = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Catch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,speciesId: freezed == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String?,caughtAt: null == caughtAt ? _self.caughtAt : caughtAt // ignore: cast_nullable_to_non_nullable
as DateTime,weightGrams: freezed == weightGrams ? _self.weightGrams : weightGrams // ignore: cast_nullable_to_non_nullable
as int?,lengthMillimeters: freezed == lengthMillimeters ? _self.lengthMillimeters : lengthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,released: freezed == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as bool?,baitId: freezed == baitId ? _self.baitId : baitId // ignore: cast_nullable_to_non_nullable
as String?,gearId: freezed == gearId ? _self.gearId : gearId // ignore: cast_nullable_to_non_nullable
as String?,depthMillimeters: freezed == depthMillimeters ? _self.depthMillimeters : depthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<CatchPhoto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Catch
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


/// Adds pattern-matching-related methods to [Catch].
extension CatchPatterns on Catch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Catch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Catch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Catch value)  $default,){
final _that = this;
switch (_that) {
case _Catch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Catch value)?  $default,){
final _that = this;
switch (_that) {
case _Catch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String? speciesId,  DateTime caughtAt,  int? weightGrams,  int? lengthMillimeters,  bool? released,  String? baitId,  String? gearId,  int? depthMillimeters,  GeoPoint? location,  String? notes,  List<CatchPhoto> photos,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Catch() when $default != null:
return $default(_that.id,_that.tripId,_that.speciesId,_that.caughtAt,_that.weightGrams,_that.lengthMillimeters,_that.released,_that.baitId,_that.gearId,_that.depthMillimeters,_that.location,_that.notes,_that.photos,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String? speciesId,  DateTime caughtAt,  int? weightGrams,  int? lengthMillimeters,  bool? released,  String? baitId,  String? gearId,  int? depthMillimeters,  GeoPoint? location,  String? notes,  List<CatchPhoto> photos,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Catch():
return $default(_that.id,_that.tripId,_that.speciesId,_that.caughtAt,_that.weightGrams,_that.lengthMillimeters,_that.released,_that.baitId,_that.gearId,_that.depthMillimeters,_that.location,_that.notes,_that.photos,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String? speciesId,  DateTime caughtAt,  int? weightGrams,  int? lengthMillimeters,  bool? released,  String? baitId,  String? gearId,  int? depthMillimeters,  GeoPoint? location,  String? notes,  List<CatchPhoto> photos,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Catch() when $default != null:
return $default(_that.id,_that.tripId,_that.speciesId,_that.caughtAt,_that.weightGrams,_that.lengthMillimeters,_that.released,_that.baitId,_that.gearId,_that.depthMillimeters,_that.location,_that.notes,_that.photos,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Catch extends Catch {
  const _Catch({required this.id, required this.tripId, this.speciesId, required this.caughtAt, this.weightGrams, this.lengthMillimeters, this.released, this.baitId, this.gearId, this.depthMillimeters, this.location, this.notes,  List<CatchPhoto> photos = const <CatchPhoto>[], required this.createdAt, required this.updatedAt}): _photos = photos,super._();
  factory _Catch.fromJson(Map<String, dynamic> json) => _$CatchFromJson(json);

@override final  String id;
@override final  String tripId;
/// Null when the species was not identified.
@override final  String? speciesId;
/// UTC.
@override final  DateTime caughtAt;
@override final  int? weightGrams;
@override final  int? lengthMillimeters;
/// Null means "not informed", which is different from "kept".
@override final  bool? released;
@override final  String? baitId;
@override final  String? gearId;
@override final  int? depthMillimeters;
@override final  GeoPoint? location;
@override final  String? notes;
 final  List<CatchPhoto> _photos;
@override@JsonKey() List<CatchPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Catch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatchCopyWith<_Catch> get copyWith => __$CatchCopyWithImpl<_Catch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatchToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Catch&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.caughtAt, caughtAt) || other.caughtAt == caughtAt)&&(identical(other.weightGrams, weightGrams) || other.weightGrams == weightGrams)&&(identical(other.lengthMillimeters, lengthMillimeters) || other.lengthMillimeters == lengthMillimeters)&&(identical(other.released, released) || other.released == released)&&(identical(other.baitId, baitId) || other.baitId == baitId)&&(identical(other.gearId, gearId) || other.gearId == gearId)&&(identical(other.depthMillimeters, depthMillimeters) || other.depthMillimeters == depthMillimeters)&&(identical(other.location, location) || other.location == location)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.photos, _photos)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,tripId,speciesId,caughtAt,weightGrams,lengthMillimeters,released,baitId,gearId,depthMillimeters,location,notes,const DeepCollectionEquality().hash(_photos),createdAt,updatedAt);
}

@override
String toString() {
    return 'Catch(id: $id, tripId: $tripId, speciesId: $speciesId, caughtAt: $caughtAt, weightGrams: $weightGrams, lengthMillimeters: $lengthMillimeters, released: $released, baitId: $baitId, gearId: $gearId, depthMillimeters: $depthMillimeters, location: $location, notes: $notes, photos: $photos, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CatchCopyWith<$Res> implements $CatchCopyWith<$Res> {
  factory _$CatchCopyWith(_Catch value, $Res Function(_Catch) _then) = __$CatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String? speciesId, DateTime caughtAt, int? weightGrams, int? lengthMillimeters, bool? released, String? baitId, String? gearId, int? depthMillimeters, GeoPoint? location, String? notes, List<CatchPhoto> photos, DateTime createdAt, DateTime updatedAt
});


@override $GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class __$CatchCopyWithImpl<$Res>
    implements _$CatchCopyWith<$Res> {
  __$CatchCopyWithImpl(this._self, this._then);

  final _Catch _self;
  final $Res Function(_Catch) _then;

/// Create a copy of Catch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? speciesId = freezed,Object? caughtAt = null,Object? weightGrams = freezed,Object? lengthMillimeters = freezed,Object? released = freezed,Object? baitId = freezed,Object? gearId = freezed,Object? depthMillimeters = freezed,Object? location = freezed,Object? notes = freezed,Object? photos = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Catch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,speciesId: freezed == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String?,caughtAt: null == caughtAt ? _self.caughtAt : caughtAt // ignore: cast_nullable_to_non_nullable
as DateTime,weightGrams: freezed == weightGrams ? _self.weightGrams : weightGrams // ignore: cast_nullable_to_non_nullable
as int?,lengthMillimeters: freezed == lengthMillimeters ? _self.lengthMillimeters : lengthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,released: freezed == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as bool?,baitId: freezed == baitId ? _self.baitId : baitId // ignore: cast_nullable_to_non_nullable
as String?,gearId: freezed == gearId ? _self.gearId : gearId // ignore: cast_nullable_to_non_nullable
as String?,depthMillimeters: freezed == depthMillimeters ? _self.depthMillimeters : depthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<CatchPhoto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Catch
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
mixin _$CatchDetails {

 String? get speciesId; DateTime? get caughtAt; int? get weightGrams; int? get lengthMillimeters; bool? get released; String? get baitId; String? get gearId; int? get depthMillimeters; String? get notes;
/// Create a copy of CatchDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatchDetailsCopyWith<CatchDetails> get copyWith => _$CatchDetailsCopyWithImpl<CatchDetails>(this as CatchDetails, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatchDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatchDetails&&(identical(other.speciesId, _this.speciesId) || other.speciesId == _this.speciesId)&&(identical(other.caughtAt, _this.caughtAt) || other.caughtAt == _this.caughtAt)&&(identical(other.weightGrams, _this.weightGrams) || other.weightGrams == _this.weightGrams)&&(identical(other.lengthMillimeters, _this.lengthMillimeters) || other.lengthMillimeters == _this.lengthMillimeters)&&(identical(other.released, _this.released) || other.released == _this.released)&&(identical(other.baitId, _this.baitId) || other.baitId == _this.baitId)&&(identical(other.gearId, _this.gearId) || other.gearId == _this.gearId)&&(identical(other.depthMillimeters, _this.depthMillimeters) || other.depthMillimeters == _this.depthMillimeters)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}


@override
int get hashCode {
  final _this = this as CatchDetails;
  return Object.hash(runtimeType,_this.speciesId,_this.caughtAt,_this.weightGrams,_this.lengthMillimeters,_this.released,_this.baitId,_this.gearId,_this.depthMillimeters,_this.notes);
}

@override
String toString() {
  final _this = this as CatchDetails;
  return 'CatchDetails(speciesId: ${_this.speciesId}, caughtAt: ${_this.caughtAt}, weightGrams: ${_this.weightGrams}, lengthMillimeters: ${_this.lengthMillimeters}, released: ${_this.released}, baitId: ${_this.baitId}, gearId: ${_this.gearId}, depthMillimeters: ${_this.depthMillimeters}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $CatchDetailsCopyWith<$Res>  {
  factory $CatchDetailsCopyWith(CatchDetails value, $Res Function(CatchDetails) _then) = _$CatchDetailsCopyWithImpl;
@useResult
$Res call({
 String? speciesId, DateTime? caughtAt, int? weightGrams, int? lengthMillimeters, bool? released, String? baitId, String? gearId, int? depthMillimeters, String? notes
});




}
/// @nodoc
class _$CatchDetailsCopyWithImpl<$Res>
    implements $CatchDetailsCopyWith<$Res> {
  _$CatchDetailsCopyWithImpl(this._self, this._then);

  final CatchDetails _self;
  final $Res Function(CatchDetails) _then;

/// Create a copy of CatchDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? speciesId = freezed,Object? caughtAt = freezed,Object? weightGrams = freezed,Object? lengthMillimeters = freezed,Object? released = freezed,Object? baitId = freezed,Object? gearId = freezed,Object? depthMillimeters = freezed,Object? notes = freezed,}) {
  return _then(CatchDetails(
speciesId: freezed == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String?,caughtAt: freezed == caughtAt ? _self.caughtAt : caughtAt // ignore: cast_nullable_to_non_nullable
as DateTime?,weightGrams: freezed == weightGrams ? _self.weightGrams : weightGrams // ignore: cast_nullable_to_non_nullable
as int?,lengthMillimeters: freezed == lengthMillimeters ? _self.lengthMillimeters : lengthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,released: freezed == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as bool?,baitId: freezed == baitId ? _self.baitId : baitId // ignore: cast_nullable_to_non_nullable
as String?,gearId: freezed == gearId ? _self.gearId : gearId // ignore: cast_nullable_to_non_nullable
as String?,depthMillimeters: freezed == depthMillimeters ? _self.depthMillimeters : depthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatchDetails].
extension CatchDetailsPatterns on CatchDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatchDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatchDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatchDetails value)  $default,){
final _that = this;
switch (_that) {
case _CatchDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatchDetails value)?  $default,){
final _that = this;
switch (_that) {
case _CatchDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? speciesId,  DateTime? caughtAt,  int? weightGrams,  int? lengthMillimeters,  bool? released,  String? baitId,  String? gearId,  int? depthMillimeters,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatchDetails() when $default != null:
return $default(_that.speciesId,_that.caughtAt,_that.weightGrams,_that.lengthMillimeters,_that.released,_that.baitId,_that.gearId,_that.depthMillimeters,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? speciesId,  DateTime? caughtAt,  int? weightGrams,  int? lengthMillimeters,  bool? released,  String? baitId,  String? gearId,  int? depthMillimeters,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _CatchDetails():
return $default(_that.speciesId,_that.caughtAt,_that.weightGrams,_that.lengthMillimeters,_that.released,_that.baitId,_that.gearId,_that.depthMillimeters,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? speciesId,  DateTime? caughtAt,  int? weightGrams,  int? lengthMillimeters,  bool? released,  String? baitId,  String? gearId,  int? depthMillimeters,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _CatchDetails() when $default != null:
return $default(_that.speciesId,_that.caughtAt,_that.weightGrams,_that.lengthMillimeters,_that.released,_that.baitId,_that.gearId,_that.depthMillimeters,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _CatchDetails implements CatchDetails {
  const _CatchDetails({this.speciesId, this.caughtAt, this.weightGrams, this.lengthMillimeters, this.released, this.baitId, this.gearId, this.depthMillimeters, this.notes});
  

@override final  String? speciesId;
@override final  DateTime? caughtAt;
@override final  int? weightGrams;
@override final  int? lengthMillimeters;
@override final  bool? released;
@override final  String? baitId;
@override final  String? gearId;
@override final  int? depthMillimeters;
@override final  String? notes;

/// Create a copy of CatchDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatchDetailsCopyWith<_CatchDetails> get copyWith => __$CatchDetailsCopyWithImpl<_CatchDetails>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatchDetails&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.caughtAt, caughtAt) || other.caughtAt == caughtAt)&&(identical(other.weightGrams, weightGrams) || other.weightGrams == weightGrams)&&(identical(other.lengthMillimeters, lengthMillimeters) || other.lengthMillimeters == lengthMillimeters)&&(identical(other.released, released) || other.released == released)&&(identical(other.baitId, baitId) || other.baitId == baitId)&&(identical(other.gearId, gearId) || other.gearId == gearId)&&(identical(other.depthMillimeters, depthMillimeters) || other.depthMillimeters == depthMillimeters)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,speciesId,caughtAt,weightGrams,lengthMillimeters,released,baitId,gearId,depthMillimeters,notes);
}

@override
String toString() {
    return 'CatchDetails(speciesId: $speciesId, caughtAt: $caughtAt, weightGrams: $weightGrams, lengthMillimeters: $lengthMillimeters, released: $released, baitId: $baitId, gearId: $gearId, depthMillimeters: $depthMillimeters, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$CatchDetailsCopyWith<$Res> implements $CatchDetailsCopyWith<$Res> {
  factory _$CatchDetailsCopyWith(_CatchDetails value, $Res Function(_CatchDetails) _then) = __$CatchDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? speciesId, DateTime? caughtAt, int? weightGrams, int? lengthMillimeters, bool? released, String? baitId, String? gearId, int? depthMillimeters, String? notes
});




}
/// @nodoc
class __$CatchDetailsCopyWithImpl<$Res>
    implements _$CatchDetailsCopyWith<$Res> {
  __$CatchDetailsCopyWithImpl(this._self, this._then);

  final _CatchDetails _self;
  final $Res Function(_CatchDetails) _then;

/// Create a copy of CatchDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? speciesId = freezed,Object? caughtAt = freezed,Object? weightGrams = freezed,Object? lengthMillimeters = freezed,Object? released = freezed,Object? baitId = freezed,Object? gearId = freezed,Object? depthMillimeters = freezed,Object? notes = freezed,}) {
  return _then(_CatchDetails(
speciesId: freezed == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String?,caughtAt: freezed == caughtAt ? _self.caughtAt : caughtAt // ignore: cast_nullable_to_non_nullable
as DateTime?,weightGrams: freezed == weightGrams ? _self.weightGrams : weightGrams // ignore: cast_nullable_to_non_nullable
as int?,lengthMillimeters: freezed == lengthMillimeters ? _self.lengthMillimeters : lengthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,released: freezed == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as bool?,baitId: freezed == baitId ? _self.baitId : baitId // ignore: cast_nullable_to_non_nullable
as String?,gearId: freezed == gearId ? _self.gearId : gearId // ignore: cast_nullable_to_non_nullable
as String?,depthMillimeters: freezed == depthMillimeters ? _self.depthMillimeters : depthMillimeters // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
