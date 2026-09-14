// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DetectedEncoding {

/// Canonical encoding name (e.g. 'utf-8', 'utf-16le', 'utf-16be', 'gbk', 'gb18030', 'shift-jis').
 String get name;/// Confidence score between 0.0 and 1.0.
 double get confidence;/// True if a definitive Byte Order Mark (BOM) was encountered.
 bool get hasBom;
/// Create a copy of DetectedEncoding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetectedEncodingCopyWith<DetectedEncoding> get copyWith => _$DetectedEncodingCopyWithImpl<DetectedEncoding>(this as DetectedEncoding, _$identity);

  /// Serializes this DetectedEncoding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DetectedEncoding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectedEncoding&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence)&&(identical(other.hasBom, _this.hasBom) || other.hasBom == _this.hasBom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DetectedEncoding;
  return Object.hash(runtimeType,_this.name,_this.confidence,_this.hasBom);
}

@override
String toString() {
  final _this = this as DetectedEncoding;
  return 'DetectedEncoding(name: ${_this.name}, confidence: ${_this.confidence}, hasBom: ${_this.hasBom})';
}


}

/// @nodoc
abstract mixin class $DetectedEncodingCopyWith<$Res>  {
  factory $DetectedEncodingCopyWith(DetectedEncoding value, $Res Function(DetectedEncoding) _then) = _$DetectedEncodingCopyWithImpl;
@useResult
$Res call({
 String name, double confidence, bool hasBom
});




}
/// @nodoc
class _$DetectedEncodingCopyWithImpl<$Res>
    implements $DetectedEncodingCopyWith<$Res> {
  _$DetectedEncodingCopyWithImpl(this._self, this._then);

  final DetectedEncoding _self;
  final $Res Function(DetectedEncoding) _then;

/// Create a copy of DetectedEncoding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? confidence = null,Object? hasBom = null,}) {
  return _then(DetectedEncoding(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,hasBom: null == hasBom ? _self.hasBom : hasBom // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DetectedEncoding].
extension DetectedEncodingPatterns on DetectedEncoding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DetectedEncoding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DetectedEncoding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DetectedEncoding value)  $default,){
final _that = this;
switch (_that) {
case _DetectedEncoding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DetectedEncoding value)?  $default,){
final _that = this;
switch (_that) {
case _DetectedEncoding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double confidence,  bool hasBom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DetectedEncoding() when $default != null:
return $default(_that.name,_that.confidence,_that.hasBom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double confidence,  bool hasBom)  $default,) {final _that = this;
switch (_that) {
case _DetectedEncoding():
return $default(_that.name,_that.confidence,_that.hasBom);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double confidence,  bool hasBom)?  $default,) {final _that = this;
switch (_that) {
case _DetectedEncoding() when $default != null:
return $default(_that.name,_that.confidence,_that.hasBom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DetectedEncoding implements DetectedEncoding {
  const _DetectedEncoding({required this.name, required this.confidence, this.hasBom = false});
  factory _DetectedEncoding.fromJson(Map<String, dynamic> json) => _$DetectedEncodingFromJson(json);

/// Canonical encoding name (e.g. 'utf-8', 'utf-16le', 'utf-16be', 'gbk', 'gb18030', 'shift-jis').
@override final  String name;
/// Confidence score between 0.0 and 1.0.
@override final  double confidence;
/// True if a definitive Byte Order Mark (BOM) was encountered.
@override@JsonKey() final  bool hasBom;

/// Create a copy of DetectedEncoding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetectedEncodingCopyWith<_DetectedEncoding> get copyWith => __$DetectedEncodingCopyWithImpl<_DetectedEncoding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetectedEncodingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetectedEncoding&&(identical(other.name, name) || other.name == name)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.hasBom, hasBom) || other.hasBom == hasBom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,confidence,hasBom);
}

@override
String toString() {
    return 'DetectedEncoding(name: $name, confidence: $confidence, hasBom: $hasBom)';
}


}

/// @nodoc
abstract mixin class _$DetectedEncodingCopyWith<$Res> implements $DetectedEncodingCopyWith<$Res> {
  factory _$DetectedEncodingCopyWith(_DetectedEncoding value, $Res Function(_DetectedEncoding) _then) = __$DetectedEncodingCopyWithImpl;
@override @useResult
$Res call({
 String name, double confidence, bool hasBom
});




}
/// @nodoc
class __$DetectedEncodingCopyWithImpl<$Res>
    implements _$DetectedEncodingCopyWith<$Res> {
  __$DetectedEncodingCopyWithImpl(this._self, this._then);

  final _DetectedEncoding _self;
  final $Res Function(_DetectedEncoding) _then;

/// Create a copy of DetectedEncoding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? confidence = null,Object? hasBom = null,}) {
  return _then(_DetectedEncoding(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,hasBom: null == hasBom ? _self.hasBom : hasBom // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DocumentMetadata {

/// Document title.
 String? get title;/// Primary author/creator.
 String? get creator;/// Language code (e.g. `en`, `fr`).
 String? get language;/// Unique document identifier.
 String? get identifier;/// Publisher name.
 String? get publisher;/// Short description / synopsis.
 String? get description;/// Subject or category.
 String? get subject;/// Last modification timestamp, if known.
 DateTime? get modified;
/// Create a copy of DocumentMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentMetadataCopyWith<DocumentMetadata> get copyWith => _$DocumentMetadataCopyWithImpl<DocumentMetadata>(this as DocumentMetadata, _$identity);

  /// Serializes this DocumentMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DocumentMetadata;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentMetadata&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.creator, _this.creator) || other.creator == _this.creator)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.identifier, _this.identifier) || other.identifier == _this.identifier)&&(identical(other.publisher, _this.publisher) || other.publisher == _this.publisher)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.subject, _this.subject) || other.subject == _this.subject)&&(identical(other.modified, _this.modified) || other.modified == _this.modified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DocumentMetadata;
  return Object.hash(runtimeType,_this.title,_this.creator,_this.language,_this.identifier,_this.publisher,_this.description,_this.subject,_this.modified);
}

@override
String toString() {
  final _this = this as DocumentMetadata;
  return 'DocumentMetadata(title: ${_this.title}, creator: ${_this.creator}, language: ${_this.language}, identifier: ${_this.identifier}, publisher: ${_this.publisher}, description: ${_this.description}, subject: ${_this.subject}, modified: ${_this.modified})';
}


}

/// @nodoc
abstract mixin class $DocumentMetadataCopyWith<$Res>  {
  factory $DocumentMetadataCopyWith(DocumentMetadata value, $Res Function(DocumentMetadata) _then) = _$DocumentMetadataCopyWithImpl;
@useResult
$Res call({
 String? title, String? creator, String? language, String? identifier, String? publisher, String? description, String? subject, DateTime? modified
});




}
/// @nodoc
class _$DocumentMetadataCopyWithImpl<$Res>
    implements $DocumentMetadataCopyWith<$Res> {
  _$DocumentMetadataCopyWithImpl(this._self, this._then);

  final DocumentMetadata _self;
  final $Res Function(DocumentMetadata) _then;

/// Create a copy of DocumentMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? creator = freezed,Object? language = freezed,Object? identifier = freezed,Object? publisher = freezed,Object? description = freezed,Object? subject = freezed,Object? modified = freezed,}) {
  return _then(DocumentMetadata(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,creator: freezed == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,identifier: freezed == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String?,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,modified: freezed == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentMetadata].
extension DocumentMetadataPatterns on DocumentMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentMetadata value)  $default,){
final _that = this;
switch (_that) {
case _DocumentMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? creator,  String? language,  String? identifier,  String? publisher,  String? description,  String? subject,  DateTime? modified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentMetadata() when $default != null:
return $default(_that.title,_that.creator,_that.language,_that.identifier,_that.publisher,_that.description,_that.subject,_that.modified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? creator,  String? language,  String? identifier,  String? publisher,  String? description,  String? subject,  DateTime? modified)  $default,) {final _that = this;
switch (_that) {
case _DocumentMetadata():
return $default(_that.title,_that.creator,_that.language,_that.identifier,_that.publisher,_that.description,_that.subject,_that.modified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? creator,  String? language,  String? identifier,  String? publisher,  String? description,  String? subject,  DateTime? modified)?  $default,) {final _that = this;
switch (_that) {
case _DocumentMetadata() when $default != null:
return $default(_that.title,_that.creator,_that.language,_that.identifier,_that.publisher,_that.description,_that.subject,_that.modified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentMetadata implements DocumentMetadata {
  const _DocumentMetadata({this.title, this.creator, this.language, this.identifier, this.publisher, this.description, this.subject, this.modified});
  factory _DocumentMetadata.fromJson(Map<String, dynamic> json) => _$DocumentMetadataFromJson(json);

/// Document title.
@override final  String? title;
/// Primary author/creator.
@override final  String? creator;
/// Language code (e.g. `en`, `fr`).
@override final  String? language;
/// Unique document identifier.
@override final  String? identifier;
/// Publisher name.
@override final  String? publisher;
/// Short description / synopsis.
@override final  String? description;
/// Subject or category.
@override final  String? subject;
/// Last modification timestamp, if known.
@override final  DateTime? modified;

/// Create a copy of DocumentMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentMetadataCopyWith<_DocumentMetadata> get copyWith => __$DocumentMetadataCopyWithImpl<_DocumentMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentMetadata&&(identical(other.title, title) || other.title == title)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.language, language) || other.language == language)&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.description, description) || other.description == description)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.modified, modified) || other.modified == modified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,creator,language,identifier,publisher,description,subject,modified);
}

@override
String toString() {
    return 'DocumentMetadata(title: $title, creator: $creator, language: $language, identifier: $identifier, publisher: $publisher, description: $description, subject: $subject, modified: $modified)';
}


}

/// @nodoc
abstract mixin class _$DocumentMetadataCopyWith<$Res> implements $DocumentMetadataCopyWith<$Res> {
  factory _$DocumentMetadataCopyWith(_DocumentMetadata value, $Res Function(_DocumentMetadata) _then) = __$DocumentMetadataCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? creator, String? language, String? identifier, String? publisher, String? description, String? subject, DateTime? modified
});




}
/// @nodoc
class __$DocumentMetadataCopyWithImpl<$Res>
    implements _$DocumentMetadataCopyWith<$Res> {
  __$DocumentMetadataCopyWithImpl(this._self, this._then);

  final _DocumentMetadata _self;
  final $Res Function(_DocumentMetadata) _then;

/// Create a copy of DocumentMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? creator = freezed,Object? language = freezed,Object? identifier = freezed,Object? publisher = freezed,Object? description = freezed,Object? subject = freezed,Object? modified = freezed,}) {
  return _then(_DocumentMetadata(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,creator: freezed == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,identifier: freezed == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String?,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,modified: freezed == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$DocumentSection {

/// Zero-based position in the document's section order.
 int get index;/// Stable identifier from the source manifest (e.g. EPUB `id`).
 String get id;/// Path/href of the section within the document container.
 String get href;/// MIME type of the section content (e.g. `application/xhtml+xml`).
 String get mediaType;/// Optional human-readable section title.
 String? get title;
/// Create a copy of DocumentSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentSectionCopyWith<DocumentSection> get copyWith => _$DocumentSectionCopyWithImpl<DocumentSection>(this as DocumentSection, _$identity);

  /// Serializes this DocumentSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DocumentSection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentSection&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.href, _this.href) || other.href == _this.href)&&(identical(other.mediaType, _this.mediaType) || other.mediaType == _this.mediaType)&&(identical(other.title, _this.title) || other.title == _this.title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DocumentSection;
  return Object.hash(runtimeType,_this.index,_this.id,_this.href,_this.mediaType,_this.title);
}

@override
String toString() {
  final _this = this as DocumentSection;
  return 'DocumentSection(index: ${_this.index}, id: ${_this.id}, href: ${_this.href}, mediaType: ${_this.mediaType}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $DocumentSectionCopyWith<$Res>  {
  factory $DocumentSectionCopyWith(DocumentSection value, $Res Function(DocumentSection) _then) = _$DocumentSectionCopyWithImpl;
@useResult
$Res call({
 int index, String id, String href, String mediaType, String? title
});




}
/// @nodoc
class _$DocumentSectionCopyWithImpl<$Res>
    implements $DocumentSectionCopyWith<$Res> {
  _$DocumentSectionCopyWithImpl(this._self, this._then);

  final DocumentSection _self;
  final $Res Function(DocumentSection) _then;

/// Create a copy of DocumentSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? id = null,Object? href = null,Object? mediaType = null,Object? title = freezed,}) {
  return _then(DocumentSection(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,href: null == href ? _self.href : href // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentSection].
extension DocumentSectionPatterns on DocumentSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentSection value)  $default,){
final _that = this;
switch (_that) {
case _DocumentSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentSection value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String id,  String href,  String mediaType,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentSection() when $default != null:
return $default(_that.index,_that.id,_that.href,_that.mediaType,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String id,  String href,  String mediaType,  String? title)  $default,) {final _that = this;
switch (_that) {
case _DocumentSection():
return $default(_that.index,_that.id,_that.href,_that.mediaType,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String id,  String href,  String mediaType,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _DocumentSection() when $default != null:
return $default(_that.index,_that.id,_that.href,_that.mediaType,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentSection implements DocumentSection {
  const _DocumentSection({required this.index, required this.id, required this.href, required this.mediaType, this.title});
  factory _DocumentSection.fromJson(Map<String, dynamic> json) => _$DocumentSectionFromJson(json);

/// Zero-based position in the document's section order.
@override final  int index;
/// Stable identifier from the source manifest (e.g. EPUB `id`).
@override final  String id;
/// Path/href of the section within the document container.
@override final  String href;
/// MIME type of the section content (e.g. `application/xhtml+xml`).
@override final  String mediaType;
/// Optional human-readable section title.
@override final  String? title;

/// Create a copy of DocumentSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentSectionCopyWith<_DocumentSection> get copyWith => __$DocumentSectionCopyWithImpl<_DocumentSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentSectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentSection&&(identical(other.index, index) || other.index == index)&&(identical(other.id, id) || other.id == id)&&(identical(other.href, href) || other.href == href)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,index,id,href,mediaType,title);
}

@override
String toString() {
    return 'DocumentSection(index: $index, id: $id, href: $href, mediaType: $mediaType, title: $title)';
}


}

/// @nodoc
abstract mixin class _$DocumentSectionCopyWith<$Res> implements $DocumentSectionCopyWith<$Res> {
  factory _$DocumentSectionCopyWith(_DocumentSection value, $Res Function(_DocumentSection) _then) = __$DocumentSectionCopyWithImpl;
@override @useResult
$Res call({
 int index, String id, String href, String mediaType, String? title
});




}
/// @nodoc
class __$DocumentSectionCopyWithImpl<$Res>
    implements _$DocumentSectionCopyWith<$Res> {
  __$DocumentSectionCopyWithImpl(this._self, this._then);

  final _DocumentSection _self;
  final $Res Function(_DocumentSection) _then;

/// Create a copy of DocumentSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? id = null,Object? href = null,Object? mediaType = null,Object? title = freezed,}) {
  return _then(_DocumentSection(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,href: null == href ? _self.href : href // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OpfData {

/// Bibliographic metadata from `<metadata>`.
 DocumentMetadata get metadata;/// Ordered spine sections, with hrefs resolved relative to the OPF dir.
 List<DocumentSection> get sections;/// Manifest href of the NCX (EPUB 2), if present.
 String? get ncxHref;/// Manifest href of the `<nav>` document (EPUB 3), if present.
 String? get navHref;/// Directory containing the OPF, used to resolve relative paths.
 String get opfDir;/// Resolved path of the cover image asset, if the OPF declares one.
 String? get coverImagePath;
/// Create a copy of OpfData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpfDataCopyWith<OpfData> get copyWith => _$OpfDataCopyWithImpl<OpfData>(this as OpfData, _$identity);

  /// Serializes this OpfData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OpfData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpfData&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&const DeepCollectionEquality().equals(other.sections, _this.sections)&&(identical(other.ncxHref, _this.ncxHref) || other.ncxHref == _this.ncxHref)&&(identical(other.navHref, _this.navHref) || other.navHref == _this.navHref)&&(identical(other.opfDir, _this.opfDir) || other.opfDir == _this.opfDir)&&(identical(other.coverImagePath, _this.coverImagePath) || other.coverImagePath == _this.coverImagePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OpfData;
  return Object.hash(runtimeType,_this.metadata,const DeepCollectionEquality().hash(_this.sections),_this.ncxHref,_this.navHref,_this.opfDir,_this.coverImagePath);
}

@override
String toString() {
  final _this = this as OpfData;
  return 'OpfData(metadata: ${_this.metadata}, sections: ${_this.sections}, ncxHref: ${_this.ncxHref}, navHref: ${_this.navHref}, opfDir: ${_this.opfDir}, coverImagePath: ${_this.coverImagePath})';
}


}

/// @nodoc
abstract mixin class $OpfDataCopyWith<$Res>  {
  factory $OpfDataCopyWith(OpfData value, $Res Function(OpfData) _then) = _$OpfDataCopyWithImpl;
@useResult
$Res call({
 DocumentMetadata metadata, List<DocumentSection> sections, String? ncxHref, String? navHref, String opfDir, String? coverImagePath
});


$DocumentMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$OpfDataCopyWithImpl<$Res>
    implements $OpfDataCopyWith<$Res> {
  _$OpfDataCopyWithImpl(this._self, this._then);

  final OpfData _self;
  final $Res Function(OpfData) _then;

/// Create a copy of OpfData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadata = null,Object? sections = null,Object? ncxHref = freezed,Object? navHref = freezed,Object? opfDir = null,Object? coverImagePath = freezed,}) {
  return _then(OpfData(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as DocumentMetadata,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<DocumentSection>,ncxHref: freezed == ncxHref ? _self.ncxHref : ncxHref // ignore: cast_nullable_to_non_nullable
as String?,navHref: freezed == navHref ? _self.navHref : navHref // ignore: cast_nullable_to_non_nullable
as String?,opfDir: null == opfDir ? _self.opfDir : opfDir // ignore: cast_nullable_to_non_nullable
as String,coverImagePath: freezed == coverImagePath ? _self.coverImagePath : coverImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of OpfData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentMetadataCopyWith<$Res> get metadata {
  
  return $DocumentMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [OpfData].
extension OpfDataPatterns on OpfData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpfData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpfData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpfData value)  $default,){
final _that = this;
switch (_that) {
case _OpfData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpfData value)?  $default,){
final _that = this;
switch (_that) {
case _OpfData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocumentMetadata metadata,  List<DocumentSection> sections,  String? ncxHref,  String? navHref,  String opfDir,  String? coverImagePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpfData() when $default != null:
return $default(_that.metadata,_that.sections,_that.ncxHref,_that.navHref,_that.opfDir,_that.coverImagePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocumentMetadata metadata,  List<DocumentSection> sections,  String? ncxHref,  String? navHref,  String opfDir,  String? coverImagePath)  $default,) {final _that = this;
switch (_that) {
case _OpfData():
return $default(_that.metadata,_that.sections,_that.ncxHref,_that.navHref,_that.opfDir,_that.coverImagePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocumentMetadata metadata,  List<DocumentSection> sections,  String? ncxHref,  String? navHref,  String opfDir,  String? coverImagePath)?  $default,) {final _that = this;
switch (_that) {
case _OpfData() when $default != null:
return $default(_that.metadata,_that.sections,_that.ncxHref,_that.navHref,_that.opfDir,_that.coverImagePath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpfData implements OpfData {
  const _OpfData({required this.metadata, required  List<DocumentSection> sections, this.ncxHref, this.navHref, this.opfDir = '', this.coverImagePath}): _sections = sections;
  factory _OpfData.fromJson(Map<String, dynamic> json) => _$OpfDataFromJson(json);

/// Bibliographic metadata from `<metadata>`.
@override final  DocumentMetadata metadata;
/// Ordered spine sections, with hrefs resolved relative to the OPF dir.
 final  List<DocumentSection> _sections;
/// Ordered spine sections, with hrefs resolved relative to the OPF dir.
@override List<DocumentSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// Manifest href of the NCX (EPUB 2), if present.
@override final  String? ncxHref;
/// Manifest href of the `<nav>` document (EPUB 3), if present.
@override final  String? navHref;
/// Directory containing the OPF, used to resolve relative paths.
@override@JsonKey() final  String opfDir;
/// Resolved path of the cover image asset, if the OPF declares one.
@override final  String? coverImagePath;

/// Create a copy of OpfData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpfDataCopyWith<_OpfData> get copyWith => __$OpfDataCopyWithImpl<_OpfData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpfDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpfData&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.sections, _sections)&&(identical(other.ncxHref, ncxHref) || other.ncxHref == ncxHref)&&(identical(other.navHref, navHref) || other.navHref == navHref)&&(identical(other.opfDir, opfDir) || other.opfDir == opfDir)&&(identical(other.coverImagePath, coverImagePath) || other.coverImagePath == coverImagePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,metadata,const DeepCollectionEquality().hash(_sections),ncxHref,navHref,opfDir,coverImagePath);
}

@override
String toString() {
    return 'OpfData(metadata: $metadata, sections: $sections, ncxHref: $ncxHref, navHref: $navHref, opfDir: $opfDir, coverImagePath: $coverImagePath)';
}


}

/// @nodoc
abstract mixin class _$OpfDataCopyWith<$Res> implements $OpfDataCopyWith<$Res> {
  factory _$OpfDataCopyWith(_OpfData value, $Res Function(_OpfData) _then) = __$OpfDataCopyWithImpl;
@override @useResult
$Res call({
 DocumentMetadata metadata, List<DocumentSection> sections, String? ncxHref, String? navHref, String opfDir, String? coverImagePath
});


@override $DocumentMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class __$OpfDataCopyWithImpl<$Res>
    implements _$OpfDataCopyWith<$Res> {
  __$OpfDataCopyWithImpl(this._self, this._then);

  final _OpfData _self;
  final $Res Function(_OpfData) _then;

/// Create a copy of OpfData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metadata = null,Object? sections = null,Object? ncxHref = freezed,Object? navHref = freezed,Object? opfDir = null,Object? coverImagePath = freezed,}) {
  return _then(_OpfData(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as DocumentMetadata,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<DocumentSection>,ncxHref: freezed == ncxHref ? _self.ncxHref : ncxHref // ignore: cast_nullable_to_non_nullable
as String?,navHref: freezed == navHref ? _self.navHref : navHref // ignore: cast_nullable_to_non_nullable
as String?,opfDir: null == opfDir ? _self.opfDir : opfDir // ignore: cast_nullable_to_non_nullable
as String,coverImagePath: freezed == coverImagePath ? _self.coverImagePath : coverImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of OpfData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentMetadataCopyWith<$Res> get metadata {
  
  return $DocumentMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// @nodoc
mixin _$FootnoteItem {

/// Unique anchor identifier of the footnote body (e.g. `fn-1`).
 String get id;/// Identifier of the caller reference link if present.
 String? get referenceId;/// Human-readable title or label of the footnote (e.g. `[1]`, `Note 1`).
 String? get title;/// Clean inner HTML content of the footnote body.
 String get contentHtml;/// Semantic type of note: 'footnote', 'endnote', 'rearnote', or 'note'.
 String get type;
/// Create a copy of FootnoteItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FootnoteItemCopyWith<FootnoteItem> get copyWith => _$FootnoteItemCopyWithImpl<FootnoteItem>(this as FootnoteItem, _$identity);

  /// Serializes this FootnoteItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FootnoteItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FootnoteItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.referenceId, _this.referenceId) || other.referenceId == _this.referenceId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.contentHtml, _this.contentHtml) || other.contentHtml == _this.contentHtml)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FootnoteItem;
  return Object.hash(runtimeType,_this.id,_this.referenceId,_this.title,_this.contentHtml,_this.type);
}

@override
String toString() {
  final _this = this as FootnoteItem;
  return 'FootnoteItem(id: ${_this.id}, referenceId: ${_this.referenceId}, title: ${_this.title}, contentHtml: ${_this.contentHtml}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $FootnoteItemCopyWith<$Res>  {
  factory $FootnoteItemCopyWith(FootnoteItem value, $Res Function(FootnoteItem) _then) = _$FootnoteItemCopyWithImpl;
@useResult
$Res call({
 String id, String? referenceId, String? title, String contentHtml, String type
});




}
/// @nodoc
class _$FootnoteItemCopyWithImpl<$Res>
    implements $FootnoteItemCopyWith<$Res> {
  _$FootnoteItemCopyWithImpl(this._self, this._then);

  final FootnoteItem _self;
  final $Res Function(FootnoteItem) _then;

/// Create a copy of FootnoteItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? referenceId = freezed,Object? title = freezed,Object? contentHtml = null,Object? type = null,}) {
  return _then(FootnoteItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,contentHtml: null == contentHtml ? _self.contentHtml : contentHtml // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FootnoteItem].
extension FootnoteItemPatterns on FootnoteItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FootnoteItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FootnoteItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FootnoteItem value)  $default,){
final _that = this;
switch (_that) {
case _FootnoteItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FootnoteItem value)?  $default,){
final _that = this;
switch (_that) {
case _FootnoteItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? referenceId,  String? title,  String contentHtml,  String type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FootnoteItem() when $default != null:
return $default(_that.id,_that.referenceId,_that.title,_that.contentHtml,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? referenceId,  String? title,  String contentHtml,  String type)  $default,) {final _that = this;
switch (_that) {
case _FootnoteItem():
return $default(_that.id,_that.referenceId,_that.title,_that.contentHtml,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? referenceId,  String? title,  String contentHtml,  String type)?  $default,) {final _that = this;
switch (_that) {
case _FootnoteItem() when $default != null:
return $default(_that.id,_that.referenceId,_that.title,_that.contentHtml,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FootnoteItem implements FootnoteItem {
  const _FootnoteItem({required this.id, this.referenceId, this.title, required this.contentHtml, this.type = 'footnote'});
  factory _FootnoteItem.fromJson(Map<String, dynamic> json) => _$FootnoteItemFromJson(json);

/// Unique anchor identifier of the footnote body (e.g. `fn-1`).
@override final  String id;
/// Identifier of the caller reference link if present.
@override final  String? referenceId;
/// Human-readable title or label of the footnote (e.g. `[1]`, `Note 1`).
@override final  String? title;
/// Clean inner HTML content of the footnote body.
@override final  String contentHtml;
/// Semantic type of note: 'footnote', 'endnote', 'rearnote', or 'note'.
@override@JsonKey() final  String type;

/// Create a copy of FootnoteItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FootnoteItemCopyWith<_FootnoteItem> get copyWith => __$FootnoteItemCopyWithImpl<_FootnoteItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FootnoteItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FootnoteItem&&(identical(other.id, id) || other.id == id)&&(identical(other.referenceId, referenceId) || other.referenceId == referenceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.contentHtml, contentHtml) || other.contentHtml == contentHtml)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,referenceId,title,contentHtml,type);
}

@override
String toString() {
    return 'FootnoteItem(id: $id, referenceId: $referenceId, title: $title, contentHtml: $contentHtml, type: $type)';
}


}

/// @nodoc
abstract mixin class _$FootnoteItemCopyWith<$Res> implements $FootnoteItemCopyWith<$Res> {
  factory _$FootnoteItemCopyWith(_FootnoteItem value, $Res Function(_FootnoteItem) _then) = __$FootnoteItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String? referenceId, String? title, String contentHtml, String type
});




}
/// @nodoc
class __$FootnoteItemCopyWithImpl<$Res>
    implements _$FootnoteItemCopyWith<$Res> {
  __$FootnoteItemCopyWithImpl(this._self, this._then);

  final _FootnoteItem _self;
  final $Res Function(_FootnoteItem) _then;

/// Create a copy of FootnoteItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? referenceId = freezed,Object? title = freezed,Object? contentHtml = null,Object? type = null,}) {
  return _then(_FootnoteItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,contentHtml: null == contentHtml ? _self.contentHtml : contentHtml // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OutlineItem {

/// Display label of the outline entry.
 String get title;/// Target href within the document, if any.
 String? get href;/// Nesting depth (0 = top level).
 int get level;/// Index of the section/chapter this entry targets, if resolvable.
 int? get chapterIndex;/// Nested child entries.
 List<OutlineItem> get children;
/// Create a copy of OutlineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutlineItemCopyWith<OutlineItem> get copyWith => _$OutlineItemCopyWithImpl<OutlineItem>(this as OutlineItem, _$identity);

  /// Serializes this OutlineItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OutlineItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutlineItem&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.href, _this.href) || other.href == _this.href)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.chapterIndex, _this.chapterIndex) || other.chapterIndex == _this.chapterIndex)&&const DeepCollectionEquality().equals(other.children, _this.children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OutlineItem;
  return Object.hash(runtimeType,_this.title,_this.href,_this.level,_this.chapterIndex,const DeepCollectionEquality().hash(_this.children));
}

@override
String toString() {
  final _this = this as OutlineItem;
  return 'OutlineItem(title: ${_this.title}, href: ${_this.href}, level: ${_this.level}, chapterIndex: ${_this.chapterIndex}, children: ${_this.children})';
}


}

/// @nodoc
abstract mixin class $OutlineItemCopyWith<$Res>  {
  factory $OutlineItemCopyWith(OutlineItem value, $Res Function(OutlineItem) _then) = _$OutlineItemCopyWithImpl;
@useResult
$Res call({
 String title, String? href, int level, int? chapterIndex, List<OutlineItem> children
});




}
/// @nodoc
class _$OutlineItemCopyWithImpl<$Res>
    implements $OutlineItemCopyWith<$Res> {
  _$OutlineItemCopyWithImpl(this._self, this._then);

  final OutlineItem _self;
  final $Res Function(OutlineItem) _then;

/// Create a copy of OutlineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? href = freezed,Object? level = null,Object? chapterIndex = freezed,Object? children = null,}) {
  return _then(OutlineItem(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,href: freezed == href ? _self.href : href // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,chapterIndex: freezed == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int?,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<OutlineItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [OutlineItem].
extension OutlineItemPatterns on OutlineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutlineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutlineItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutlineItem value)  $default,){
final _that = this;
switch (_that) {
case _OutlineItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutlineItem value)?  $default,){
final _that = this;
switch (_that) {
case _OutlineItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? href,  int level,  int? chapterIndex,  List<OutlineItem> children)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutlineItem() when $default != null:
return $default(_that.title,_that.href,_that.level,_that.chapterIndex,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? href,  int level,  int? chapterIndex,  List<OutlineItem> children)  $default,) {final _that = this;
switch (_that) {
case _OutlineItem():
return $default(_that.title,_that.href,_that.level,_that.chapterIndex,_that.children);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? href,  int level,  int? chapterIndex,  List<OutlineItem> children)?  $default,) {final _that = this;
switch (_that) {
case _OutlineItem() when $default != null:
return $default(_that.title,_that.href,_that.level,_that.chapterIndex,_that.children);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OutlineItem extends OutlineItem {
  const _OutlineItem({required this.title, this.href, this.level = 0, this.chapterIndex,  List<OutlineItem> children = const []}): _children = children,super._();
  factory _OutlineItem.fromJson(Map<String, dynamic> json) => _$OutlineItemFromJson(json);

/// Display label of the outline entry.
@override final  String title;
/// Target href within the document, if any.
@override final  String? href;
/// Nesting depth (0 = top level).
@override@JsonKey() final  int level;
/// Index of the section/chapter this entry targets, if resolvable.
@override final  int? chapterIndex;
/// Nested child entries.
 final  List<OutlineItem> _children;
/// Nested child entries.
@override@JsonKey() List<OutlineItem> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of OutlineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutlineItemCopyWith<_OutlineItem> get copyWith => __$OutlineItemCopyWithImpl<_OutlineItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutlineItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutlineItem&&(identical(other.title, title) || other.title == title)&&(identical(other.href, href) || other.href == href)&&(identical(other.level, level) || other.level == level)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&const DeepCollectionEquality().equals(other.children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,href,level,chapterIndex,const DeepCollectionEquality().hash(_children));
}

@override
String toString() {
    return 'OutlineItem(title: $title, href: $href, level: $level, chapterIndex: $chapterIndex, children: $children)';
}


}

/// @nodoc
abstract mixin class _$OutlineItemCopyWith<$Res> implements $OutlineItemCopyWith<$Res> {
  factory _$OutlineItemCopyWith(_OutlineItem value, $Res Function(_OutlineItem) _then) = __$OutlineItemCopyWithImpl;
@override @useResult
$Res call({
 String title, String? href, int level, int? chapterIndex, List<OutlineItem> children
});




}
/// @nodoc
class __$OutlineItemCopyWithImpl<$Res>
    implements _$OutlineItemCopyWith<$Res> {
  __$OutlineItemCopyWithImpl(this._self, this._then);

  final _OutlineItem _self;
  final $Res Function(_OutlineItem) _then;

/// Create a copy of OutlineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? href = freezed,Object? level = null,Object? chapterIndex = freezed,Object? children = null,}) {
  return _then(_OutlineItem(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,href: freezed == href ? _self.href : href // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,chapterIndex: freezed == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int?,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<OutlineItem>,
  ));
}


}


/// @nodoc
mixin _$PageCoordinate {

/// Zero-based chapter/section index.
 int get chapterIndex;/// Zero-based page within the chapter.
 int get pageInChapter;/// Total number of pages in the chapter.
 int get totalPagesInChapter;/// Zero-based page across the whole document.
 int get globalPage;
/// Create a copy of PageCoordinate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageCoordinateCopyWith<PageCoordinate> get copyWith => _$PageCoordinateCopyWithImpl<PageCoordinate>(this as PageCoordinate, _$identity);

  /// Serializes this PageCoordinate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PageCoordinate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageCoordinate&&(identical(other.chapterIndex, _this.chapterIndex) || other.chapterIndex == _this.chapterIndex)&&(identical(other.pageInChapter, _this.pageInChapter) || other.pageInChapter == _this.pageInChapter)&&(identical(other.totalPagesInChapter, _this.totalPagesInChapter) || other.totalPagesInChapter == _this.totalPagesInChapter)&&(identical(other.globalPage, _this.globalPage) || other.globalPage == _this.globalPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PageCoordinate;
  return Object.hash(runtimeType,_this.chapterIndex,_this.pageInChapter,_this.totalPagesInChapter,_this.globalPage);
}

@override
String toString() {
  final _this = this as PageCoordinate;
  return 'PageCoordinate(chapterIndex: ${_this.chapterIndex}, pageInChapter: ${_this.pageInChapter}, totalPagesInChapter: ${_this.totalPagesInChapter}, globalPage: ${_this.globalPage})';
}


}

/// @nodoc
abstract mixin class $PageCoordinateCopyWith<$Res>  {
  factory $PageCoordinateCopyWith(PageCoordinate value, $Res Function(PageCoordinate) _then) = _$PageCoordinateCopyWithImpl;
@useResult
$Res call({
 int chapterIndex, int pageInChapter, int totalPagesInChapter, int globalPage
});




}
/// @nodoc
class _$PageCoordinateCopyWithImpl<$Res>
    implements $PageCoordinateCopyWith<$Res> {
  _$PageCoordinateCopyWithImpl(this._self, this._then);

  final PageCoordinate _self;
  final $Res Function(PageCoordinate) _then;

/// Create a copy of PageCoordinate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chapterIndex = null,Object? pageInChapter = null,Object? totalPagesInChapter = null,Object? globalPage = null,}) {
  return _then(PageCoordinate(
chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,pageInChapter: null == pageInChapter ? _self.pageInChapter : pageInChapter // ignore: cast_nullable_to_non_nullable
as int,totalPagesInChapter: null == totalPagesInChapter ? _self.totalPagesInChapter : totalPagesInChapter // ignore: cast_nullable_to_non_nullable
as int,globalPage: null == globalPage ? _self.globalPage : globalPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PageCoordinate].
extension PageCoordinatePatterns on PageCoordinate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageCoordinate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageCoordinate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageCoordinate value)  $default,){
final _that = this;
switch (_that) {
case _PageCoordinate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageCoordinate value)?  $default,){
final _that = this;
switch (_that) {
case _PageCoordinate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int chapterIndex,  int pageInChapter,  int totalPagesInChapter,  int globalPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageCoordinate() when $default != null:
return $default(_that.chapterIndex,_that.pageInChapter,_that.totalPagesInChapter,_that.globalPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int chapterIndex,  int pageInChapter,  int totalPagesInChapter,  int globalPage)  $default,) {final _that = this;
switch (_that) {
case _PageCoordinate():
return $default(_that.chapterIndex,_that.pageInChapter,_that.totalPagesInChapter,_that.globalPage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int chapterIndex,  int pageInChapter,  int totalPagesInChapter,  int globalPage)?  $default,) {final _that = this;
switch (_that) {
case _PageCoordinate() when $default != null:
return $default(_that.chapterIndex,_that.pageInChapter,_that.totalPagesInChapter,_that.globalPage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageCoordinate extends PageCoordinate {
  const _PageCoordinate({required this.chapterIndex, required this.pageInChapter, required this.totalPagesInChapter, required this.globalPage}): super._();
  factory _PageCoordinate.fromJson(Map<String, dynamic> json) => _$PageCoordinateFromJson(json);

/// Zero-based chapter/section index.
@override final  int chapterIndex;
/// Zero-based page within the chapter.
@override final  int pageInChapter;
/// Total number of pages in the chapter.
@override final  int totalPagesInChapter;
/// Zero-based page across the whole document.
@override final  int globalPage;

/// Create a copy of PageCoordinate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageCoordinateCopyWith<_PageCoordinate> get copyWith => __$PageCoordinateCopyWithImpl<_PageCoordinate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageCoordinateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageCoordinate&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.pageInChapter, pageInChapter) || other.pageInChapter == pageInChapter)&&(identical(other.totalPagesInChapter, totalPagesInChapter) || other.totalPagesInChapter == totalPagesInChapter)&&(identical(other.globalPage, globalPage) || other.globalPage == globalPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,chapterIndex,pageInChapter,totalPagesInChapter,globalPage);
}

@override
String toString() {
    return 'PageCoordinate(chapterIndex: $chapterIndex, pageInChapter: $pageInChapter, totalPagesInChapter: $totalPagesInChapter, globalPage: $globalPage)';
}


}

/// @nodoc
abstract mixin class _$PageCoordinateCopyWith<$Res> implements $PageCoordinateCopyWith<$Res> {
  factory _$PageCoordinateCopyWith(_PageCoordinate value, $Res Function(_PageCoordinate) _then) = __$PageCoordinateCopyWithImpl;
@override @useResult
$Res call({
 int chapterIndex, int pageInChapter, int totalPagesInChapter, int globalPage
});




}
/// @nodoc
class __$PageCoordinateCopyWithImpl<$Res>
    implements _$PageCoordinateCopyWith<$Res> {
  __$PageCoordinateCopyWithImpl(this._self, this._then);

  final _PageCoordinate _self;
  final $Res Function(_PageCoordinate) _then;

/// Create a copy of PageCoordinate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chapterIndex = null,Object? pageInChapter = null,Object? totalPagesInChapter = null,Object? globalPage = null,}) {
  return _then(_PageCoordinate(
chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,pageInChapter: null == pageInChapter ? _self.pageInChapter : pageInChapter // ignore: cast_nullable_to_non_nullable
as int,totalPagesInChapter: null == totalPagesInChapter ? _self.totalPagesInChapter : totalPagesInChapter // ignore: cast_nullable_to_non_nullable
as int,globalPage: null == globalPage ? _self.globalPage : globalPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PageLink {

/// Clickable region in page coordinates.
 PageRect get bounds;/// External URI, if this is an external link.
 String? get uri;/// Resolved target page, if this is an internal link.
 int? get pageNumber;
/// Create a copy of PageLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageLinkCopyWith<PageLink> get copyWith => _$PageLinkCopyWithImpl<PageLink>(this as PageLink, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PageLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageLink&&(identical(other.bounds, _this.bounds) || other.bounds == _this.bounds)&&(identical(other.uri, _this.uri) || other.uri == _this.uri)&&(identical(other.pageNumber, _this.pageNumber) || other.pageNumber == _this.pageNumber));
}


@override
int get hashCode {
  final _this = this as PageLink;
  return Object.hash(runtimeType,_this.bounds,_this.uri,_this.pageNumber);
}

@override
String toString() {
  final _this = this as PageLink;
  return 'PageLink(bounds: ${_this.bounds}, uri: ${_this.uri}, pageNumber: ${_this.pageNumber})';
}


}

/// @nodoc
abstract mixin class $PageLinkCopyWith<$Res>  {
  factory $PageLinkCopyWith(PageLink value, $Res Function(PageLink) _then) = _$PageLinkCopyWithImpl;
@useResult
$Res call({
 PageRect bounds, String? uri, int? pageNumber
});


$PageRectCopyWith<$Res> get bounds;

}
/// @nodoc
class _$PageLinkCopyWithImpl<$Res>
    implements $PageLinkCopyWith<$Res> {
  _$PageLinkCopyWithImpl(this._self, this._then);

  final PageLink _self;
  final $Res Function(PageLink) _then;

/// Create a copy of PageLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bounds = null,Object? uri = freezed,Object? pageNumber = freezed,}) {
  return _then(PageLink(
bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as PageRect,uri: freezed == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String?,pageNumber: freezed == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of PageLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageRectCopyWith<$Res> get bounds {
  
  return $PageRectCopyWith<$Res>(_self.bounds, (value) {
    return _then(_self.copyWith(bounds: value));
  });
}
}


/// Adds pattern-matching-related methods to [PageLink].
extension PageLinkPatterns on PageLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageLink value)  $default,){
final _that = this;
switch (_that) {
case _PageLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageLink value)?  $default,){
final _that = this;
switch (_that) {
case _PageLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PageRect bounds,  String? uri,  int? pageNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageLink() when $default != null:
return $default(_that.bounds,_that.uri,_that.pageNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PageRect bounds,  String? uri,  int? pageNumber)  $default,) {final _that = this;
switch (_that) {
case _PageLink():
return $default(_that.bounds,_that.uri,_that.pageNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PageRect bounds,  String? uri,  int? pageNumber)?  $default,) {final _that = this;
switch (_that) {
case _PageLink() when $default != null:
return $default(_that.bounds,_that.uri,_that.pageNumber);case _:
  return null;

}
}

}

/// @nodoc


class _PageLink extends PageLink {
  const _PageLink({required this.bounds, this.uri, this.pageNumber}): super._();
  

/// Clickable region in page coordinates.
@override final  PageRect bounds;
/// External URI, if this is an external link.
@override final  String? uri;
/// Resolved target page, if this is an internal link.
@override final  int? pageNumber;

/// Create a copy of PageLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageLinkCopyWith<_PageLink> get copyWith => __$PageLinkCopyWithImpl<_PageLink>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageLink&&(identical(other.bounds, bounds) || other.bounds == bounds)&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bounds,uri,pageNumber);
}

@override
String toString() {
    return 'PageLink(bounds: $bounds, uri: $uri, pageNumber: $pageNumber)';
}


}

/// @nodoc
abstract mixin class _$PageLinkCopyWith<$Res> implements $PageLinkCopyWith<$Res> {
  factory _$PageLinkCopyWith(_PageLink value, $Res Function(_PageLink) _then) = __$PageLinkCopyWithImpl;
@override @useResult
$Res call({
 PageRect bounds, String? uri, int? pageNumber
});


@override $PageRectCopyWith<$Res> get bounds;

}
/// @nodoc
class __$PageLinkCopyWithImpl<$Res>
    implements _$PageLinkCopyWith<$Res> {
  __$PageLinkCopyWithImpl(this._self, this._then);

  final _PageLink _self;
  final $Res Function(_PageLink) _then;

/// Create a copy of PageLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bounds = null,Object? uri = freezed,Object? pageNumber = freezed,}) {
  return _then(_PageLink(
bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as PageRect,uri: freezed == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String?,pageNumber: freezed == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of PageLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageRectCopyWith<$Res> get bounds {
  
  return $PageRectCopyWith<$Res>(_self.bounds, (value) {
    return _then(_self.copyWith(bounds: value));
  });
}
}

/// @nodoc
mixin _$PageRect {

/// Left edge.
 double get x0;/// Top edge.
 double get y0;/// Right edge.
 double get x1;/// Bottom edge.
 double get y1;
/// Create a copy of PageRect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageRectCopyWith<PageRect> get copyWith => _$PageRectCopyWithImpl<PageRect>(this as PageRect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PageRect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageRect&&(identical(other.x0, _this.x0) || other.x0 == _this.x0)&&(identical(other.y0, _this.y0) || other.y0 == _this.y0)&&(identical(other.x1, _this.x1) || other.x1 == _this.x1)&&(identical(other.y1, _this.y1) || other.y1 == _this.y1));
}


@override
int get hashCode {
  final _this = this as PageRect;
  return Object.hash(runtimeType,_this.x0,_this.y0,_this.x1,_this.y1);
}

@override
String toString() {
  final _this = this as PageRect;
  return 'PageRect(x0: ${_this.x0}, y0: ${_this.y0}, x1: ${_this.x1}, y1: ${_this.y1})';
}


}

/// @nodoc
abstract mixin class $PageRectCopyWith<$Res>  {
  factory $PageRectCopyWith(PageRect value, $Res Function(PageRect) _then) = _$PageRectCopyWithImpl;
@useResult
$Res call({
 double x0, double y0, double x1, double y1
});




}
/// @nodoc
class _$PageRectCopyWithImpl<$Res>
    implements $PageRectCopyWith<$Res> {
  _$PageRectCopyWithImpl(this._self, this._then);

  final PageRect _self;
  final $Res Function(PageRect) _then;

/// Create a copy of PageRect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x0 = null,Object? y0 = null,Object? x1 = null,Object? y1 = null,}) {
  return _then(PageRect(
x0: null == x0 ? _self.x0 : x0 // ignore: cast_nullable_to_non_nullable
as double,y0: null == y0 ? _self.y0 : y0 // ignore: cast_nullable_to_non_nullable
as double,x1: null == x1 ? _self.x1 : x1 // ignore: cast_nullable_to_non_nullable
as double,y1: null == y1 ? _self.y1 : y1 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PageRect].
extension PageRectPatterns on PageRect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageRect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageRect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageRect value)  $default,){
final _that = this;
switch (_that) {
case _PageRect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageRect value)?  $default,){
final _that = this;
switch (_that) {
case _PageRect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x0,  double y0,  double x1,  double y1)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageRect() when $default != null:
return $default(_that.x0,_that.y0,_that.x1,_that.y1);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x0,  double y0,  double x1,  double y1)  $default,) {final _that = this;
switch (_that) {
case _PageRect():
return $default(_that.x0,_that.y0,_that.x1,_that.y1);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x0,  double y0,  double x1,  double y1)?  $default,) {final _that = this;
switch (_that) {
case _PageRect() when $default != null:
return $default(_that.x0,_that.y0,_that.x1,_that.y1);case _:
  return null;

}
}

}

/// @nodoc


class _PageRect extends PageRect {
  const _PageRect({required this.x0, required this.y0, required this.x1, required this.y1}): super._();
  

/// Left edge.
@override final  double x0;
/// Top edge.
@override final  double y0;
/// Right edge.
@override final  double x1;
/// Bottom edge.
@override final  double y1;

/// Create a copy of PageRect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageRectCopyWith<_PageRect> get copyWith => __$PageRectCopyWithImpl<_PageRect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageRect&&(identical(other.x0, x0) || other.x0 == x0)&&(identical(other.y0, y0) || other.y0 == y0)&&(identical(other.x1, x1) || other.x1 == x1)&&(identical(other.y1, y1) || other.y1 == y1));
}


@override
int get hashCode {
    return Object.hash(runtimeType,x0,y0,x1,y1);
}

@override
String toString() {
    return 'PageRect(x0: $x0, y0: $y0, x1: $x1, y1: $y1)';
}


}

/// @nodoc
abstract mixin class _$PageRectCopyWith<$Res> implements $PageRectCopyWith<$Res> {
  factory _$PageRectCopyWith(_PageRect value, $Res Function(_PageRect) _then) = __$PageRectCopyWithImpl;
@override @useResult
$Res call({
 double x0, double y0, double x1, double y1
});




}
/// @nodoc
class __$PageRectCopyWithImpl<$Res>
    implements _$PageRectCopyWith<$Res> {
  __$PageRectCopyWithImpl(this._self, this._then);

  final _PageRect _self;
  final $Res Function(_PageRect) _then;

/// Create a copy of PageRect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x0 = null,Object? y0 = null,Object? x1 = null,Object? y1 = null,}) {
  return _then(_PageRect(
x0: null == x0 ? _self.x0 : x0 // ignore: cast_nullable_to_non_nullable
as double,y0: null == y0 ? _self.y0 : y0 // ignore: cast_nullable_to_non_nullable
as double,x1: null == x1 ? _self.x1 : x1 // ignore: cast_nullable_to_non_nullable
as double,y1: null == y1 ? _self.y1 : y1 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PaginationState {

/// Zero-based current chapter index.
 int get chapterIndex;/// Zero-based current page within the chapter.
 int get pageInChapter;/// Total pages in the current chapter.
 int get totalPagesInChapter;/// Zero-based current page across the whole document.
 int get globalPage;/// Total pages across the whole document.
 int get totalPages;/// Viewport height used for pagination, in logical pixels.
 double get viewportHeight;/// Laid-out content height per chapter index.
 Map<int, double> get chapterHeights;/// Computed page count per chapter index.
 Map<int, int> get chapterPageCounts;
/// Create a copy of PaginationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginationStateCopyWith<PaginationState> get copyWith => _$PaginationStateCopyWithImpl<PaginationState>(this as PaginationState, _$identity);

  /// Serializes this PaginationState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginationState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationState&&(identical(other.chapterIndex, _this.chapterIndex) || other.chapterIndex == _this.chapterIndex)&&(identical(other.pageInChapter, _this.pageInChapter) || other.pageInChapter == _this.pageInChapter)&&(identical(other.totalPagesInChapter, _this.totalPagesInChapter) || other.totalPagesInChapter == _this.totalPagesInChapter)&&(identical(other.globalPage, _this.globalPage) || other.globalPage == _this.globalPage)&&(identical(other.totalPages, _this.totalPages) || other.totalPages == _this.totalPages)&&(identical(other.viewportHeight, _this.viewportHeight) || other.viewportHeight == _this.viewportHeight)&&const DeepCollectionEquality().equals(other.chapterHeights, _this.chapterHeights)&&const DeepCollectionEquality().equals(other.chapterPageCounts, _this.chapterPageCounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginationState;
  return Object.hash(runtimeType,_this.chapterIndex,_this.pageInChapter,_this.totalPagesInChapter,_this.globalPage,_this.totalPages,_this.viewportHeight,const DeepCollectionEquality().hash(_this.chapterHeights),const DeepCollectionEquality().hash(_this.chapterPageCounts));
}

@override
String toString() {
  final _this = this as PaginationState;
  return 'PaginationState(chapterIndex: ${_this.chapterIndex}, pageInChapter: ${_this.pageInChapter}, totalPagesInChapter: ${_this.totalPagesInChapter}, globalPage: ${_this.globalPage}, totalPages: ${_this.totalPages}, viewportHeight: ${_this.viewportHeight}, chapterHeights: ${_this.chapterHeights}, chapterPageCounts: ${_this.chapterPageCounts})';
}


}

/// @nodoc
abstract mixin class $PaginationStateCopyWith<$Res>  {
  factory $PaginationStateCopyWith(PaginationState value, $Res Function(PaginationState) _then) = _$PaginationStateCopyWithImpl;
@useResult
$Res call({
 int chapterIndex, int pageInChapter, int totalPagesInChapter, int globalPage, int totalPages, double viewportHeight, Map<int, double> chapterHeights, Map<int, int> chapterPageCounts
});




}
/// @nodoc
class _$PaginationStateCopyWithImpl<$Res>
    implements $PaginationStateCopyWith<$Res> {
  _$PaginationStateCopyWithImpl(this._self, this._then);

  final PaginationState _self;
  final $Res Function(PaginationState) _then;

/// Create a copy of PaginationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chapterIndex = null,Object? pageInChapter = null,Object? totalPagesInChapter = null,Object? globalPage = null,Object? totalPages = null,Object? viewportHeight = null,Object? chapterHeights = null,Object? chapterPageCounts = null,}) {
  return _then(PaginationState(
chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,pageInChapter: null == pageInChapter ? _self.pageInChapter : pageInChapter // ignore: cast_nullable_to_non_nullable
as int,totalPagesInChapter: null == totalPagesInChapter ? _self.totalPagesInChapter : totalPagesInChapter // ignore: cast_nullable_to_non_nullable
as int,globalPage: null == globalPage ? _self.globalPage : globalPage // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,viewportHeight: null == viewportHeight ? _self.viewportHeight : viewportHeight // ignore: cast_nullable_to_non_nullable
as double,chapterHeights: null == chapterHeights ? _self.chapterHeights : chapterHeights // ignore: cast_nullable_to_non_nullable
as Map<int, double>,chapterPageCounts: null == chapterPageCounts ? _self.chapterPageCounts : chapterPageCounts // ignore: cast_nullable_to_non_nullable
as Map<int, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginationState].
extension PaginationStatePatterns on PaginationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginationState value)  $default,){
final _that = this;
switch (_that) {
case _PaginationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginationState value)?  $default,){
final _that = this;
switch (_that) {
case _PaginationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int chapterIndex,  int pageInChapter,  int totalPagesInChapter,  int globalPage,  int totalPages,  double viewportHeight,  Map<int, double> chapterHeights,  Map<int, int> chapterPageCounts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginationState() when $default != null:
return $default(_that.chapterIndex,_that.pageInChapter,_that.totalPagesInChapter,_that.globalPage,_that.totalPages,_that.viewportHeight,_that.chapterHeights,_that.chapterPageCounts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int chapterIndex,  int pageInChapter,  int totalPagesInChapter,  int globalPage,  int totalPages,  double viewportHeight,  Map<int, double> chapterHeights,  Map<int, int> chapterPageCounts)  $default,) {final _that = this;
switch (_that) {
case _PaginationState():
return $default(_that.chapterIndex,_that.pageInChapter,_that.totalPagesInChapter,_that.globalPage,_that.totalPages,_that.viewportHeight,_that.chapterHeights,_that.chapterPageCounts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int chapterIndex,  int pageInChapter,  int totalPagesInChapter,  int globalPage,  int totalPages,  double viewportHeight,  Map<int, double> chapterHeights,  Map<int, int> chapterPageCounts)?  $default,) {final _that = this;
switch (_that) {
case _PaginationState() when $default != null:
return $default(_that.chapterIndex,_that.pageInChapter,_that.totalPagesInChapter,_that.globalPage,_that.totalPages,_that.viewportHeight,_that.chapterHeights,_that.chapterPageCounts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginationState implements PaginationState {
  const _PaginationState({this.chapterIndex = 0, this.pageInChapter = 0, this.totalPagesInChapter = 1, this.globalPage = 0, this.totalPages = 0, this.viewportHeight = 0.0,  Map<int, double> chapterHeights = const {},  Map<int, int> chapterPageCounts = const {}}): _chapterHeights = chapterHeights,_chapterPageCounts = chapterPageCounts;
  factory _PaginationState.fromJson(Map<String, dynamic> json) => _$PaginationStateFromJson(json);

/// Zero-based current chapter index.
@override@JsonKey() final  int chapterIndex;
/// Zero-based current page within the chapter.
@override@JsonKey() final  int pageInChapter;
/// Total pages in the current chapter.
@override@JsonKey() final  int totalPagesInChapter;
/// Zero-based current page across the whole document.
@override@JsonKey() final  int globalPage;
/// Total pages across the whole document.
@override@JsonKey() final  int totalPages;
/// Viewport height used for pagination, in logical pixels.
@override@JsonKey() final  double viewportHeight;
/// Laid-out content height per chapter index.
 final  Map<int, double> _chapterHeights;
/// Laid-out content height per chapter index.
@override@JsonKey() Map<int, double> get chapterHeights {
  if (_chapterHeights is EqualUnmodifiableMapView) return _chapterHeights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_chapterHeights);
}

/// Computed page count per chapter index.
 final  Map<int, int> _chapterPageCounts;
/// Computed page count per chapter index.
@override@JsonKey() Map<int, int> get chapterPageCounts {
  if (_chapterPageCounts is EqualUnmodifiableMapView) return _chapterPageCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_chapterPageCounts);
}


/// Create a copy of PaginationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginationStateCopyWith<_PaginationState> get copyWith => __$PaginationStateCopyWithImpl<_PaginationState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginationStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginationState&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.pageInChapter, pageInChapter) || other.pageInChapter == pageInChapter)&&(identical(other.totalPagesInChapter, totalPagesInChapter) || other.totalPagesInChapter == totalPagesInChapter)&&(identical(other.globalPage, globalPage) || other.globalPage == globalPage)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.viewportHeight, viewportHeight) || other.viewportHeight == viewportHeight)&&const DeepCollectionEquality().equals(other.chapterHeights, _chapterHeights)&&const DeepCollectionEquality().equals(other.chapterPageCounts, _chapterPageCounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,chapterIndex,pageInChapter,totalPagesInChapter,globalPage,totalPages,viewportHeight,const DeepCollectionEquality().hash(_chapterHeights),const DeepCollectionEquality().hash(_chapterPageCounts));
}

@override
String toString() {
    return 'PaginationState(chapterIndex: $chapterIndex, pageInChapter: $pageInChapter, totalPagesInChapter: $totalPagesInChapter, globalPage: $globalPage, totalPages: $totalPages, viewportHeight: $viewportHeight, chapterHeights: $chapterHeights, chapterPageCounts: $chapterPageCounts)';
}


}

/// @nodoc
abstract mixin class _$PaginationStateCopyWith<$Res> implements $PaginationStateCopyWith<$Res> {
  factory _$PaginationStateCopyWith(_PaginationState value, $Res Function(_PaginationState) _then) = __$PaginationStateCopyWithImpl;
@override @useResult
$Res call({
 int chapterIndex, int pageInChapter, int totalPagesInChapter, int globalPage, int totalPages, double viewportHeight, Map<int, double> chapterHeights, Map<int, int> chapterPageCounts
});




}
/// @nodoc
class __$PaginationStateCopyWithImpl<$Res>
    implements _$PaginationStateCopyWith<$Res> {
  __$PaginationStateCopyWithImpl(this._self, this._then);

  final _PaginationState _self;
  final $Res Function(_PaginationState) _then;

/// Create a copy of PaginationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chapterIndex = null,Object? pageInChapter = null,Object? totalPagesInChapter = null,Object? globalPage = null,Object? totalPages = null,Object? viewportHeight = null,Object? chapterHeights = null,Object? chapterPageCounts = null,}) {
  return _then(_PaginationState(
chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,pageInChapter: null == pageInChapter ? _self.pageInChapter : pageInChapter // ignore: cast_nullable_to_non_nullable
as int,totalPagesInChapter: null == totalPagesInChapter ? _self.totalPagesInChapter : totalPagesInChapter // ignore: cast_nullable_to_non_nullable
as int,globalPage: null == globalPage ? _self.globalPage : globalPage // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,viewportHeight: null == viewportHeight ? _self.viewportHeight : viewportHeight // ignore: cast_nullable_to_non_nullable
as double,chapterHeights: null == chapterHeights ? _self._chapterHeights : chapterHeights // ignore: cast_nullable_to_non_nullable
as Map<int, double>,chapterPageCounts: null == chapterPageCounts ? _self._chapterPageCounts : chapterPageCounts // ignore: cast_nullable_to_non_nullable
as Map<int, int>,
  ));
}


}


/// @nodoc
mixin _$ReadingAnchor {

/// Zero-based chapter/section index.
 int get chapterIndex;/// Reading progress within the chapter, in `[0, 1]`.
 double get progressionInChapter;
/// Create a copy of ReadingAnchor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingAnchorCopyWith<ReadingAnchor> get copyWith => _$ReadingAnchorCopyWithImpl<ReadingAnchor>(this as ReadingAnchor, _$identity);

  /// Serializes this ReadingAnchor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReadingAnchor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingAnchor&&(identical(other.chapterIndex, _this.chapterIndex) || other.chapterIndex == _this.chapterIndex)&&(identical(other.progressionInChapter, _this.progressionInChapter) || other.progressionInChapter == _this.progressionInChapter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReadingAnchor;
  return Object.hash(runtimeType,_this.chapterIndex,_this.progressionInChapter);
}

@override
String toString() {
  final _this = this as ReadingAnchor;
  return 'ReadingAnchor(chapterIndex: ${_this.chapterIndex}, progressionInChapter: ${_this.progressionInChapter})';
}


}

/// @nodoc
abstract mixin class $ReadingAnchorCopyWith<$Res>  {
  factory $ReadingAnchorCopyWith(ReadingAnchor value, $Res Function(ReadingAnchor) _then) = _$ReadingAnchorCopyWithImpl;
@useResult
$Res call({
 int chapterIndex, double progressionInChapter
});




}
/// @nodoc
class _$ReadingAnchorCopyWithImpl<$Res>
    implements $ReadingAnchorCopyWith<$Res> {
  _$ReadingAnchorCopyWithImpl(this._self, this._then);

  final ReadingAnchor _self;
  final $Res Function(ReadingAnchor) _then;

/// Create a copy of ReadingAnchor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chapterIndex = null,Object? progressionInChapter = null,}) {
  return _then(ReadingAnchor(
chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,progressionInChapter: null == progressionInChapter ? _self.progressionInChapter : progressionInChapter // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingAnchor].
extension ReadingAnchorPatterns on ReadingAnchor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingAnchor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingAnchor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingAnchor value)  $default,){
final _that = this;
switch (_that) {
case _ReadingAnchor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingAnchor value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingAnchor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int chapterIndex,  double progressionInChapter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingAnchor() when $default != null:
return $default(_that.chapterIndex,_that.progressionInChapter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int chapterIndex,  double progressionInChapter)  $default,) {final _that = this;
switch (_that) {
case _ReadingAnchor():
return $default(_that.chapterIndex,_that.progressionInChapter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int chapterIndex,  double progressionInChapter)?  $default,) {final _that = this;
switch (_that) {
case _ReadingAnchor() when $default != null:
return $default(_that.chapterIndex,_that.progressionInChapter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadingAnchor implements ReadingAnchor {
  const _ReadingAnchor({required this.chapterIndex, required this.progressionInChapter});
  factory _ReadingAnchor.fromJson(Map<String, dynamic> json) => _$ReadingAnchorFromJson(json);

/// Zero-based chapter/section index.
@override final  int chapterIndex;
/// Reading progress within the chapter, in `[0, 1]`.
@override final  double progressionInChapter;

/// Create a copy of ReadingAnchor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingAnchorCopyWith<_ReadingAnchor> get copyWith => __$ReadingAnchorCopyWithImpl<_ReadingAnchor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingAnchorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingAnchor&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.progressionInChapter, progressionInChapter) || other.progressionInChapter == progressionInChapter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,chapterIndex,progressionInChapter);
}

@override
String toString() {
    return 'ReadingAnchor(chapterIndex: $chapterIndex, progressionInChapter: $progressionInChapter)';
}


}

/// @nodoc
abstract mixin class _$ReadingAnchorCopyWith<$Res> implements $ReadingAnchorCopyWith<$Res> {
  factory _$ReadingAnchorCopyWith(_ReadingAnchor value, $Res Function(_ReadingAnchor) _then) = __$ReadingAnchorCopyWithImpl;
@override @useResult
$Res call({
 int chapterIndex, double progressionInChapter
});




}
/// @nodoc
class __$ReadingAnchorCopyWithImpl<$Res>
    implements _$ReadingAnchorCopyWith<$Res> {
  __$ReadingAnchorCopyWithImpl(this._self, this._then);

  final _ReadingAnchor _self;
  final $Res Function(_ReadingAnchor) _then;

/// Create a copy of ReadingAnchor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chapterIndex = null,Object? progressionInChapter = null,}) {
  return _then(_ReadingAnchor(
chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,progressionInChapter: null == progressionInChapter ? _self.progressionInChapter : progressionInChapter // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$RenderedPage {

/// Pixel width of the rendered image.
 int get width;/// Pixel height of the rendered image.
 int get height;/// Bytes per row (may exceed `width * components` due to padding).
 int get stride;/// Number of color components per pixel (4 = RGBA).
 int get components;/// Raw pixel data, `stride * height` bytes.
 Uint8List get pixels;
/// Create a copy of RenderedPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RenderedPageCopyWith<RenderedPage> get copyWith => _$RenderedPageCopyWithImpl<RenderedPage>(this as RenderedPage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RenderedPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RenderedPage&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.stride, _this.stride) || other.stride == _this.stride)&&(identical(other.components, _this.components) || other.components == _this.components)&&const DeepCollectionEquality().equals(other.pixels, _this.pixels));
}


@override
int get hashCode {
  final _this = this as RenderedPage;
  return Object.hash(runtimeType,_this.width,_this.height,_this.stride,_this.components,const DeepCollectionEquality().hash(_this.pixels));
}

@override
String toString() {
  final _this = this as RenderedPage;
  return 'RenderedPage(width: ${_this.width}, height: ${_this.height}, stride: ${_this.stride}, components: ${_this.components}, pixels: ${_this.pixels})';
}


}

/// @nodoc
abstract mixin class $RenderedPageCopyWith<$Res>  {
  factory $RenderedPageCopyWith(RenderedPage value, $Res Function(RenderedPage) _then) = _$RenderedPageCopyWithImpl;
@useResult
$Res call({
 int width, int height, int stride, int components, Uint8List pixels
});




}
/// @nodoc
class _$RenderedPageCopyWithImpl<$Res>
    implements $RenderedPageCopyWith<$Res> {
  _$RenderedPageCopyWithImpl(this._self, this._then);

  final RenderedPage _self;
  final $Res Function(RenderedPage) _then;

/// Create a copy of RenderedPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? width = null,Object? height = null,Object? stride = null,Object? components = null,Object? pixels = null,}) {
  return _then(RenderedPage(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,stride: null == stride ? _self.stride : stride // ignore: cast_nullable_to_non_nullable
as int,components: null == components ? _self.components : components // ignore: cast_nullable_to_non_nullable
as int,pixels: null == pixels ? _self.pixels : pixels // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}

}


/// Adds pattern-matching-related methods to [RenderedPage].
extension RenderedPagePatterns on RenderedPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RenderedPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RenderedPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RenderedPage value)  $default,){
final _that = this;
switch (_that) {
case _RenderedPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RenderedPage value)?  $default,){
final _that = this;
switch (_that) {
case _RenderedPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int width,  int height,  int stride,  int components,  Uint8List pixels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RenderedPage() when $default != null:
return $default(_that.width,_that.height,_that.stride,_that.components,_that.pixels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int width,  int height,  int stride,  int components,  Uint8List pixels)  $default,) {final _that = this;
switch (_that) {
case _RenderedPage():
return $default(_that.width,_that.height,_that.stride,_that.components,_that.pixels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int width,  int height,  int stride,  int components,  Uint8List pixels)?  $default,) {final _that = this;
switch (_that) {
case _RenderedPage() when $default != null:
return $default(_that.width,_that.height,_that.stride,_that.components,_that.pixels);case _:
  return null;

}
}

}

/// @nodoc


class _RenderedPage implements RenderedPage {
  const _RenderedPage({required this.width, required this.height, required this.stride, required this.components, required this.pixels});
  

/// Pixel width of the rendered image.
@override final  int width;
/// Pixel height of the rendered image.
@override final  int height;
/// Bytes per row (may exceed `width * components` due to padding).
@override final  int stride;
/// Number of color components per pixel (4 = RGBA).
@override final  int components;
/// Raw pixel data, `stride * height` bytes.
@override final  Uint8List pixels;

/// Create a copy of RenderedPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RenderedPageCopyWith<_RenderedPage> get copyWith => __$RenderedPageCopyWithImpl<_RenderedPage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RenderedPage&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.stride, stride) || other.stride == stride)&&(identical(other.components, components) || other.components == components)&&const DeepCollectionEquality().equals(other.pixels, pixels));
}


@override
int get hashCode {
    return Object.hash(runtimeType,width,height,stride,components,const DeepCollectionEquality().hash(pixels));
}

@override
String toString() {
    return 'RenderedPage(width: $width, height: $height, stride: $stride, components: $components, pixels: $pixels)';
}


}

/// @nodoc
abstract mixin class _$RenderedPageCopyWith<$Res> implements $RenderedPageCopyWith<$Res> {
  factory _$RenderedPageCopyWith(_RenderedPage value, $Res Function(_RenderedPage) _then) = __$RenderedPageCopyWithImpl;
@override @useResult
$Res call({
 int width, int height, int stride, int components, Uint8List pixels
});




}
/// @nodoc
class __$RenderedPageCopyWithImpl<$Res>
    implements _$RenderedPageCopyWith<$Res> {
  __$RenderedPageCopyWithImpl(this._self, this._then);

  final _RenderedPage _self;
  final $Res Function(_RenderedPage) _then;

/// Create a copy of RenderedPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? width = null,Object? height = null,Object? stride = null,Object? components = null,Object? pixels = null,}) {
  return _then(_RenderedPage(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,stride: null == stride ? _self.stride : stride // ignore: cast_nullable_to_non_nullable
as int,components: null == components ? _self.components : components // ignore: cast_nullable_to_non_nullable
as int,pixels: null == pixels ? _self.pixels : pixels // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc
mixin _$SearchHit {

 double get ulX; double get ulY; double get urX; double get urY; double get lrX; double get lrY; double get llX; double get llY;
/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchHitCopyWith<SearchHit> get copyWith => _$SearchHitCopyWithImpl<SearchHit>(this as SearchHit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchHit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchHit&&(identical(other.ulX, _this.ulX) || other.ulX == _this.ulX)&&(identical(other.ulY, _this.ulY) || other.ulY == _this.ulY)&&(identical(other.urX, _this.urX) || other.urX == _this.urX)&&(identical(other.urY, _this.urY) || other.urY == _this.urY)&&(identical(other.lrX, _this.lrX) || other.lrX == _this.lrX)&&(identical(other.lrY, _this.lrY) || other.lrY == _this.lrY)&&(identical(other.llX, _this.llX) || other.llX == _this.llX)&&(identical(other.llY, _this.llY) || other.llY == _this.llY));
}


@override
int get hashCode {
  final _this = this as SearchHit;
  return Object.hash(runtimeType,_this.ulX,_this.ulY,_this.urX,_this.urY,_this.lrX,_this.lrY,_this.llX,_this.llY);
}

@override
String toString() {
  final _this = this as SearchHit;
  return 'SearchHit(ulX: ${_this.ulX}, ulY: ${_this.ulY}, urX: ${_this.urX}, urY: ${_this.urY}, lrX: ${_this.lrX}, lrY: ${_this.lrY}, llX: ${_this.llX}, llY: ${_this.llY})';
}


}

/// @nodoc
abstract mixin class $SearchHitCopyWith<$Res>  {
  factory $SearchHitCopyWith(SearchHit value, $Res Function(SearchHit) _then) = _$SearchHitCopyWithImpl;
@useResult
$Res call({
 double ulX, double ulY, double urX, double urY, double lrX, double lrY, double llX, double llY
});




}
/// @nodoc
class _$SearchHitCopyWithImpl<$Res>
    implements $SearchHitCopyWith<$Res> {
  _$SearchHitCopyWithImpl(this._self, this._then);

  final SearchHit _self;
  final $Res Function(SearchHit) _then;

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ulX = null,Object? ulY = null,Object? urX = null,Object? urY = null,Object? lrX = null,Object? lrY = null,Object? llX = null,Object? llY = null,}) {
  return _then(SearchHit(
ulX: null == ulX ? _self.ulX : ulX // ignore: cast_nullable_to_non_nullable
as double,ulY: null == ulY ? _self.ulY : ulY // ignore: cast_nullable_to_non_nullable
as double,urX: null == urX ? _self.urX : urX // ignore: cast_nullable_to_non_nullable
as double,urY: null == urY ? _self.urY : urY // ignore: cast_nullable_to_non_nullable
as double,lrX: null == lrX ? _self.lrX : lrX // ignore: cast_nullable_to_non_nullable
as double,lrY: null == lrY ? _self.lrY : lrY // ignore: cast_nullable_to_non_nullable
as double,llX: null == llX ? _self.llX : llX // ignore: cast_nullable_to_non_nullable
as double,llY: null == llY ? _self.llY : llY // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchHit].
extension SearchHitPatterns on SearchHit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchHit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchHit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchHit value)  $default,){
final _that = this;
switch (_that) {
case _SearchHit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchHit value)?  $default,){
final _that = this;
switch (_that) {
case _SearchHit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double ulX,  double ulY,  double urX,  double urY,  double lrX,  double lrY,  double llX,  double llY)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchHit() when $default != null:
return $default(_that.ulX,_that.ulY,_that.urX,_that.urY,_that.lrX,_that.lrY,_that.llX,_that.llY);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double ulX,  double ulY,  double urX,  double urY,  double lrX,  double lrY,  double llX,  double llY)  $default,) {final _that = this;
switch (_that) {
case _SearchHit():
return $default(_that.ulX,_that.ulY,_that.urX,_that.urY,_that.lrX,_that.lrY,_that.llX,_that.llY);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double ulX,  double ulY,  double urX,  double urY,  double lrX,  double lrY,  double llX,  double llY)?  $default,) {final _that = this;
switch (_that) {
case _SearchHit() when $default != null:
return $default(_that.ulX,_that.ulY,_that.urX,_that.urY,_that.lrX,_that.lrY,_that.llX,_that.llY);case _:
  return null;

}
}

}

/// @nodoc


class _SearchHit implements SearchHit {
  const _SearchHit({required this.ulX, required this.ulY, required this.urX, required this.urY, required this.lrX, required this.lrY, required this.llX, required this.llY});
  

@override final  double ulX;
@override final  double ulY;
@override final  double urX;
@override final  double urY;
@override final  double lrX;
@override final  double lrY;
@override final  double llX;
@override final  double llY;

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchHitCopyWith<_SearchHit> get copyWith => __$SearchHitCopyWithImpl<_SearchHit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchHit&&(identical(other.ulX, ulX) || other.ulX == ulX)&&(identical(other.ulY, ulY) || other.ulY == ulY)&&(identical(other.urX, urX) || other.urX == urX)&&(identical(other.urY, urY) || other.urY == urY)&&(identical(other.lrX, lrX) || other.lrX == lrX)&&(identical(other.lrY, lrY) || other.lrY == lrY)&&(identical(other.llX, llX) || other.llX == llX)&&(identical(other.llY, llY) || other.llY == llY));
}


@override
int get hashCode {
    return Object.hash(runtimeType,ulX,ulY,urX,urY,lrX,lrY,llX,llY);
}

@override
String toString() {
    return 'SearchHit(ulX: $ulX, ulY: $ulY, urX: $urX, urY: $urY, lrX: $lrX, lrY: $lrY, llX: $llX, llY: $llY)';
}


}

/// @nodoc
abstract mixin class _$SearchHitCopyWith<$Res> implements $SearchHitCopyWith<$Res> {
  factory _$SearchHitCopyWith(_SearchHit value, $Res Function(_SearchHit) _then) = __$SearchHitCopyWithImpl;
@override @useResult
$Res call({
 double ulX, double ulY, double urX, double urY, double lrX, double lrY, double llX, double llY
});




}
/// @nodoc
class __$SearchHitCopyWithImpl<$Res>
    implements _$SearchHitCopyWith<$Res> {
  __$SearchHitCopyWithImpl(this._self, this._then);

  final _SearchHit _self;
  final $Res Function(_SearchHit) _then;

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ulX = null,Object? ulY = null,Object? urX = null,Object? urY = null,Object? lrX = null,Object? lrY = null,Object? llX = null,Object? llY = null,}) {
  return _then(_SearchHit(
ulX: null == ulX ? _self.ulX : ulX // ignore: cast_nullable_to_non_nullable
as double,ulY: null == ulY ? _self.ulY : ulY // ignore: cast_nullable_to_non_nullable
as double,urX: null == urX ? _self.urX : urX // ignore: cast_nullable_to_non_nullable
as double,urY: null == urY ? _self.urY : urY // ignore: cast_nullable_to_non_nullable
as double,lrX: null == lrX ? _self.lrX : lrX // ignore: cast_nullable_to_non_nullable
as double,lrY: null == lrY ? _self.lrY : lrY // ignore: cast_nullable_to_non_nullable
as double,llX: null == llX ? _self.llX : llX // ignore: cast_nullable_to_non_nullable
as double,llY: null == llY ? _self.llY : llY // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$TransformContext {

/// The HTML or text content to be transformed.
 String get content;/// BCP-47 language tag (e.g. 'en', 'ru', 'zh-Hans', 'ja').
 String? get language;/// Whether the reading layout is vertical (top-to-bottom, right-to-left).
 bool get vertical;/// Whether to replace and adapt quotation marks.
 bool get replaceQuotationMarks;/// Variant translation for Chinese text: 's2t' (Simplified to Traditional),
/// 't2s' (Traditional to Simplified), or null.
 String? get convertChineseVariant;/// Whether the user layout override is enabled.
 bool get overrideLayout;/// Optional extra parameters for specialized transformers.
 Map<String, dynamic> get extra;
/// Create a copy of TransformContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransformContextCopyWith<TransformContext> get copyWith => _$TransformContextCopyWithImpl<TransformContext>(this as TransformContext, _$identity);

  /// Serializes this TransformContext to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TransformContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransformContext&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.vertical, _this.vertical) || other.vertical == _this.vertical)&&(identical(other.replaceQuotationMarks, _this.replaceQuotationMarks) || other.replaceQuotationMarks == _this.replaceQuotationMarks)&&(identical(other.convertChineseVariant, _this.convertChineseVariant) || other.convertChineseVariant == _this.convertChineseVariant)&&(identical(other.overrideLayout, _this.overrideLayout) || other.overrideLayout == _this.overrideLayout)&&const DeepCollectionEquality().equals(other.extra, _this.extra));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TransformContext;
  return Object.hash(runtimeType,_this.content,_this.language,_this.vertical,_this.replaceQuotationMarks,_this.convertChineseVariant,_this.overrideLayout,const DeepCollectionEquality().hash(_this.extra));
}

@override
String toString() {
  final _this = this as TransformContext;
  return 'TransformContext(content: ${_this.content}, language: ${_this.language}, vertical: ${_this.vertical}, replaceQuotationMarks: ${_this.replaceQuotationMarks}, convertChineseVariant: ${_this.convertChineseVariant}, overrideLayout: ${_this.overrideLayout}, extra: ${_this.extra})';
}


}

/// @nodoc
abstract mixin class $TransformContextCopyWith<$Res>  {
  factory $TransformContextCopyWith(TransformContext value, $Res Function(TransformContext) _then) = _$TransformContextCopyWithImpl;
@useResult
$Res call({
 String content, String? language, bool vertical, bool replaceQuotationMarks, String? convertChineseVariant, bool overrideLayout, Map<String, dynamic> extra
});




}
/// @nodoc
class _$TransformContextCopyWithImpl<$Res>
    implements $TransformContextCopyWith<$Res> {
  _$TransformContextCopyWithImpl(this._self, this._then);

  final TransformContext _self;
  final $Res Function(TransformContext) _then;

/// Create a copy of TransformContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? language = freezed,Object? vertical = null,Object? replaceQuotationMarks = null,Object? convertChineseVariant = freezed,Object? overrideLayout = null,Object? extra = null,}) {
  return _then(TransformContext(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as bool,replaceQuotationMarks: null == replaceQuotationMarks ? _self.replaceQuotationMarks : replaceQuotationMarks // ignore: cast_nullable_to_non_nullable
as bool,convertChineseVariant: freezed == convertChineseVariant ? _self.convertChineseVariant : convertChineseVariant // ignore: cast_nullable_to_non_nullable
as String?,overrideLayout: null == overrideLayout ? _self.overrideLayout : overrideLayout // ignore: cast_nullable_to_non_nullable
as bool,extra: null == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [TransformContext].
extension TransformContextPatterns on TransformContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransformContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransformContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransformContext value)  $default,){
final _that = this;
switch (_that) {
case _TransformContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransformContext value)?  $default,){
final _that = this;
switch (_that) {
case _TransformContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content,  String? language,  bool vertical,  bool replaceQuotationMarks,  String? convertChineseVariant,  bool overrideLayout,  Map<String, dynamic> extra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransformContext() when $default != null:
return $default(_that.content,_that.language,_that.vertical,_that.replaceQuotationMarks,_that.convertChineseVariant,_that.overrideLayout,_that.extra);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content,  String? language,  bool vertical,  bool replaceQuotationMarks,  String? convertChineseVariant,  bool overrideLayout,  Map<String, dynamic> extra)  $default,) {final _that = this;
switch (_that) {
case _TransformContext():
return $default(_that.content,_that.language,_that.vertical,_that.replaceQuotationMarks,_that.convertChineseVariant,_that.overrideLayout,_that.extra);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content,  String? language,  bool vertical,  bool replaceQuotationMarks,  String? convertChineseVariant,  bool overrideLayout,  Map<String, dynamic> extra)?  $default,) {final _that = this;
switch (_that) {
case _TransformContext() when $default != null:
return $default(_that.content,_that.language,_that.vertical,_that.replaceQuotationMarks,_that.convertChineseVariant,_that.overrideLayout,_that.extra);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransformContext implements TransformContext {
  const _TransformContext({required this.content, this.language, this.vertical = false, this.replaceQuotationMarks = false, this.convertChineseVariant, this.overrideLayout = false,  Map<String, dynamic> extra = const <String, dynamic>{}}): _extra = extra;
  factory _TransformContext.fromJson(Map<String, dynamic> json) => _$TransformContextFromJson(json);

/// The HTML or text content to be transformed.
@override final  String content;
/// BCP-47 language tag (e.g. 'en', 'ru', 'zh-Hans', 'ja').
@override final  String? language;
/// Whether the reading layout is vertical (top-to-bottom, right-to-left).
@override@JsonKey() final  bool vertical;
/// Whether to replace and adapt quotation marks.
@override@JsonKey() final  bool replaceQuotationMarks;
/// Variant translation for Chinese text: 's2t' (Simplified to Traditional),
/// 't2s' (Traditional to Simplified), or null.
@override final  String? convertChineseVariant;
/// Whether the user layout override is enabled.
@override@JsonKey() final  bool overrideLayout;
/// Optional extra parameters for specialized transformers.
 final  Map<String, dynamic> _extra;
/// Optional extra parameters for specialized transformers.
@override@JsonKey() Map<String, dynamic> get extra {
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extra);
}


/// Create a copy of TransformContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransformContextCopyWith<_TransformContext> get copyWith => __$TransformContextCopyWithImpl<_TransformContext>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransformContextToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransformContext&&(identical(other.content, content) || other.content == content)&&(identical(other.language, language) || other.language == language)&&(identical(other.vertical, vertical) || other.vertical == vertical)&&(identical(other.replaceQuotationMarks, replaceQuotationMarks) || other.replaceQuotationMarks == replaceQuotationMarks)&&(identical(other.convertChineseVariant, convertChineseVariant) || other.convertChineseVariant == convertChineseVariant)&&(identical(other.overrideLayout, overrideLayout) || other.overrideLayout == overrideLayout)&&const DeepCollectionEquality().equals(other.extra, _extra));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,content,language,vertical,replaceQuotationMarks,convertChineseVariant,overrideLayout,const DeepCollectionEquality().hash(_extra));
}

@override
String toString() {
    return 'TransformContext(content: $content, language: $language, vertical: $vertical, replaceQuotationMarks: $replaceQuotationMarks, convertChineseVariant: $convertChineseVariant, overrideLayout: $overrideLayout, extra: $extra)';
}


}

/// @nodoc
abstract mixin class _$TransformContextCopyWith<$Res> implements $TransformContextCopyWith<$Res> {
  factory _$TransformContextCopyWith(_TransformContext value, $Res Function(_TransformContext) _then) = __$TransformContextCopyWithImpl;
@override @useResult
$Res call({
 String content, String? language, bool vertical, bool replaceQuotationMarks, String? convertChineseVariant, bool overrideLayout, Map<String, dynamic> extra
});




}
/// @nodoc
class __$TransformContextCopyWithImpl<$Res>
    implements _$TransformContextCopyWith<$Res> {
  __$TransformContextCopyWithImpl(this._self, this._then);

  final _TransformContext _self;
  final $Res Function(_TransformContext) _then;

/// Create a copy of TransformContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? language = freezed,Object? vertical = null,Object? replaceQuotationMarks = null,Object? convertChineseVariant = freezed,Object? overrideLayout = null,Object? extra = null,}) {
  return _then(_TransformContext(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as bool,replaceQuotationMarks: null == replaceQuotationMarks ? _self.replaceQuotationMarks : replaceQuotationMarks // ignore: cast_nullable_to_non_nullable
as bool,convertChineseVariant: freezed == convertChineseVariant ? _self.convertChineseVariant : convertChineseVariant // ignore: cast_nullable_to_non_nullable
as String?,overrideLayout: null == overrideLayout ? _self.overrideLayout : overrideLayout // ignore: cast_nullable_to_non_nullable
as bool,extra: null == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$TtsWordSpan {

/// The raw word or token string.
 String get word;/// Absolute character index start bound within the parent chunk text.
 int get startOffset;/// Absolute character index end bound within the parent chunk text.
 int get endOffset;
/// Create a copy of TtsWordSpan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TtsWordSpanCopyWith<TtsWordSpan> get copyWith => _$TtsWordSpanCopyWithImpl<TtsWordSpan>(this as TtsWordSpan, _$identity);

  /// Serializes this TtsWordSpan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TtsWordSpan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TtsWordSpan&&(identical(other.word, _this.word) || other.word == _this.word)&&(identical(other.startOffset, _this.startOffset) || other.startOffset == _this.startOffset)&&(identical(other.endOffset, _this.endOffset) || other.endOffset == _this.endOffset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TtsWordSpan;
  return Object.hash(runtimeType,_this.word,_this.startOffset,_this.endOffset);
}

@override
String toString() {
  final _this = this as TtsWordSpan;
  return 'TtsWordSpan(word: ${_this.word}, startOffset: ${_this.startOffset}, endOffset: ${_this.endOffset})';
}


}

/// @nodoc
abstract mixin class $TtsWordSpanCopyWith<$Res>  {
  factory $TtsWordSpanCopyWith(TtsWordSpan value, $Res Function(TtsWordSpan) _then) = _$TtsWordSpanCopyWithImpl;
@useResult
$Res call({
 String word, int startOffset, int endOffset
});




}
/// @nodoc
class _$TtsWordSpanCopyWithImpl<$Res>
    implements $TtsWordSpanCopyWith<$Res> {
  _$TtsWordSpanCopyWithImpl(this._self, this._then);

  final TtsWordSpan _self;
  final $Res Function(TtsWordSpan) _then;

/// Create a copy of TtsWordSpan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? word = null,Object? startOffset = null,Object? endOffset = null,}) {
  return _then(TtsWordSpan(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TtsWordSpan].
extension TtsWordSpanPatterns on TtsWordSpan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TtsWordSpan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TtsWordSpan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TtsWordSpan value)  $default,){
final _that = this;
switch (_that) {
case _TtsWordSpan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TtsWordSpan value)?  $default,){
final _that = this;
switch (_that) {
case _TtsWordSpan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String word,  int startOffset,  int endOffset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TtsWordSpan() when $default != null:
return $default(_that.word,_that.startOffset,_that.endOffset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String word,  int startOffset,  int endOffset)  $default,) {final _that = this;
switch (_that) {
case _TtsWordSpan():
return $default(_that.word,_that.startOffset,_that.endOffset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String word,  int startOffset,  int endOffset)?  $default,) {final _that = this;
switch (_that) {
case _TtsWordSpan() when $default != null:
return $default(_that.word,_that.startOffset,_that.endOffset);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TtsWordSpan implements TtsWordSpan {
  const _TtsWordSpan({required this.word, required this.startOffset, required this.endOffset});
  factory _TtsWordSpan.fromJson(Map<String, dynamic> json) => _$TtsWordSpanFromJson(json);

/// The raw word or token string.
@override final  String word;
/// Absolute character index start bound within the parent chunk text.
@override final  int startOffset;
/// Absolute character index end bound within the parent chunk text.
@override final  int endOffset;

/// Create a copy of TtsWordSpan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TtsWordSpanCopyWith<_TtsWordSpan> get copyWith => __$TtsWordSpanCopyWithImpl<_TtsWordSpan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TtsWordSpanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsWordSpan&&(identical(other.word, word) || other.word == word)&&(identical(other.startOffset, startOffset) || other.startOffset == startOffset)&&(identical(other.endOffset, endOffset) || other.endOffset == endOffset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,word,startOffset,endOffset);
}

@override
String toString() {
    return 'TtsWordSpan(word: $word, startOffset: $startOffset, endOffset: $endOffset)';
}


}

/// @nodoc
abstract mixin class _$TtsWordSpanCopyWith<$Res> implements $TtsWordSpanCopyWith<$Res> {
  factory _$TtsWordSpanCopyWith(_TtsWordSpan value, $Res Function(_TtsWordSpan) _then) = __$TtsWordSpanCopyWithImpl;
@override @useResult
$Res call({
 String word, int startOffset, int endOffset
});




}
/// @nodoc
class __$TtsWordSpanCopyWithImpl<$Res>
    implements _$TtsWordSpanCopyWith<$Res> {
  __$TtsWordSpanCopyWithImpl(this._self, this._then);

  final _TtsWordSpan _self;
  final $Res Function(_TtsWordSpan) _then;

/// Create a copy of TtsWordSpan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? word = null,Object? startOffset = null,Object? endOffset = null,}) {
  return _then(_TtsWordSpan(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TtsChunk {

/// Trimmed display text representing the sentence or clause.
 String get text;/// Absolute character index start bound in the source text
/// (trimmed to non-whitespace).
 int get startOffset;/// Absolute character index end bound in the source text
/// (trimmed to non-whitespace).
 int get endOffset;/// Text sanitized and normalized for speech synthesis (e.g. stripped of
/// footnote citations, soft hyphens, and decorative glyphs).
///
/// Falls back to [text] at read time via [speechContent].
 String? get spokenText;/// Absolute character index start bound in the source text including
/// leading whitespace.
 int? get rawStartOffset;/// Absolute character index end bound in the source text including
/// trailing whitespace.
 int? get rawEndOffset;/// Whether this chunk marks the terminal sentence/clause of a paragraph.
 bool get isParagraphEnd;/// 0-based paragraph index within the page or document section.
 int get paragraphIndex;/// Optional word-level spans for progressive karaoke-style highlighting.
///
/// Explicit encoders keep the nested [TtsWordSpan] objects flattened into
/// plain maps so the payload survives `SendPort` hops between isolates.
@JsonKey(toJson: _encodeWordSpans, fromJson: _decodeWordSpans) List<TtsWordSpan> get words;/// BCP-47 language tag inferred from the chunk's dominant script
/// (e.g. `'en'`, `'ja'`, `'zh'`, `'ru'`).
///
/// Lets the TTS engine pick the right voice/pronunciation for
/// mixed-language content.
 String get language;
/// Create a copy of TtsChunk
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TtsChunkCopyWith<TtsChunk> get copyWith => _$TtsChunkCopyWithImpl<TtsChunk>(this as TtsChunk, _$identity);

  /// Serializes this TtsChunk to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TtsChunk;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TtsChunk&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.startOffset, _this.startOffset) || other.startOffset == _this.startOffset)&&(identical(other.endOffset, _this.endOffset) || other.endOffset == _this.endOffset)&&(identical(other.spokenText, _this.spokenText) || other.spokenText == _this.spokenText)&&(identical(other.rawStartOffset, _this.rawStartOffset) || other.rawStartOffset == _this.rawStartOffset)&&(identical(other.rawEndOffset, _this.rawEndOffset) || other.rawEndOffset == _this.rawEndOffset)&&(identical(other.isParagraphEnd, _this.isParagraphEnd) || other.isParagraphEnd == _this.isParagraphEnd)&&(identical(other.paragraphIndex, _this.paragraphIndex) || other.paragraphIndex == _this.paragraphIndex)&&const DeepCollectionEquality().equals(other.words, _this.words)&&(identical(other.language, _this.language) || other.language == _this.language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TtsChunk;
  return Object.hash(runtimeType,_this.text,_this.startOffset,_this.endOffset,_this.spokenText,_this.rawStartOffset,_this.rawEndOffset,_this.isParagraphEnd,_this.paragraphIndex,const DeepCollectionEquality().hash(_this.words),_this.language);
}

@override
String toString() {
  final _this = this as TtsChunk;
  return 'TtsChunk(text: ${_this.text}, startOffset: ${_this.startOffset}, endOffset: ${_this.endOffset}, spokenText: ${_this.spokenText}, rawStartOffset: ${_this.rawStartOffset}, rawEndOffset: ${_this.rawEndOffset}, isParagraphEnd: ${_this.isParagraphEnd}, paragraphIndex: ${_this.paragraphIndex}, words: ${_this.words}, language: ${_this.language})';
}


}

/// @nodoc
abstract mixin class $TtsChunkCopyWith<$Res>  {
  factory $TtsChunkCopyWith(TtsChunk value, $Res Function(TtsChunk) _then) = _$TtsChunkCopyWithImpl;
@useResult
$Res call({
 String text, int startOffset, int endOffset, String? spokenText, int? rawStartOffset, int? rawEndOffset, bool isParagraphEnd, int paragraphIndex,@JsonKey(toJson: _encodeWordSpans, fromJson: _decodeWordSpans) List<TtsWordSpan> words, String language
});




}
/// @nodoc
class _$TtsChunkCopyWithImpl<$Res>
    implements $TtsChunkCopyWith<$Res> {
  _$TtsChunkCopyWithImpl(this._self, this._then);

  final TtsChunk _self;
  final $Res Function(TtsChunk) _then;

/// Create a copy of TtsChunk
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? startOffset = null,Object? endOffset = null,Object? spokenText = freezed,Object? rawStartOffset = freezed,Object? rawEndOffset = freezed,Object? isParagraphEnd = null,Object? paragraphIndex = null,Object? words = null,Object? language = null,}) {
  return _then(TtsChunk(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,spokenText: freezed == spokenText ? _self.spokenText : spokenText // ignore: cast_nullable_to_non_nullable
as String?,rawStartOffset: freezed == rawStartOffset ? _self.rawStartOffset : rawStartOffset // ignore: cast_nullable_to_non_nullable
as int?,rawEndOffset: freezed == rawEndOffset ? _self.rawEndOffset : rawEndOffset // ignore: cast_nullable_to_non_nullable
as int?,isParagraphEnd: null == isParagraphEnd ? _self.isParagraphEnd : isParagraphEnd // ignore: cast_nullable_to_non_nullable
as bool,paragraphIndex: null == paragraphIndex ? _self.paragraphIndex : paragraphIndex // ignore: cast_nullable_to_non_nullable
as int,words: null == words ? _self.words : words // ignore: cast_nullable_to_non_nullable
as List<TtsWordSpan>,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TtsChunk].
extension TtsChunkPatterns on TtsChunk {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TtsChunk value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TtsChunk() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TtsChunk value)  $default,){
final _that = this;
switch (_that) {
case _TtsChunk():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TtsChunk value)?  $default,){
final _that = this;
switch (_that) {
case _TtsChunk() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  int startOffset,  int endOffset,  String? spokenText,  int? rawStartOffset,  int? rawEndOffset,  bool isParagraphEnd,  int paragraphIndex, @JsonKey(toJson: _encodeWordSpans, fromJson: _decodeWordSpans)  List<TtsWordSpan> words,  String language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TtsChunk() when $default != null:
return $default(_that.text,_that.startOffset,_that.endOffset,_that.spokenText,_that.rawStartOffset,_that.rawEndOffset,_that.isParagraphEnd,_that.paragraphIndex,_that.words,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  int startOffset,  int endOffset,  String? spokenText,  int? rawStartOffset,  int? rawEndOffset,  bool isParagraphEnd,  int paragraphIndex, @JsonKey(toJson: _encodeWordSpans, fromJson: _decodeWordSpans)  List<TtsWordSpan> words,  String language)  $default,) {final _that = this;
switch (_that) {
case _TtsChunk():
return $default(_that.text,_that.startOffset,_that.endOffset,_that.spokenText,_that.rawStartOffset,_that.rawEndOffset,_that.isParagraphEnd,_that.paragraphIndex,_that.words,_that.language);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  int startOffset,  int endOffset,  String? spokenText,  int? rawStartOffset,  int? rawEndOffset,  bool isParagraphEnd,  int paragraphIndex, @JsonKey(toJson: _encodeWordSpans, fromJson: _decodeWordSpans)  List<TtsWordSpan> words,  String language)?  $default,) {final _that = this;
switch (_that) {
case _TtsChunk() when $default != null:
return $default(_that.text,_that.startOffset,_that.endOffset,_that.spokenText,_that.rawStartOffset,_that.rawEndOffset,_that.isParagraphEnd,_that.paragraphIndex,_that.words,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TtsChunk extends TtsChunk {
  const _TtsChunk({required this.text, required this.startOffset, required this.endOffset, this.spokenText, this.rawStartOffset, this.rawEndOffset, this.isParagraphEnd = false, this.paragraphIndex = 0, @JsonKey(toJson: _encodeWordSpans, fromJson: _decodeWordSpans)  List<TtsWordSpan> words = const <TtsWordSpan>[], this.language = 'en'}): _words = words,super._();
  factory _TtsChunk.fromJson(Map<String, dynamic> json) => _$TtsChunkFromJson(json);

/// Trimmed display text representing the sentence or clause.
@override final  String text;
/// Absolute character index start bound in the source text
/// (trimmed to non-whitespace).
@override final  int startOffset;
/// Absolute character index end bound in the source text
/// (trimmed to non-whitespace).
@override final  int endOffset;
/// Text sanitized and normalized for speech synthesis (e.g. stripped of
/// footnote citations, soft hyphens, and decorative glyphs).
///
/// Falls back to [text] at read time via [speechContent].
@override final  String? spokenText;
/// Absolute character index start bound in the source text including
/// leading whitespace.
@override final  int? rawStartOffset;
/// Absolute character index end bound in the source text including
/// trailing whitespace.
@override final  int? rawEndOffset;
/// Whether this chunk marks the terminal sentence/clause of a paragraph.
@override@JsonKey() final  bool isParagraphEnd;
/// 0-based paragraph index within the page or document section.
@override@JsonKey() final  int paragraphIndex;
/// Optional word-level spans for progressive karaoke-style highlighting.
///
/// Explicit encoders keep the nested [TtsWordSpan] objects flattened into
/// plain maps so the payload survives `SendPort` hops between isolates.
 final  List<TtsWordSpan> _words;
/// Optional word-level spans for progressive karaoke-style highlighting.
///
/// Explicit encoders keep the nested [TtsWordSpan] objects flattened into
/// plain maps so the payload survives `SendPort` hops between isolates.
@override@JsonKey(toJson: _encodeWordSpans, fromJson: _decodeWordSpans) List<TtsWordSpan> get words {
  if (_words is EqualUnmodifiableListView) return _words;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_words);
}

/// BCP-47 language tag inferred from the chunk's dominant script
/// (e.g. `'en'`, `'ja'`, `'zh'`, `'ru'`).
///
/// Lets the TTS engine pick the right voice/pronunciation for
/// mixed-language content.
@override@JsonKey() final  String language;

/// Create a copy of TtsChunk
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TtsChunkCopyWith<_TtsChunk> get copyWith => __$TtsChunkCopyWithImpl<_TtsChunk>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TtsChunkToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsChunk&&(identical(other.text, text) || other.text == text)&&(identical(other.startOffset, startOffset) || other.startOffset == startOffset)&&(identical(other.endOffset, endOffset) || other.endOffset == endOffset)&&(identical(other.spokenText, spokenText) || other.spokenText == spokenText)&&(identical(other.rawStartOffset, rawStartOffset) || other.rawStartOffset == rawStartOffset)&&(identical(other.rawEndOffset, rawEndOffset) || other.rawEndOffset == rawEndOffset)&&(identical(other.isParagraphEnd, isParagraphEnd) || other.isParagraphEnd == isParagraphEnd)&&(identical(other.paragraphIndex, paragraphIndex) || other.paragraphIndex == paragraphIndex)&&const DeepCollectionEquality().equals(other.words, _words)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,startOffset,endOffset,spokenText,rawStartOffset,rawEndOffset,isParagraphEnd,paragraphIndex,const DeepCollectionEquality().hash(_words),language);
}

@override
String toString() {
    return 'TtsChunk(text: $text, startOffset: $startOffset, endOffset: $endOffset, spokenText: $spokenText, rawStartOffset: $rawStartOffset, rawEndOffset: $rawEndOffset, isParagraphEnd: $isParagraphEnd, paragraphIndex: $paragraphIndex, words: $words, language: $language)';
}


}

/// @nodoc
abstract mixin class _$TtsChunkCopyWith<$Res> implements $TtsChunkCopyWith<$Res> {
  factory _$TtsChunkCopyWith(_TtsChunk value, $Res Function(_TtsChunk) _then) = __$TtsChunkCopyWithImpl;
@override @useResult
$Res call({
 String text, int startOffset, int endOffset, String? spokenText, int? rawStartOffset, int? rawEndOffset, bool isParagraphEnd, int paragraphIndex,@JsonKey(toJson: _encodeWordSpans, fromJson: _decodeWordSpans) List<TtsWordSpan> words, String language
});




}
/// @nodoc
class __$TtsChunkCopyWithImpl<$Res>
    implements _$TtsChunkCopyWith<$Res> {
  __$TtsChunkCopyWithImpl(this._self, this._then);

  final _TtsChunk _self;
  final $Res Function(_TtsChunk) _then;

/// Create a copy of TtsChunk
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? startOffset = null,Object? endOffset = null,Object? spokenText = freezed,Object? rawStartOffset = freezed,Object? rawEndOffset = freezed,Object? isParagraphEnd = null,Object? paragraphIndex = null,Object? words = null,Object? language = null,}) {
  return _then(_TtsChunk(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,spokenText: freezed == spokenText ? _self.spokenText : spokenText // ignore: cast_nullable_to_non_nullable
as String?,rawStartOffset: freezed == rawStartOffset ? _self.rawStartOffset : rawStartOffset // ignore: cast_nullable_to_non_nullable
as int?,rawEndOffset: freezed == rawEndOffset ? _self.rawEndOffset : rawEndOffset // ignore: cast_nullable_to_non_nullable
as int?,isParagraphEnd: null == isParagraphEnd ? _self.isParagraphEnd : isParagraphEnd // ignore: cast_nullable_to_non_nullable
as bool,paragraphIndex: null == paragraphIndex ? _self.paragraphIndex : paragraphIndex // ignore: cast_nullable_to_non_nullable
as int,words: null == words ? _self._words : words // ignore: cast_nullable_to_non_nullable
as List<TtsWordSpan>,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TxtChapter {

/// Zero-based sequential chapter index.
 int get index;/// Chapter or section title.
 String get title;/// Clean semantic HTML content for this chapter (`<h2>...</h2><p>...</p>`).
 String get contentHtml;/// True if this chapter represents a volume or book partition.
 bool get isVolume;/// True if this chapter title was detected from a heading regex;
/// false if it was generated by fallback paragraph chunking.
 bool get detected;
/// Create a copy of TxtChapter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TxtChapterCopyWith<TxtChapter> get copyWith => _$TxtChapterCopyWithImpl<TxtChapter>(this as TxtChapter, _$identity);

  /// Serializes this TxtChapter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TxtChapter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TxtChapter&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.contentHtml, _this.contentHtml) || other.contentHtml == _this.contentHtml)&&(identical(other.isVolume, _this.isVolume) || other.isVolume == _this.isVolume)&&(identical(other.detected, _this.detected) || other.detected == _this.detected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TxtChapter;
  return Object.hash(runtimeType,_this.index,_this.title,_this.contentHtml,_this.isVolume,_this.detected);
}

@override
String toString() {
  final _this = this as TxtChapter;
  return 'TxtChapter(index: ${_this.index}, title: ${_this.title}, contentHtml: ${_this.contentHtml}, isVolume: ${_this.isVolume}, detected: ${_this.detected})';
}


}

/// @nodoc
abstract mixin class $TxtChapterCopyWith<$Res>  {
  factory $TxtChapterCopyWith(TxtChapter value, $Res Function(TxtChapter) _then) = _$TxtChapterCopyWithImpl;
@useResult
$Res call({
 int index, String title, String contentHtml, bool isVolume, bool detected
});




}
/// @nodoc
class _$TxtChapterCopyWithImpl<$Res>
    implements $TxtChapterCopyWith<$Res> {
  _$TxtChapterCopyWithImpl(this._self, this._then);

  final TxtChapter _self;
  final $Res Function(TxtChapter) _then;

/// Create a copy of TxtChapter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? title = null,Object? contentHtml = null,Object? isVolume = null,Object? detected = null,}) {
  return _then(TxtChapter(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,contentHtml: null == contentHtml ? _self.contentHtml : contentHtml // ignore: cast_nullable_to_non_nullable
as String,isVolume: null == isVolume ? _self.isVolume : isVolume // ignore: cast_nullable_to_non_nullable
as bool,detected: null == detected ? _self.detected : detected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TxtChapter].
extension TxtChapterPatterns on TxtChapter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TxtChapter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TxtChapter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TxtChapter value)  $default,){
final _that = this;
switch (_that) {
case _TxtChapter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TxtChapter value)?  $default,){
final _that = this;
switch (_that) {
case _TxtChapter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String title,  String contentHtml,  bool isVolume,  bool detected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TxtChapter() when $default != null:
return $default(_that.index,_that.title,_that.contentHtml,_that.isVolume,_that.detected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String title,  String contentHtml,  bool isVolume,  bool detected)  $default,) {final _that = this;
switch (_that) {
case _TxtChapter():
return $default(_that.index,_that.title,_that.contentHtml,_that.isVolume,_that.detected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String title,  String contentHtml,  bool isVolume,  bool detected)?  $default,) {final _that = this;
switch (_that) {
case _TxtChapter() when $default != null:
return $default(_that.index,_that.title,_that.contentHtml,_that.isVolume,_that.detected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TxtChapter implements TxtChapter {
  const _TxtChapter({required this.index, required this.title, required this.contentHtml, this.isVolume = false, this.detected = true});
  factory _TxtChapter.fromJson(Map<String, dynamic> json) => _$TxtChapterFromJson(json);

/// Zero-based sequential chapter index.
@override final  int index;
/// Chapter or section title.
@override final  String title;
/// Clean semantic HTML content for this chapter (`<h2>...</h2><p>...</p>`).
@override final  String contentHtml;
/// True if this chapter represents a volume or book partition.
@override@JsonKey() final  bool isVolume;
/// True if this chapter title was detected from a heading regex;
/// false if it was generated by fallback paragraph chunking.
@override@JsonKey() final  bool detected;

/// Create a copy of TxtChapter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TxtChapterCopyWith<_TxtChapter> get copyWith => __$TxtChapterCopyWithImpl<_TxtChapter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TxtChapterToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TxtChapter&&(identical(other.index, index) || other.index == index)&&(identical(other.title, title) || other.title == title)&&(identical(other.contentHtml, contentHtml) || other.contentHtml == contentHtml)&&(identical(other.isVolume, isVolume) || other.isVolume == isVolume)&&(identical(other.detected, detected) || other.detected == detected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,index,title,contentHtml,isVolume,detected);
}

@override
String toString() {
    return 'TxtChapter(index: $index, title: $title, contentHtml: $contentHtml, isVolume: $isVolume, detected: $detected)';
}


}

/// @nodoc
abstract mixin class _$TxtChapterCopyWith<$Res> implements $TxtChapterCopyWith<$Res> {
  factory _$TxtChapterCopyWith(_TxtChapter value, $Res Function(_TxtChapter) _then) = __$TxtChapterCopyWithImpl;
@override @useResult
$Res call({
 int index, String title, String contentHtml, bool isVolume, bool detected
});




}
/// @nodoc
class __$TxtChapterCopyWithImpl<$Res>
    implements _$TxtChapterCopyWith<$Res> {
  __$TxtChapterCopyWithImpl(this._self, this._then);

  final _TxtChapter _self;
  final $Res Function(_TxtChapter) _then;

/// Create a copy of TxtChapter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? title = null,Object? contentHtml = null,Object? isVolume = null,Object? detected = null,}) {
  return _then(_TxtChapter(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,contentHtml: null == contentHtml ? _self.contentHtml : contentHtml // ignore: cast_nullable_to_non_nullable
as String,isVolume: null == isVolume ? _self.isVolume : isVolume // ignore: cast_nullable_to_non_nullable
as bool,detected: null == detected ? _self.detected : detected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$TxtMetadata {

/// Extracted or fallback title of the document.
 String get title;/// Extracted author name if detected, or null.
 String? get author;/// Detected or provided BCP-47 language tag.
 String? get language;/// Character encoding detected or used (e.g. 'utf-8', 'gbk', 'shift-jis').
 String get encoding;/// Stable content identifier.
 String? get identifier;
/// Create a copy of TxtMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TxtMetadataCopyWith<TxtMetadata> get copyWith => _$TxtMetadataCopyWithImpl<TxtMetadata>(this as TxtMetadata, _$identity);

  /// Serializes this TxtMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TxtMetadata;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TxtMetadata&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.encoding, _this.encoding) || other.encoding == _this.encoding)&&(identical(other.identifier, _this.identifier) || other.identifier == _this.identifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TxtMetadata;
  return Object.hash(runtimeType,_this.title,_this.author,_this.language,_this.encoding,_this.identifier);
}

@override
String toString() {
  final _this = this as TxtMetadata;
  return 'TxtMetadata(title: ${_this.title}, author: ${_this.author}, language: ${_this.language}, encoding: ${_this.encoding}, identifier: ${_this.identifier})';
}


}

/// @nodoc
abstract mixin class $TxtMetadataCopyWith<$Res>  {
  factory $TxtMetadataCopyWith(TxtMetadata value, $Res Function(TxtMetadata) _then) = _$TxtMetadataCopyWithImpl;
@useResult
$Res call({
 String title, String? author, String? language, String encoding, String? identifier
});




}
/// @nodoc
class _$TxtMetadataCopyWithImpl<$Res>
    implements $TxtMetadataCopyWith<$Res> {
  _$TxtMetadataCopyWithImpl(this._self, this._then);

  final TxtMetadata _self;
  final $Res Function(TxtMetadata) _then;

/// Create a copy of TxtMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? author = freezed,Object? language = freezed,Object? encoding = null,Object? identifier = freezed,}) {
  return _then(TxtMetadata(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,encoding: null == encoding ? _self.encoding : encoding // ignore: cast_nullable_to_non_nullable
as String,identifier: freezed == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TxtMetadata].
extension TxtMetadataPatterns on TxtMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TxtMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TxtMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TxtMetadata value)  $default,){
final _that = this;
switch (_that) {
case _TxtMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TxtMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _TxtMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? author,  String? language,  String encoding,  String? identifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TxtMetadata() when $default != null:
return $default(_that.title,_that.author,_that.language,_that.encoding,_that.identifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? author,  String? language,  String encoding,  String? identifier)  $default,) {final _that = this;
switch (_that) {
case _TxtMetadata():
return $default(_that.title,_that.author,_that.language,_that.encoding,_that.identifier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? author,  String? language,  String encoding,  String? identifier)?  $default,) {final _that = this;
switch (_that) {
case _TxtMetadata() when $default != null:
return $default(_that.title,_that.author,_that.language,_that.encoding,_that.identifier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TxtMetadata implements TxtMetadata {
  const _TxtMetadata({required this.title, this.author, this.language, required this.encoding, this.identifier});
  factory _TxtMetadata.fromJson(Map<String, dynamic> json) => _$TxtMetadataFromJson(json);

/// Extracted or fallback title of the document.
@override final  String title;
/// Extracted author name if detected, or null.
@override final  String? author;
/// Detected or provided BCP-47 language tag.
@override final  String? language;
/// Character encoding detected or used (e.g. 'utf-8', 'gbk', 'shift-jis').
@override final  String encoding;
/// Stable content identifier.
@override final  String? identifier;

/// Create a copy of TxtMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TxtMetadataCopyWith<_TxtMetadata> get copyWith => __$TxtMetadataCopyWithImpl<_TxtMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TxtMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TxtMetadata&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.language, language) || other.language == language)&&(identical(other.encoding, encoding) || other.encoding == encoding)&&(identical(other.identifier, identifier) || other.identifier == identifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,author,language,encoding,identifier);
}

@override
String toString() {
    return 'TxtMetadata(title: $title, author: $author, language: $language, encoding: $encoding, identifier: $identifier)';
}


}

/// @nodoc
abstract mixin class _$TxtMetadataCopyWith<$Res> implements $TxtMetadataCopyWith<$Res> {
  factory _$TxtMetadataCopyWith(_TxtMetadata value, $Res Function(_TxtMetadata) _then) = __$TxtMetadataCopyWithImpl;
@override @useResult
$Res call({
 String title, String? author, String? language, String encoding, String? identifier
});




}
/// @nodoc
class __$TxtMetadataCopyWithImpl<$Res>
    implements _$TxtMetadataCopyWith<$Res> {
  __$TxtMetadataCopyWithImpl(this._self, this._then);

  final _TxtMetadata _self;
  final $Res Function(_TxtMetadata) _then;

/// Create a copy of TxtMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? author = freezed,Object? language = freezed,Object? encoding = null,Object? identifier = freezed,}) {
  return _then(_TxtMetadata(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,encoding: null == encoding ? _self.encoding : encoding // ignore: cast_nullable_to_non_nullable
as String,identifier: freezed == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
