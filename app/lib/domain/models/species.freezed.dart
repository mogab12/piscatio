// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'species.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SpeciesName {

/// `pt`, `en`, `es`, or [scientificSynonymLang].
 String get lang; String get name; bool get isPrimary;/// Optional ISO country where this name is used (e.g. `AR` for tararira).
 String? get region;/// Translation needs human review before it is considered final.
 bool get needsReview;
/// Create a copy of SpeciesName
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeciesNameCopyWith<SpeciesName> get copyWith => _$SpeciesNameCopyWithImpl<SpeciesName>(this as SpeciesName, _$identity);

  /// Serializes this SpeciesName to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SpeciesName;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeciesName&&(identical(other.lang, _this.lang) || other.lang == _this.lang)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.isPrimary, _this.isPrimary) || other.isPrimary == _this.isPrimary)&&(identical(other.region, _this.region) || other.region == _this.region)&&(identical(other.needsReview, _this.needsReview) || other.needsReview == _this.needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SpeciesName;
  return Object.hash(runtimeType,_this.lang,_this.name,_this.isPrimary,_this.region,_this.needsReview);
}

@override
String toString() {
  final _this = this as SpeciesName;
  return 'SpeciesName(lang: ${_this.lang}, name: ${_this.name}, isPrimary: ${_this.isPrimary}, region: ${_this.region}, needsReview: ${_this.needsReview})';
}


}

/// @nodoc
abstract mixin class $SpeciesNameCopyWith<$Res>  {
  factory $SpeciesNameCopyWith(SpeciesName value, $Res Function(SpeciesName) _then) = _$SpeciesNameCopyWithImpl;
@useResult
$Res call({
 String lang, String name, bool isPrimary, String? region, bool needsReview
});




}
/// @nodoc
class _$SpeciesNameCopyWithImpl<$Res>
    implements $SpeciesNameCopyWith<$Res> {
  _$SpeciesNameCopyWithImpl(this._self, this._then);

  final SpeciesName _self;
  final $Res Function(SpeciesName) _then;

/// Create a copy of SpeciesName
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lang = null,Object? name = null,Object? isPrimary = null,Object? region = freezed,Object? needsReview = null,}) {
  return _then(SpeciesName(
lang: null == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeciesName].
extension SpeciesNamePatterns on SpeciesName {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeciesName value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeciesName() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeciesName value)  $default,){
final _that = this;
switch (_that) {
case _SpeciesName():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeciesName value)?  $default,){
final _that = this;
switch (_that) {
case _SpeciesName() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String lang,  String name,  bool isPrimary,  String? region,  bool needsReview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeciesName() when $default != null:
return $default(_that.lang,_that.name,_that.isPrimary,_that.region,_that.needsReview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String lang,  String name,  bool isPrimary,  String? region,  bool needsReview)  $default,) {final _that = this;
switch (_that) {
case _SpeciesName():
return $default(_that.lang,_that.name,_that.isPrimary,_that.region,_that.needsReview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String lang,  String name,  bool isPrimary,  String? region,  bool needsReview)?  $default,) {final _that = this;
switch (_that) {
case _SpeciesName() when $default != null:
return $default(_that.lang,_that.name,_that.isPrimary,_that.region,_that.needsReview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpeciesName implements SpeciesName {
  const _SpeciesName({required this.lang, required this.name, this.isPrimary = false, this.region, this.needsReview = false});
  factory _SpeciesName.fromJson(Map<String, dynamic> json) => _$SpeciesNameFromJson(json);

/// `pt`, `en`, `es`, or [scientificSynonymLang].
@override final  String lang;
@override final  String name;
@override@JsonKey() final  bool isPrimary;
/// Optional ISO country where this name is used (e.g. `AR` for tararira).
@override final  String? region;
/// Translation needs human review before it is considered final.
@override@JsonKey() final  bool needsReview;

/// Create a copy of SpeciesName
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeciesNameCopyWith<_SpeciesName> get copyWith => __$SpeciesNameCopyWithImpl<_SpeciesName>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpeciesNameToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeciesName&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.name, name) || other.name == name)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.region, region) || other.region == region)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lang,name,isPrimary,region,needsReview);
}

@override
String toString() {
    return 'SpeciesName(lang: $lang, name: $name, isPrimary: $isPrimary, region: $region, needsReview: $needsReview)';
}


}

/// @nodoc
abstract mixin class _$SpeciesNameCopyWith<$Res> implements $SpeciesNameCopyWith<$Res> {
  factory _$SpeciesNameCopyWith(_SpeciesName value, $Res Function(_SpeciesName) _then) = __$SpeciesNameCopyWithImpl;
@override @useResult
$Res call({
 String lang, String name, bool isPrimary, String? region, bool needsReview
});




}
/// @nodoc
class __$SpeciesNameCopyWithImpl<$Res>
    implements _$SpeciesNameCopyWith<$Res> {
  __$SpeciesNameCopyWithImpl(this._self, this._then);

  final _SpeciesName _self;
  final $Res Function(_SpeciesName) _then;

/// Create a copy of SpeciesName
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lang = null,Object? name = null,Object? isPrimary = null,Object? region = freezed,Object? needsReview = null,}) {
  return _then(_SpeciesName(
lang: null == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Species {

/// Stable slug, never changes even if the scientific name does.
 String get id; String get scientificName; List<Habitat> get habitats;/// Continents/countries where the species is commonly fished
/// (`SA`, `NA`, `BR`, `US`…). Used to rank the catalog.
 List<String> get regionTags; List<SpeciesName> get names; bool get isCustom;
/// Create a copy of Species
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeciesCopyWith<Species> get copyWith => _$SpeciesCopyWithImpl<Species>(this as Species, _$identity);

  /// Serializes this Species to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Species;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Species&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.scientificName, _this.scientificName) || other.scientificName == _this.scientificName)&&const DeepCollectionEquality().equals(other.habitats, _this.habitats)&&const DeepCollectionEquality().equals(other.regionTags, _this.regionTags)&&const DeepCollectionEquality().equals(other.names, _this.names)&&(identical(other.isCustom, _this.isCustom) || other.isCustom == _this.isCustom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Species;
  return Object.hash(runtimeType,_this.id,_this.scientificName,const DeepCollectionEquality().hash(_this.habitats),const DeepCollectionEquality().hash(_this.regionTags),const DeepCollectionEquality().hash(_this.names),_this.isCustom);
}

@override
String toString() {
  final _this = this as Species;
  return 'Species(id: ${_this.id}, scientificName: ${_this.scientificName}, habitats: ${_this.habitats}, regionTags: ${_this.regionTags}, names: ${_this.names}, isCustom: ${_this.isCustom})';
}


}

/// @nodoc
abstract mixin class $SpeciesCopyWith<$Res>  {
  factory $SpeciesCopyWith(Species value, $Res Function(Species) _then) = _$SpeciesCopyWithImpl;
@useResult
$Res call({
 String id, String scientificName, List<Habitat> habitats, List<String> regionTags, List<SpeciesName> names, bool isCustom
});




}
/// @nodoc
class _$SpeciesCopyWithImpl<$Res>
    implements $SpeciesCopyWith<$Res> {
  _$SpeciesCopyWithImpl(this._self, this._then);

  final Species _self;
  final $Res Function(Species) _then;

/// Create a copy of Species
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? scientificName = null,Object? habitats = null,Object? regionTags = null,Object? names = null,Object? isCustom = null,}) {
  return _then(Species(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scientificName: null == scientificName ? _self.scientificName : scientificName // ignore: cast_nullable_to_non_nullable
as String,habitats: null == habitats ? _self.habitats : habitats // ignore: cast_nullable_to_non_nullable
as List<Habitat>,regionTags: null == regionTags ? _self.regionTags : regionTags // ignore: cast_nullable_to_non_nullable
as List<String>,names: null == names ? _self.names : names // ignore: cast_nullable_to_non_nullable
as List<SpeciesName>,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Species].
extension SpeciesPatterns on Species {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Species value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Species() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Species value)  $default,){
final _that = this;
switch (_that) {
case _Species():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Species value)?  $default,){
final _that = this;
switch (_that) {
case _Species() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String scientificName,  List<Habitat> habitats,  List<String> regionTags,  List<SpeciesName> names,  bool isCustom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Species() when $default != null:
return $default(_that.id,_that.scientificName,_that.habitats,_that.regionTags,_that.names,_that.isCustom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String scientificName,  List<Habitat> habitats,  List<String> regionTags,  List<SpeciesName> names,  bool isCustom)  $default,) {final _that = this;
switch (_that) {
case _Species():
return $default(_that.id,_that.scientificName,_that.habitats,_that.regionTags,_that.names,_that.isCustom);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String scientificName,  List<Habitat> habitats,  List<String> regionTags,  List<SpeciesName> names,  bool isCustom)?  $default,) {final _that = this;
switch (_that) {
case _Species() when $default != null:
return $default(_that.id,_that.scientificName,_that.habitats,_that.regionTags,_that.names,_that.isCustom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Species extends Species {
  const _Species({required this.id, required this.scientificName,  List<Habitat> habitats = const <Habitat>[],  List<String> regionTags = const <String>[],  List<SpeciesName> names = const <SpeciesName>[], this.isCustom = false}): _habitats = habitats,_regionTags = regionTags,_names = names,super._();
  factory _Species.fromJson(Map<String, dynamic> json) => _$SpeciesFromJson(json);

/// Stable slug, never changes even if the scientific name does.
@override final  String id;
@override final  String scientificName;
 final  List<Habitat> _habitats;
@override@JsonKey() List<Habitat> get habitats {
  if (_habitats is EqualUnmodifiableListView) return _habitats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_habitats);
}

/// Continents/countries where the species is commonly fished
/// (`SA`, `NA`, `BR`, `US`…). Used to rank the catalog.
 final  List<String> _regionTags;
/// Continents/countries where the species is commonly fished
/// (`SA`, `NA`, `BR`, `US`…). Used to rank the catalog.
@override@JsonKey() List<String> get regionTags {
  if (_regionTags is EqualUnmodifiableListView) return _regionTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_regionTags);
}

 final  List<SpeciesName> _names;
@override@JsonKey() List<SpeciesName> get names {
  if (_names is EqualUnmodifiableListView) return _names;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_names);
}

@override@JsonKey() final  bool isCustom;

/// Create a copy of Species
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeciesCopyWith<_Species> get copyWith => __$SpeciesCopyWithImpl<_Species>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpeciesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Species&&(identical(other.id, id) || other.id == id)&&(identical(other.scientificName, scientificName) || other.scientificName == scientificName)&&const DeepCollectionEquality().equals(other.habitats, _habitats)&&const DeepCollectionEquality().equals(other.regionTags, _regionTags)&&const DeepCollectionEquality().equals(other.names, _names)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,scientificName,const DeepCollectionEquality().hash(_habitats),const DeepCollectionEquality().hash(_regionTags),const DeepCollectionEquality().hash(_names),isCustom);
}

@override
String toString() {
    return 'Species(id: $id, scientificName: $scientificName, habitats: $habitats, regionTags: $regionTags, names: $names, isCustom: $isCustom)';
}


}

/// @nodoc
abstract mixin class _$SpeciesCopyWith<$Res> implements $SpeciesCopyWith<$Res> {
  factory _$SpeciesCopyWith(_Species value, $Res Function(_Species) _then) = __$SpeciesCopyWithImpl;
@override @useResult
$Res call({
 String id, String scientificName, List<Habitat> habitats, List<String> regionTags, List<SpeciesName> names, bool isCustom
});




}
/// @nodoc
class __$SpeciesCopyWithImpl<$Res>
    implements _$SpeciesCopyWith<$Res> {
  __$SpeciesCopyWithImpl(this._self, this._then);

  final _Species _self;
  final $Res Function(_Species) _then;

/// Create a copy of Species
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? scientificName = null,Object? habitats = null,Object? regionTags = null,Object? names = null,Object? isCustom = null,}) {
  return _then(_Species(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scientificName: null == scientificName ? _self.scientificName : scientificName // ignore: cast_nullable_to_non_nullable
as String,habitats: null == habitats ? _self._habitats : habitats // ignore: cast_nullable_to_non_nullable
as List<Habitat>,regionTags: null == regionTags ? _self._regionTags : regionTags // ignore: cast_nullable_to_non_nullable
as List<String>,names: null == names ? _self._names : names // ignore: cast_nullable_to_non_nullable
as List<SpeciesName>,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
