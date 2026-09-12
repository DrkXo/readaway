// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentMetadata&&(identical(other.title, title) || other.title == title)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.language, language) || other.language == language)&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.description, description) || other.description == description)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.modified, modified) || other.modified == modified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,creator,language,identifier,publisher,description,subject,modified);

@override
String toString() {
  return 'DocumentMetadata(title: $title, creator: $creator, language: $language, identifier: $identifier, publisher: $publisher, description: $description, subject: $subject, modified: $modified)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,title,creator,language,identifier,publisher,description,subject,modified);

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentSection&&(identical(other.index, index) || other.index == index)&&(identical(other.id, id) || other.id == id)&&(identical(other.href, href) || other.href == href)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,id,href,mediaType,title);

@override
String toString() {
  return 'DocumentSection(index: $index, id: $id, href: $href, mediaType: $mediaType, title: $title)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,index,id,href,mediaType,title);

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpfData&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.sections, sections)&&(identical(other.ncxHref, ncxHref) || other.ncxHref == ncxHref)&&(identical(other.navHref, navHref) || other.navHref == navHref)&&(identical(other.opfDir, opfDir) || other.opfDir == opfDir)&&(identical(other.coverImagePath, coverImagePath) || other.coverImagePath == coverImagePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata,const DeepCollectionEquality().hash(sections),ncxHref,navHref,opfDir,coverImagePath);

@override
String toString() {
  return 'OpfData(metadata: $metadata, sections: $sections, ncxHref: $ncxHref, navHref: $navHref, opfDir: $opfDir, coverImagePath: $coverImagePath)';
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
  return _then(_self.copyWith(
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
  const _OpfData({required this.metadata, required final  List<DocumentSection> sections, this.ncxHref, this.navHref, this.opfDir = '', this.coverImagePath}): _sections = sections;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpfData&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other._sections, _sections)&&(identical(other.ncxHref, ncxHref) || other.ncxHref == ncxHref)&&(identical(other.navHref, navHref) || other.navHref == navHref)&&(identical(other.opfDir, opfDir) || other.opfDir == opfDir)&&(identical(other.coverImagePath, coverImagePath) || other.coverImagePath == coverImagePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata,const DeepCollectionEquality().hash(_sections),ncxHref,navHref,opfDir,coverImagePath);

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutlineItem&&(identical(other.title, title) || other.title == title)&&(identical(other.href, href) || other.href == href)&&(identical(other.level, level) || other.level == level)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&const DeepCollectionEquality().equals(other.children, children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,href,level,chapterIndex,const DeepCollectionEquality().hash(children));

@override
String toString() {
  return 'OutlineItem(title: $title, href: $href, level: $level, chapterIndex: $chapterIndex, children: $children)';
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
  return _then(_self.copyWith(
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
  const _OutlineItem({required this.title, this.href, this.level = 0, this.chapterIndex, final  List<OutlineItem> children = const []}): _children = children,super._();
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutlineItem&&(identical(other.title, title) || other.title == title)&&(identical(other.href, href) || other.href == href)&&(identical(other.level, level) || other.level == level)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&const DeepCollectionEquality().equals(other._children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,href,level,chapterIndex,const DeepCollectionEquality().hash(_children));

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageCoordinate&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.pageInChapter, pageInChapter) || other.pageInChapter == pageInChapter)&&(identical(other.totalPagesInChapter, totalPagesInChapter) || other.totalPagesInChapter == totalPagesInChapter)&&(identical(other.globalPage, globalPage) || other.globalPage == globalPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chapterIndex,pageInChapter,totalPagesInChapter,globalPage);

@override
String toString() {
  return 'PageCoordinate(chapterIndex: $chapterIndex, pageInChapter: $pageInChapter, totalPagesInChapter: $totalPagesInChapter, globalPage: $globalPage)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,chapterIndex,pageInChapter,totalPagesInChapter,globalPage);

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageLink&&(identical(other.bounds, bounds) || other.bounds == bounds)&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber));
}


@override
int get hashCode => Object.hash(runtimeType,bounds,uri,pageNumber);

@override
String toString() {
  return 'PageLink(bounds: $bounds, uri: $uri, pageNumber: $pageNumber)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,bounds,uri,pageNumber);

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageRect&&(identical(other.x0, x0) || other.x0 == x0)&&(identical(other.y0, y0) || other.y0 == y0)&&(identical(other.x1, x1) || other.x1 == x1)&&(identical(other.y1, y1) || other.y1 == y1));
}


@override
int get hashCode => Object.hash(runtimeType,x0,y0,x1,y1);

@override
String toString() {
  return 'PageRect(x0: $x0, y0: $y0, x1: $x1, y1: $y1)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,x0,y0,x1,y1);

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationState&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.pageInChapter, pageInChapter) || other.pageInChapter == pageInChapter)&&(identical(other.totalPagesInChapter, totalPagesInChapter) || other.totalPagesInChapter == totalPagesInChapter)&&(identical(other.globalPage, globalPage) || other.globalPage == globalPage)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.viewportHeight, viewportHeight) || other.viewportHeight == viewportHeight)&&const DeepCollectionEquality().equals(other.chapterHeights, chapterHeights)&&const DeepCollectionEquality().equals(other.chapterPageCounts, chapterPageCounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chapterIndex,pageInChapter,totalPagesInChapter,globalPage,totalPages,viewportHeight,const DeepCollectionEquality().hash(chapterHeights),const DeepCollectionEquality().hash(chapterPageCounts));

@override
String toString() {
  return 'PaginationState(chapterIndex: $chapterIndex, pageInChapter: $pageInChapter, totalPagesInChapter: $totalPagesInChapter, globalPage: $globalPage, totalPages: $totalPages, viewportHeight: $viewportHeight, chapterHeights: $chapterHeights, chapterPageCounts: $chapterPageCounts)';
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
  return _then(_self.copyWith(
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
  const _PaginationState({this.chapterIndex = 0, this.pageInChapter = 0, this.totalPagesInChapter = 1, this.globalPage = 0, this.totalPages = 0, this.viewportHeight = 0.0, final  Map<int, double> chapterHeights = const {}, final  Map<int, int> chapterPageCounts = const {}}): _chapterHeights = chapterHeights,_chapterPageCounts = chapterPageCounts;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginationState&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.pageInChapter, pageInChapter) || other.pageInChapter == pageInChapter)&&(identical(other.totalPagesInChapter, totalPagesInChapter) || other.totalPagesInChapter == totalPagesInChapter)&&(identical(other.globalPage, globalPage) || other.globalPage == globalPage)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.viewportHeight, viewportHeight) || other.viewportHeight == viewportHeight)&&const DeepCollectionEquality().equals(other._chapterHeights, _chapterHeights)&&const DeepCollectionEquality().equals(other._chapterPageCounts, _chapterPageCounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chapterIndex,pageInChapter,totalPagesInChapter,globalPage,totalPages,viewportHeight,const DeepCollectionEquality().hash(_chapterHeights),const DeepCollectionEquality().hash(_chapterPageCounts));

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingAnchor&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.progressionInChapter, progressionInChapter) || other.progressionInChapter == progressionInChapter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chapterIndex,progressionInChapter);

@override
String toString() {
  return 'ReadingAnchor(chapterIndex: $chapterIndex, progressionInChapter: $progressionInChapter)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,chapterIndex,progressionInChapter);

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RenderedPage&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.stride, stride) || other.stride == stride)&&(identical(other.components, components) || other.components == components)&&const DeepCollectionEquality().equals(other.pixels, pixels));
}


@override
int get hashCode => Object.hash(runtimeType,width,height,stride,components,const DeepCollectionEquality().hash(pixels));

@override
String toString() {
  return 'RenderedPage(width: $width, height: $height, stride: $stride, components: $components, pixels: $pixels)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,width,height,stride,components,const DeepCollectionEquality().hash(pixels));

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchHit&&(identical(other.ulX, ulX) || other.ulX == ulX)&&(identical(other.ulY, ulY) || other.ulY == ulY)&&(identical(other.urX, urX) || other.urX == urX)&&(identical(other.urY, urY) || other.urY == urY)&&(identical(other.lrX, lrX) || other.lrX == lrX)&&(identical(other.lrY, lrY) || other.lrY == lrY)&&(identical(other.llX, llX) || other.llX == llX)&&(identical(other.llY, llY) || other.llY == llY));
}


@override
int get hashCode => Object.hash(runtimeType,ulX,ulY,urX,urY,lrX,lrY,llX,llY);

@override
String toString() {
  return 'SearchHit(ulX: $ulX, ulY: $ulY, urX: $urX, urY: $urY, lrX: $lrX, lrY: $lrY, llX: $llX, llY: $llY)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,ulX,ulY,urX,urY,lrX,lrY,llX,llY);

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

// dart format on
