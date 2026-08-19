// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReaderEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderEvent()';
}


}

/// @nodoc
class $ReaderEventCopyWith<$Res>  {
$ReaderEventCopyWith(ReaderEvent _, $Res Function(ReaderEvent) __);
}


/// Adds pattern-matching-related methods to [ReaderEvent].
extension ReaderEventPatterns on ReaderEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _OpenDocument value)?  openDocument,TResult Function( _PageChanged value)?  pageChanged,TResult Function( _LoadPage value)?  loadPage,TResult Function( _CloseDocument value)?  closeDocument,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenDocument() when openDocument != null:
return openDocument(_that);case _PageChanged() when pageChanged != null:
return pageChanged(_that);case _LoadPage() when loadPage != null:
return loadPage(_that);case _CloseDocument() when closeDocument != null:
return closeDocument(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _OpenDocument value)  openDocument,required TResult Function( _PageChanged value)  pageChanged,required TResult Function( _LoadPage value)  loadPage,required TResult Function( _CloseDocument value)  closeDocument,}){
final _that = this;
switch (_that) {
case _OpenDocument():
return openDocument(_that);case _PageChanged():
return pageChanged(_that);case _LoadPage():
return loadPage(_that);case _CloseDocument():
return closeDocument(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _OpenDocument value)?  openDocument,TResult? Function( _PageChanged value)?  pageChanged,TResult? Function( _LoadPage value)?  loadPage,TResult? Function( _CloseDocument value)?  closeDocument,}){
final _that = this;
switch (_that) {
case _OpenDocument() when openDocument != null:
return openDocument(_that);case _PageChanged() when pageChanged != null:
return pageChanged(_that);case _LoadPage() when loadPage != null:
return loadPage(_that);case _CloseDocument() when closeDocument != null:
return closeDocument(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String path,  String fileName)?  openDocument,TResult Function( int index)?  pageChanged,TResult Function( int index)?  loadPage,TResult Function()?  closeDocument,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenDocument() when openDocument != null:
return openDocument(_that.path,_that.fileName);case _PageChanged() when pageChanged != null:
return pageChanged(_that.index);case _LoadPage() when loadPage != null:
return loadPage(_that.index);case _CloseDocument() when closeDocument != null:
return closeDocument();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String path,  String fileName)  openDocument,required TResult Function( int index)  pageChanged,required TResult Function( int index)  loadPage,required TResult Function()  closeDocument,}) {final _that = this;
switch (_that) {
case _OpenDocument():
return openDocument(_that.path,_that.fileName);case _PageChanged():
return pageChanged(_that.index);case _LoadPage():
return loadPage(_that.index);case _CloseDocument():
return closeDocument();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String path,  String fileName)?  openDocument,TResult? Function( int index)?  pageChanged,TResult? Function( int index)?  loadPage,TResult? Function()?  closeDocument,}) {final _that = this;
switch (_that) {
case _OpenDocument() when openDocument != null:
return openDocument(_that.path,_that.fileName);case _PageChanged() when pageChanged != null:
return pageChanged(_that.index);case _LoadPage() when loadPage != null:
return loadPage(_that.index);case _CloseDocument() when closeDocument != null:
return closeDocument();case _:
  return null;

}
}

}

/// @nodoc


class _OpenDocument implements ReaderEvent {
  const _OpenDocument({required this.path, required this.fileName});
  

 final  String path;
 final  String fileName;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenDocumentCopyWith<_OpenDocument> get copyWith => __$OpenDocumentCopyWithImpl<_OpenDocument>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenDocument&&(identical(other.path, path) || other.path == path)&&(identical(other.fileName, fileName) || other.fileName == fileName));
}


@override
int get hashCode => Object.hash(runtimeType,path,fileName);

@override
String toString() {
  return 'ReaderEvent.openDocument(path: $path, fileName: $fileName)';
}


}

/// @nodoc
abstract mixin class _$OpenDocumentCopyWith<$Res> implements $ReaderEventCopyWith<$Res> {
  factory _$OpenDocumentCopyWith(_OpenDocument value, $Res Function(_OpenDocument) _then) = __$OpenDocumentCopyWithImpl;
@useResult
$Res call({
 String path, String fileName
});




}
/// @nodoc
class __$OpenDocumentCopyWithImpl<$Res>
    implements _$OpenDocumentCopyWith<$Res> {
  __$OpenDocumentCopyWithImpl(this._self, this._then);

  final _OpenDocument _self;
  final $Res Function(_OpenDocument) _then;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,Object? fileName = null,}) {
  return _then(_OpenDocument(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _PageChanged implements ReaderEvent {
  const _PageChanged({required this.index});
  

 final  int index;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageChangedCopyWith<_PageChanged> get copyWith => __$PageChangedCopyWithImpl<_PageChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageChanged&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,index);

@override
String toString() {
  return 'ReaderEvent.pageChanged(index: $index)';
}


}

/// @nodoc
abstract mixin class _$PageChangedCopyWith<$Res> implements $ReaderEventCopyWith<$Res> {
  factory _$PageChangedCopyWith(_PageChanged value, $Res Function(_PageChanged) _then) = __$PageChangedCopyWithImpl;
@useResult
$Res call({
 int index
});




}
/// @nodoc
class __$PageChangedCopyWithImpl<$Res>
    implements _$PageChangedCopyWith<$Res> {
  __$PageChangedCopyWithImpl(this._self, this._then);

  final _PageChanged _self;
  final $Res Function(_PageChanged) _then;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,}) {
  return _then(_PageChanged(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _LoadPage implements ReaderEvent {
  const _LoadPage({required this.index});
  

 final  int index;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadPageCopyWith<_LoadPage> get copyWith => __$LoadPageCopyWithImpl<_LoadPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadPage&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,index);

@override
String toString() {
  return 'ReaderEvent.loadPage(index: $index)';
}


}

/// @nodoc
abstract mixin class _$LoadPageCopyWith<$Res> implements $ReaderEventCopyWith<$Res> {
  factory _$LoadPageCopyWith(_LoadPage value, $Res Function(_LoadPage) _then) = __$LoadPageCopyWithImpl;
@useResult
$Res call({
 int index
});




}
/// @nodoc
class __$LoadPageCopyWithImpl<$Res>
    implements _$LoadPageCopyWith<$Res> {
  __$LoadPageCopyWithImpl(this._self, this._then);

  final _LoadPage _self;
  final $Res Function(_LoadPage) _then;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,}) {
  return _then(_LoadPage(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _CloseDocument implements ReaderEvent {
  const _CloseDocument();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CloseDocument);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderEvent.closeDocument()';
}


}




/// @nodoc
mixin _$ReaderState {

 bool get loading; String? get error; String? get fileName; int get pageCount; int get currentPage; List<String?>? get htmlPages; Set<int> get loadingPages;
/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderStateCopyWith<ReaderState> get copyWith => _$ReaderStateCopyWithImpl<ReaderState>(this as ReaderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderState&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&const DeepCollectionEquality().equals(other.htmlPages, htmlPages)&&const DeepCollectionEquality().equals(other.loadingPages, loadingPages));
}


@override
int get hashCode => Object.hash(runtimeType,loading,error,fileName,pageCount,currentPage,const DeepCollectionEquality().hash(htmlPages),const DeepCollectionEquality().hash(loadingPages));

@override
String toString() {
  return 'ReaderState(loading: $loading, error: $error, fileName: $fileName, pageCount: $pageCount, currentPage: $currentPage, htmlPages: $htmlPages, loadingPages: $loadingPages)';
}


}

/// @nodoc
abstract mixin class $ReaderStateCopyWith<$Res>  {
  factory $ReaderStateCopyWith(ReaderState value, $Res Function(ReaderState) _then) = _$ReaderStateCopyWithImpl;
@useResult
$Res call({
 bool loading, String? error, String? fileName, int pageCount, int currentPage, List<String?>? htmlPages, Set<int> loadingPages
});




}
/// @nodoc
class _$ReaderStateCopyWithImpl<$Res>
    implements $ReaderStateCopyWith<$Res> {
  _$ReaderStateCopyWithImpl(this._self, this._then);

  final ReaderState _self;
  final $Res Function(ReaderState) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loading = null,Object? error = freezed,Object? fileName = freezed,Object? pageCount = null,Object? currentPage = null,Object? htmlPages = freezed,Object? loadingPages = null,}) {
  return _then(_self.copyWith(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,htmlPages: freezed == htmlPages ? _self.htmlPages : htmlPages // ignore: cast_nullable_to_non_nullable
as List<String?>?,loadingPages: null == loadingPages ? _self.loadingPages : loadingPages // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReaderState].
extension ReaderStatePatterns on ReaderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReaderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReaderState value)  $default,){
final _that = this;
switch (_that) {
case _ReaderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReaderState value)?  $default,){
final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool loading,  String? error,  String? fileName,  int pageCount,  int currentPage,  List<String?>? htmlPages,  Set<int> loadingPages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.loading,_that.error,_that.fileName,_that.pageCount,_that.currentPage,_that.htmlPages,_that.loadingPages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool loading,  String? error,  String? fileName,  int pageCount,  int currentPage,  List<String?>? htmlPages,  Set<int> loadingPages)  $default,) {final _that = this;
switch (_that) {
case _ReaderState():
return $default(_that.loading,_that.error,_that.fileName,_that.pageCount,_that.currentPage,_that.htmlPages,_that.loadingPages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool loading,  String? error,  String? fileName,  int pageCount,  int currentPage,  List<String?>? htmlPages,  Set<int> loadingPages)?  $default,) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.loading,_that.error,_that.fileName,_that.pageCount,_that.currentPage,_that.htmlPages,_that.loadingPages);case _:
  return null;

}
}

}

/// @nodoc


class _ReaderState implements ReaderState {
  const _ReaderState({this.loading = false, this.error, this.fileName, this.pageCount = 0, this.currentPage = 0, final  List<String?>? htmlPages, final  Set<int> loadingPages = const <int>{}}): _htmlPages = htmlPages,_loadingPages = loadingPages;
  

@override@JsonKey() final  bool loading;
@override final  String? error;
@override final  String? fileName;
@override@JsonKey() final  int pageCount;
@override@JsonKey() final  int currentPage;
 final  List<String?>? _htmlPages;
@override List<String?>? get htmlPages {
  final value = _htmlPages;
  if (value == null) return null;
  if (_htmlPages is EqualUnmodifiableListView) return _htmlPages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Set<int> _loadingPages;
@override@JsonKey() Set<int> get loadingPages {
  if (_loadingPages is EqualUnmodifiableSetView) return _loadingPages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_loadingPages);
}


/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReaderStateCopyWith<_ReaderState> get copyWith => __$ReaderStateCopyWithImpl<_ReaderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReaderState&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&const DeepCollectionEquality().equals(other._htmlPages, _htmlPages)&&const DeepCollectionEquality().equals(other._loadingPages, _loadingPages));
}


@override
int get hashCode => Object.hash(runtimeType,loading,error,fileName,pageCount,currentPage,const DeepCollectionEquality().hash(_htmlPages),const DeepCollectionEquality().hash(_loadingPages));

@override
String toString() {
  return 'ReaderState(loading: $loading, error: $error, fileName: $fileName, pageCount: $pageCount, currentPage: $currentPage, htmlPages: $htmlPages, loadingPages: $loadingPages)';
}


}

/// @nodoc
abstract mixin class _$ReaderStateCopyWith<$Res> implements $ReaderStateCopyWith<$Res> {
  factory _$ReaderStateCopyWith(_ReaderState value, $Res Function(_ReaderState) _then) = __$ReaderStateCopyWithImpl;
@override @useResult
$Res call({
 bool loading, String? error, String? fileName, int pageCount, int currentPage, List<String?>? htmlPages, Set<int> loadingPages
});




}
/// @nodoc
class __$ReaderStateCopyWithImpl<$Res>
    implements _$ReaderStateCopyWith<$Res> {
  __$ReaderStateCopyWithImpl(this._self, this._then);

  final _ReaderState _self;
  final $Res Function(_ReaderState) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loading = null,Object? error = freezed,Object? fileName = freezed,Object? pageCount = null,Object? currentPage = null,Object? htmlPages = freezed,Object? loadingPages = null,}) {
  return _then(_ReaderState(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,htmlPages: freezed == htmlPages ? _self._htmlPages : htmlPages // ignore: cast_nullable_to_non_nullable
as List<String?>?,loadingPages: null == loadingPages ? _self._loadingPages : loadingPages // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}


}

// dart format on
