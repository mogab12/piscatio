// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tackle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Bait {

 String get id; String get name; BaitType get type; String? get notes; bool get archived;
/// Create a copy of Bait
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BaitCopyWith<Bait> get copyWith => _$BaitCopyWithImpl<Bait>(this as Bait, _$identity);

  /// Serializes this Bait to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Bait;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bait&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.archived, _this.archived) || other.archived == _this.archived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Bait;
  return Object.hash(runtimeType,_this.id,_this.name,_this.type,_this.notes,_this.archived);
}

@override
String toString() {
  final _this = this as Bait;
  return 'Bait(id: ${_this.id}, name: ${_this.name}, type: ${_this.type}, notes: ${_this.notes}, archived: ${_this.archived})';
}


}

/// @nodoc
abstract mixin class $BaitCopyWith<$Res>  {
  factory $BaitCopyWith(Bait value, $Res Function(Bait) _then) = _$BaitCopyWithImpl;
@useResult
$Res call({
 String id, String name, BaitType type, String? notes, bool archived
});




}
/// @nodoc
class _$BaitCopyWithImpl<$Res>
    implements $BaitCopyWith<$Res> {
  _$BaitCopyWithImpl(this._self, this._then);

  final Bait _self;
  final $Res Function(Bait) _then;

/// Create a copy of Bait
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? notes = freezed,Object? archived = null,}) {
  return _then(Bait(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BaitType,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Bait].
extension BaitPatterns on Bait {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Bait value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Bait() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Bait value)  $default,){
final _that = this;
switch (_that) {
case _Bait():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Bait value)?  $default,){
final _that = this;
switch (_that) {
case _Bait() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  BaitType type,  String? notes,  bool archived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Bait() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.notes,_that.archived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  BaitType type,  String? notes,  bool archived)  $default,) {final _that = this;
switch (_that) {
case _Bait():
return $default(_that.id,_that.name,_that.type,_that.notes,_that.archived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  BaitType type,  String? notes,  bool archived)?  $default,) {final _that = this;
switch (_that) {
case _Bait() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.notes,_that.archived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Bait implements Bait {
  const _Bait({required this.id, required this.name, required this.type, this.notes, this.archived = false});
  factory _Bait.fromJson(Map<String, dynamic> json) => _$BaitFromJson(json);

@override final  String id;
@override final  String name;
@override final  BaitType type;
@override final  String? notes;
@override@JsonKey() final  bool archived;

/// Create a copy of Bait
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BaitCopyWith<_Bait> get copyWith => __$BaitCopyWithImpl<_Bait>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BaitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Bait&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.archived, archived) || other.archived == archived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,type,notes,archived);
}

@override
String toString() {
    return 'Bait(id: $id, name: $name, type: $type, notes: $notes, archived: $archived)';
}


}

/// @nodoc
abstract mixin class _$BaitCopyWith<$Res> implements $BaitCopyWith<$Res> {
  factory _$BaitCopyWith(_Bait value, $Res Function(_Bait) _then) = __$BaitCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, BaitType type, String? notes, bool archived
});




}
/// @nodoc
class __$BaitCopyWithImpl<$Res>
    implements _$BaitCopyWith<$Res> {
  __$BaitCopyWithImpl(this._self, this._then);

  final _Bait _self;
  final $Res Function(_Bait) _then;

/// Create a copy of Bait
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? notes = freezed,Object? archived = null,}) {
  return _then(_Bait(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BaitType,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Gear {

 String get id; String get name; GearType get type; String? get notes; bool get archived;
/// Create a copy of Gear
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearCopyWith<Gear> get copyWith => _$GearCopyWithImpl<Gear>(this as Gear, _$identity);

  /// Serializes this Gear to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Gear;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Gear&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.archived, _this.archived) || other.archived == _this.archived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Gear;
  return Object.hash(runtimeType,_this.id,_this.name,_this.type,_this.notes,_this.archived);
}

@override
String toString() {
  final _this = this as Gear;
  return 'Gear(id: ${_this.id}, name: ${_this.name}, type: ${_this.type}, notes: ${_this.notes}, archived: ${_this.archived})';
}


}

/// @nodoc
abstract mixin class $GearCopyWith<$Res>  {
  factory $GearCopyWith(Gear value, $Res Function(Gear) _then) = _$GearCopyWithImpl;
@useResult
$Res call({
 String id, String name, GearType type, String? notes, bool archived
});




}
/// @nodoc
class _$GearCopyWithImpl<$Res>
    implements $GearCopyWith<$Res> {
  _$GearCopyWithImpl(this._self, this._then);

  final Gear _self;
  final $Res Function(Gear) _then;

/// Create a copy of Gear
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? notes = freezed,Object? archived = null,}) {
  return _then(Gear(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GearType,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Gear].
extension GearPatterns on Gear {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Gear value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Gear() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Gear value)  $default,){
final _that = this;
switch (_that) {
case _Gear():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Gear value)?  $default,){
final _that = this;
switch (_that) {
case _Gear() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  GearType type,  String? notes,  bool archived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Gear() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.notes,_that.archived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  GearType type,  String? notes,  bool archived)  $default,) {final _that = this;
switch (_that) {
case _Gear():
return $default(_that.id,_that.name,_that.type,_that.notes,_that.archived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  GearType type,  String? notes,  bool archived)?  $default,) {final _that = this;
switch (_that) {
case _Gear() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.notes,_that.archived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Gear implements Gear {
  const _Gear({required this.id, required this.name, required this.type, this.notes, this.archived = false});
  factory _Gear.fromJson(Map<String, dynamic> json) => _$GearFromJson(json);

@override final  String id;
@override final  String name;
@override final  GearType type;
@override final  String? notes;
@override@JsonKey() final  bool archived;

/// Create a copy of Gear
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearCopyWith<_Gear> get copyWith => __$GearCopyWithImpl<_Gear>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Gear&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.archived, archived) || other.archived == archived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,type,notes,archived);
}

@override
String toString() {
    return 'Gear(id: $id, name: $name, type: $type, notes: $notes, archived: $archived)';
}


}

/// @nodoc
abstract mixin class _$GearCopyWith<$Res> implements $GearCopyWith<$Res> {
  factory _$GearCopyWith(_Gear value, $Res Function(_Gear) _then) = __$GearCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, GearType type, String? notes, bool archived
});




}
/// @nodoc
class __$GearCopyWithImpl<$Res>
    implements _$GearCopyWith<$Res> {
  __$GearCopyWithImpl(this._self, this._then);

  final _Gear _self;
  final $Res Function(_Gear) _then;

/// Create a copy of Gear
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? notes = freezed,Object? archived = null,}) {
  return _then(_Gear(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GearType,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
