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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _OpenDocument value)?  openDocument,TResult Function( _EngineModeChanged value)?  engineModeChanged,TResult Function( _PageChanged value)?  pageChanged,TResult Function( _LoadPage value)?  loadPage,TResult Function( _CloseDocument value)?  closeDocument,TResult Function( _TtsStart value)?  ttsStart,TResult Function( _TtsClose value)?  ttsClose,TResult Function( _ConsumeFeedback value)?  consumeFeedback,TResult Function( _TtsErrorOccurred value)?  ttsErrorOccurred,TResult Function( _JumpToTtsPage value)?  jumpToTtsPage,TResult Function( _TtsPageAdvanced value)?  ttsPageAdvanced,TResult Function( _VirtualPageChanged value)?  virtualPageChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenDocument() when openDocument != null:
return openDocument(_that);case _EngineModeChanged() when engineModeChanged != null:
return engineModeChanged(_that);case _PageChanged() when pageChanged != null:
return pageChanged(_that);case _LoadPage() when loadPage != null:
return loadPage(_that);case _CloseDocument() when closeDocument != null:
return closeDocument(_that);case _TtsStart() when ttsStart != null:
return ttsStart(_that);case _TtsClose() when ttsClose != null:
return ttsClose(_that);case _ConsumeFeedback() when consumeFeedback != null:
return consumeFeedback(_that);case _TtsErrorOccurred() when ttsErrorOccurred != null:
return ttsErrorOccurred(_that);case _JumpToTtsPage() when jumpToTtsPage != null:
return jumpToTtsPage(_that);case _TtsPageAdvanced() when ttsPageAdvanced != null:
return ttsPageAdvanced(_that);case _VirtualPageChanged() when virtualPageChanged != null:
return virtualPageChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _OpenDocument value)  openDocument,required TResult Function( _EngineModeChanged value)  engineModeChanged,required TResult Function( _PageChanged value)  pageChanged,required TResult Function( _LoadPage value)  loadPage,required TResult Function( _CloseDocument value)  closeDocument,required TResult Function( _TtsStart value)  ttsStart,required TResult Function( _TtsClose value)  ttsClose,required TResult Function( _ConsumeFeedback value)  consumeFeedback,required TResult Function( _TtsErrorOccurred value)  ttsErrorOccurred,required TResult Function( _JumpToTtsPage value)  jumpToTtsPage,required TResult Function( _TtsPageAdvanced value)  ttsPageAdvanced,required TResult Function( _VirtualPageChanged value)  virtualPageChanged,}){
final _that = this;
switch (_that) {
case _OpenDocument():
return openDocument(_that);case _EngineModeChanged():
return engineModeChanged(_that);case _PageChanged():
return pageChanged(_that);case _LoadPage():
return loadPage(_that);case _CloseDocument():
return closeDocument(_that);case _TtsStart():
return ttsStart(_that);case _TtsClose():
return ttsClose(_that);case _ConsumeFeedback():
return consumeFeedback(_that);case _TtsErrorOccurred():
return ttsErrorOccurred(_that);case _JumpToTtsPage():
return jumpToTtsPage(_that);case _TtsPageAdvanced():
return ttsPageAdvanced(_that);case _VirtualPageChanged():
return virtualPageChanged(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _OpenDocument value)?  openDocument,TResult? Function( _EngineModeChanged value)?  engineModeChanged,TResult? Function( _PageChanged value)?  pageChanged,TResult? Function( _LoadPage value)?  loadPage,TResult? Function( _CloseDocument value)?  closeDocument,TResult? Function( _TtsStart value)?  ttsStart,TResult? Function( _TtsClose value)?  ttsClose,TResult? Function( _ConsumeFeedback value)?  consumeFeedback,TResult? Function( _TtsErrorOccurred value)?  ttsErrorOccurred,TResult? Function( _JumpToTtsPage value)?  jumpToTtsPage,TResult? Function( _TtsPageAdvanced value)?  ttsPageAdvanced,TResult? Function( _VirtualPageChanged value)?  virtualPageChanged,}){
final _that = this;
switch (_that) {
case _OpenDocument() when openDocument != null:
return openDocument(_that);case _EngineModeChanged() when engineModeChanged != null:
return engineModeChanged(_that);case _PageChanged() when pageChanged != null:
return pageChanged(_that);case _LoadPage() when loadPage != null:
return loadPage(_that);case _CloseDocument() when closeDocument != null:
return closeDocument(_that);case _TtsStart() when ttsStart != null:
return ttsStart(_that);case _TtsClose() when ttsClose != null:
return ttsClose(_that);case _ConsumeFeedback() when consumeFeedback != null:
return consumeFeedback(_that);case _TtsErrorOccurred() when ttsErrorOccurred != null:
return ttsErrorOccurred(_that);case _JumpToTtsPage() when jumpToTtsPage != null:
return jumpToTtsPage(_that);case _TtsPageAdvanced() when ttsPageAdvanced != null:
return ttsPageAdvanced(_that);case _VirtualPageChanged() when virtualPageChanged != null:
return virtualPageChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String path,  String? fileName,  ReaderEngineMode engineMode)?  openDocument,TResult Function( ReaderEngineMode newMode)?  engineModeChanged,TResult Function( int index)?  pageChanged,TResult Function( int index)?  loadPage,TResult Function()?  closeDocument,TResult Function()?  ttsStart,TResult Function()?  ttsClose,TResult Function()?  consumeFeedback,TResult Function( String message)?  ttsErrorOccurred,TResult Function()?  jumpToTtsPage,TResult Function( int pageIndex)?  ttsPageAdvanced,TResult Function( int globalPage,  int totalPages,  int chapterIndex)?  virtualPageChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenDocument() when openDocument != null:
return openDocument(_that.path,_that.fileName,_that.engineMode);case _EngineModeChanged() when engineModeChanged != null:
return engineModeChanged(_that.newMode);case _PageChanged() when pageChanged != null:
return pageChanged(_that.index);case _LoadPage() when loadPage != null:
return loadPage(_that.index);case _CloseDocument() when closeDocument != null:
return closeDocument();case _TtsStart() when ttsStart != null:
return ttsStart();case _TtsClose() when ttsClose != null:
return ttsClose();case _ConsumeFeedback() when consumeFeedback != null:
return consumeFeedback();case _TtsErrorOccurred() when ttsErrorOccurred != null:
return ttsErrorOccurred(_that.message);case _JumpToTtsPage() when jumpToTtsPage != null:
return jumpToTtsPage();case _TtsPageAdvanced() when ttsPageAdvanced != null:
return ttsPageAdvanced(_that.pageIndex);case _VirtualPageChanged() when virtualPageChanged != null:
return virtualPageChanged(_that.globalPage,_that.totalPages,_that.chapterIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String path,  String? fileName,  ReaderEngineMode engineMode)  openDocument,required TResult Function( ReaderEngineMode newMode)  engineModeChanged,required TResult Function( int index)  pageChanged,required TResult Function( int index)  loadPage,required TResult Function()  closeDocument,required TResult Function()  ttsStart,required TResult Function()  ttsClose,required TResult Function()  consumeFeedback,required TResult Function( String message)  ttsErrorOccurred,required TResult Function()  jumpToTtsPage,required TResult Function( int pageIndex)  ttsPageAdvanced,required TResult Function( int globalPage,  int totalPages,  int chapterIndex)  virtualPageChanged,}) {final _that = this;
switch (_that) {
case _OpenDocument():
return openDocument(_that.path,_that.fileName,_that.engineMode);case _EngineModeChanged():
return engineModeChanged(_that.newMode);case _PageChanged():
return pageChanged(_that.index);case _LoadPage():
return loadPage(_that.index);case _CloseDocument():
return closeDocument();case _TtsStart():
return ttsStart();case _TtsClose():
return ttsClose();case _ConsumeFeedback():
return consumeFeedback();case _TtsErrorOccurred():
return ttsErrorOccurred(_that.message);case _JumpToTtsPage():
return jumpToTtsPage();case _TtsPageAdvanced():
return ttsPageAdvanced(_that.pageIndex);case _VirtualPageChanged():
return virtualPageChanged(_that.globalPage,_that.totalPages,_that.chapterIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String path,  String? fileName,  ReaderEngineMode engineMode)?  openDocument,TResult? Function( ReaderEngineMode newMode)?  engineModeChanged,TResult? Function( int index)?  pageChanged,TResult? Function( int index)?  loadPage,TResult? Function()?  closeDocument,TResult? Function()?  ttsStart,TResult? Function()?  ttsClose,TResult? Function()?  consumeFeedback,TResult? Function( String message)?  ttsErrorOccurred,TResult? Function()?  jumpToTtsPage,TResult? Function( int pageIndex)?  ttsPageAdvanced,TResult? Function( int globalPage,  int totalPages,  int chapterIndex)?  virtualPageChanged,}) {final _that = this;
switch (_that) {
case _OpenDocument() when openDocument != null:
return openDocument(_that.path,_that.fileName,_that.engineMode);case _EngineModeChanged() when engineModeChanged != null:
return engineModeChanged(_that.newMode);case _PageChanged() when pageChanged != null:
return pageChanged(_that.index);case _LoadPage() when loadPage != null:
return loadPage(_that.index);case _CloseDocument() when closeDocument != null:
return closeDocument();case _TtsStart() when ttsStart != null:
return ttsStart();case _TtsClose() when ttsClose != null:
return ttsClose();case _ConsumeFeedback() when consumeFeedback != null:
return consumeFeedback();case _TtsErrorOccurred() when ttsErrorOccurred != null:
return ttsErrorOccurred(_that.message);case _JumpToTtsPage() when jumpToTtsPage != null:
return jumpToTtsPage();case _TtsPageAdvanced() when ttsPageAdvanced != null:
return ttsPageAdvanced(_that.pageIndex);case _VirtualPageChanged() when virtualPageChanged != null:
return virtualPageChanged(_that.globalPage,_that.totalPages,_that.chapterIndex);case _:
  return null;

}
}

}

/// @nodoc


class _OpenDocument implements ReaderEvent {
  const _OpenDocument({required this.path, this.fileName, this.engineMode = ReaderEngineMode.customFlow});
  

 final  String path;
 final  String? fileName;
@JsonKey() final  ReaderEngineMode engineMode;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenDocumentCopyWith<_OpenDocument> get copyWith => __$OpenDocumentCopyWithImpl<_OpenDocument>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenDocument&&(identical(other.path, path) || other.path == path)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.engineMode, engineMode) || other.engineMode == engineMode));
}


@override
int get hashCode => Object.hash(runtimeType,path,fileName,engineMode);

@override
String toString() {
  return 'ReaderEvent.openDocument(path: $path, fileName: $fileName, engineMode: $engineMode)';
}


}

/// @nodoc
abstract mixin class _$OpenDocumentCopyWith<$Res> implements $ReaderEventCopyWith<$Res> {
  factory _$OpenDocumentCopyWith(_OpenDocument value, $Res Function(_OpenDocument) _then) = __$OpenDocumentCopyWithImpl;
@useResult
$Res call({
 String path, String? fileName, ReaderEngineMode engineMode
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
@pragma('vm:prefer-inline') $Res call({Object? path = null,Object? fileName = freezed,Object? engineMode = null,}) {
  return _then(_OpenDocument(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,engineMode: null == engineMode ? _self.engineMode : engineMode // ignore: cast_nullable_to_non_nullable
as ReaderEngineMode,
  ));
}


}

/// @nodoc


class _EngineModeChanged implements ReaderEvent {
  const _EngineModeChanged({required this.newMode});
  

 final  ReaderEngineMode newMode;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EngineModeChangedCopyWith<_EngineModeChanged> get copyWith => __$EngineModeChangedCopyWithImpl<_EngineModeChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EngineModeChanged&&(identical(other.newMode, newMode) || other.newMode == newMode));
}


@override
int get hashCode => Object.hash(runtimeType,newMode);

@override
String toString() {
  return 'ReaderEvent.engineModeChanged(newMode: $newMode)';
}


}

/// @nodoc
abstract mixin class _$EngineModeChangedCopyWith<$Res> implements $ReaderEventCopyWith<$Res> {
  factory _$EngineModeChangedCopyWith(_EngineModeChanged value, $Res Function(_EngineModeChanged) _then) = __$EngineModeChangedCopyWithImpl;
@useResult
$Res call({
 ReaderEngineMode newMode
});




}
/// @nodoc
class __$EngineModeChangedCopyWithImpl<$Res>
    implements _$EngineModeChangedCopyWith<$Res> {
  __$EngineModeChangedCopyWithImpl(this._self, this._then);

  final _EngineModeChanged _self;
  final $Res Function(_EngineModeChanged) _then;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? newMode = null,}) {
  return _then(_EngineModeChanged(
newMode: null == newMode ? _self.newMode : newMode // ignore: cast_nullable_to_non_nullable
as ReaderEngineMode,
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


class _TtsStart implements ReaderEvent {
  const _TtsStart();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsStart);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderEvent.ttsStart()';
}


}




/// @nodoc


class _TtsClose implements ReaderEvent {
  const _TtsClose();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsClose);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderEvent.ttsClose()';
}


}




/// @nodoc


class _ConsumeFeedback implements ReaderEvent {
  const _ConsumeFeedback();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsumeFeedback);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderEvent.consumeFeedback()';
}


}




/// @nodoc


class _TtsErrorOccurred implements ReaderEvent {
  const _TtsErrorOccurred(this.message);
  

 final  String message;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TtsErrorOccurredCopyWith<_TtsErrorOccurred> get copyWith => __$TtsErrorOccurredCopyWithImpl<_TtsErrorOccurred>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsErrorOccurred&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ReaderEvent.ttsErrorOccurred(message: $message)';
}


}

/// @nodoc
abstract mixin class _$TtsErrorOccurredCopyWith<$Res> implements $ReaderEventCopyWith<$Res> {
  factory _$TtsErrorOccurredCopyWith(_TtsErrorOccurred value, $Res Function(_TtsErrorOccurred) _then) = __$TtsErrorOccurredCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$TtsErrorOccurredCopyWithImpl<$Res>
    implements _$TtsErrorOccurredCopyWith<$Res> {
  __$TtsErrorOccurredCopyWithImpl(this._self, this._then);

  final _TtsErrorOccurred _self;
  final $Res Function(_TtsErrorOccurred) _then;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_TtsErrorOccurred(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _JumpToTtsPage implements ReaderEvent {
  const _JumpToTtsPage();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JumpToTtsPage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderEvent.jumpToTtsPage()';
}


}




/// @nodoc


class _TtsPageAdvanced implements ReaderEvent {
  const _TtsPageAdvanced({required this.pageIndex});
  

 final  int pageIndex;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TtsPageAdvancedCopyWith<_TtsPageAdvanced> get copyWith => __$TtsPageAdvancedCopyWithImpl<_TtsPageAdvanced>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsPageAdvanced&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex));
}


@override
int get hashCode => Object.hash(runtimeType,pageIndex);

@override
String toString() {
  return 'ReaderEvent.ttsPageAdvanced(pageIndex: $pageIndex)';
}


}

/// @nodoc
abstract mixin class _$TtsPageAdvancedCopyWith<$Res> implements $ReaderEventCopyWith<$Res> {
  factory _$TtsPageAdvancedCopyWith(_TtsPageAdvanced value, $Res Function(_TtsPageAdvanced) _then) = __$TtsPageAdvancedCopyWithImpl;
@useResult
$Res call({
 int pageIndex
});




}
/// @nodoc
class __$TtsPageAdvancedCopyWithImpl<$Res>
    implements _$TtsPageAdvancedCopyWith<$Res> {
  __$TtsPageAdvancedCopyWithImpl(this._self, this._then);

  final _TtsPageAdvanced _self;
  final $Res Function(_TtsPageAdvanced) _then;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pageIndex = null,}) {
  return _then(_TtsPageAdvanced(
pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _VirtualPageChanged implements ReaderEvent {
  const _VirtualPageChanged({required this.globalPage, required this.totalPages, required this.chapterIndex});
  

 final  int globalPage;
 final  int totalPages;
 final  int chapterIndex;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VirtualPageChangedCopyWith<_VirtualPageChanged> get copyWith => __$VirtualPageChangedCopyWithImpl<_VirtualPageChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VirtualPageChanged&&(identical(other.globalPage, globalPage) || other.globalPage == globalPage)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex));
}


@override
int get hashCode => Object.hash(runtimeType,globalPage,totalPages,chapterIndex);

@override
String toString() {
  return 'ReaderEvent.virtualPageChanged(globalPage: $globalPage, totalPages: $totalPages, chapterIndex: $chapterIndex)';
}


}

/// @nodoc
abstract mixin class _$VirtualPageChangedCopyWith<$Res> implements $ReaderEventCopyWith<$Res> {
  factory _$VirtualPageChangedCopyWith(_VirtualPageChanged value, $Res Function(_VirtualPageChanged) _then) = __$VirtualPageChangedCopyWithImpl;
@useResult
$Res call({
 int globalPage, int totalPages, int chapterIndex
});




}
/// @nodoc
class __$VirtualPageChangedCopyWithImpl<$Res>
    implements _$VirtualPageChangedCopyWith<$Res> {
  __$VirtualPageChangedCopyWithImpl(this._self, this._then);

  final _VirtualPageChanged _self;
  final $Res Function(_VirtualPageChanged) _then;

/// Create a copy of ReaderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? globalPage = null,Object? totalPages = null,Object? chapterIndex = null,}) {
  return _then(_VirtualPageChanged(
globalPage: null == globalPage ? _self.globalPage : globalPage // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ReaderState {

 bool get loading; Failure? get failure; String? get error; String? get fileName; bool get isReflowable; int get pageCount; int get currentPage; List<String?>? get pageHtmls; List<List<ReaderLink>?>? get pageLinks; List<ui.Image?>? get pageImages; Set<int> get loadingPages; List<OutlineItem>? get outline; String? get bookTitle; String? get author; String? get documentPath; UiFeedback? get transientFeedback; bool get ttsActive; int? get ttsCurrentPage; ReaderEngineMode get engineMode; int? get virtualPageCount; int? get currentVirtualPage;
/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderStateCopyWith<ReaderState> get copyWith => _$ReaderStateCopyWithImpl<ReaderState>(this as ReaderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderState&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.error, error) || other.error == error)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.isReflowable, isReflowable) || other.isReflowable == isReflowable)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&const DeepCollectionEquality().equals(other.pageHtmls, pageHtmls)&&const DeepCollectionEquality().equals(other.pageLinks, pageLinks)&&const DeepCollectionEquality().equals(other.pageImages, pageImages)&&const DeepCollectionEquality().equals(other.loadingPages, loadingPages)&&const DeepCollectionEquality().equals(other.outline, outline)&&(identical(other.bookTitle, bookTitle) || other.bookTitle == bookTitle)&&(identical(other.author, author) || other.author == author)&&(identical(other.documentPath, documentPath) || other.documentPath == documentPath)&&(identical(other.transientFeedback, transientFeedback) || other.transientFeedback == transientFeedback)&&(identical(other.ttsActive, ttsActive) || other.ttsActive == ttsActive)&&(identical(other.ttsCurrentPage, ttsCurrentPage) || other.ttsCurrentPage == ttsCurrentPage)&&(identical(other.engineMode, engineMode) || other.engineMode == engineMode)&&(identical(other.virtualPageCount, virtualPageCount) || other.virtualPageCount == virtualPageCount)&&(identical(other.currentVirtualPage, currentVirtualPage) || other.currentVirtualPage == currentVirtualPage));
}


@override
int get hashCode => Object.hashAll([runtimeType,loading,failure,error,fileName,isReflowable,pageCount,currentPage,const DeepCollectionEquality().hash(pageHtmls),const DeepCollectionEquality().hash(pageLinks),const DeepCollectionEquality().hash(pageImages),const DeepCollectionEquality().hash(loadingPages),const DeepCollectionEquality().hash(outline),bookTitle,author,documentPath,transientFeedback,ttsActive,ttsCurrentPage,engineMode,virtualPageCount,currentVirtualPage]);

@override
String toString() {
  return 'ReaderState(loading: $loading, failure: $failure, error: $error, fileName: $fileName, isReflowable: $isReflowable, pageCount: $pageCount, currentPage: $currentPage, pageHtmls: $pageHtmls, pageLinks: $pageLinks, pageImages: $pageImages, loadingPages: $loadingPages, outline: $outline, bookTitle: $bookTitle, author: $author, documentPath: $documentPath, transientFeedback: $transientFeedback, ttsActive: $ttsActive, ttsCurrentPage: $ttsCurrentPage, engineMode: $engineMode, virtualPageCount: $virtualPageCount, currentVirtualPage: $currentVirtualPage)';
}


}

/// @nodoc
abstract mixin class $ReaderStateCopyWith<$Res>  {
  factory $ReaderStateCopyWith(ReaderState value, $Res Function(ReaderState) _then) = _$ReaderStateCopyWithImpl;
@useResult
$Res call({
 bool loading, Failure? failure, String? error, String? fileName, bool isReflowable, int pageCount, int currentPage, List<String?>? pageHtmls, List<List<ReaderLink>?>? pageLinks, List<ui.Image?>? pageImages, Set<int> loadingPages, List<OutlineItem>? outline, String? bookTitle, String? author, String? documentPath, UiFeedback? transientFeedback, bool ttsActive, int? ttsCurrentPage, ReaderEngineMode engineMode, int? virtualPageCount, int? currentVirtualPage
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
@pragma('vm:prefer-inline') @override $Res call({Object? loading = null,Object? failure = freezed,Object? error = freezed,Object? fileName = freezed,Object? isReflowable = null,Object? pageCount = null,Object? currentPage = null,Object? pageHtmls = freezed,Object? pageLinks = freezed,Object? pageImages = freezed,Object? loadingPages = null,Object? outline = freezed,Object? bookTitle = freezed,Object? author = freezed,Object? documentPath = freezed,Object? transientFeedback = freezed,Object? ttsActive = null,Object? ttsCurrentPage = freezed,Object? engineMode = null,Object? virtualPageCount = freezed,Object? currentVirtualPage = freezed,}) {
  return _then(_self.copyWith(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,isReflowable: null == isReflowable ? _self.isReflowable : isReflowable // ignore: cast_nullable_to_non_nullable
as bool,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,pageHtmls: freezed == pageHtmls ? _self.pageHtmls : pageHtmls // ignore: cast_nullable_to_non_nullable
as List<String?>?,pageLinks: freezed == pageLinks ? _self.pageLinks : pageLinks // ignore: cast_nullable_to_non_nullable
as List<List<ReaderLink>?>?,pageImages: freezed == pageImages ? _self.pageImages : pageImages // ignore: cast_nullable_to_non_nullable
as List<ui.Image?>?,loadingPages: null == loadingPages ? _self.loadingPages : loadingPages // ignore: cast_nullable_to_non_nullable
as Set<int>,outline: freezed == outline ? _self.outline : outline // ignore: cast_nullable_to_non_nullable
as List<OutlineItem>?,bookTitle: freezed == bookTitle ? _self.bookTitle : bookTitle // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,documentPath: freezed == documentPath ? _self.documentPath : documentPath // ignore: cast_nullable_to_non_nullable
as String?,transientFeedback: freezed == transientFeedback ? _self.transientFeedback : transientFeedback // ignore: cast_nullable_to_non_nullable
as UiFeedback?,ttsActive: null == ttsActive ? _self.ttsActive : ttsActive // ignore: cast_nullable_to_non_nullable
as bool,ttsCurrentPage: freezed == ttsCurrentPage ? _self.ttsCurrentPage : ttsCurrentPage // ignore: cast_nullable_to_non_nullable
as int?,engineMode: null == engineMode ? _self.engineMode : engineMode // ignore: cast_nullable_to_non_nullable
as ReaderEngineMode,virtualPageCount: freezed == virtualPageCount ? _self.virtualPageCount : virtualPageCount // ignore: cast_nullable_to_non_nullable
as int?,currentVirtualPage: freezed == currentVirtualPage ? _self.currentVirtualPage : currentVirtualPage // ignore: cast_nullable_to_non_nullable
as int?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool loading,  Failure? failure,  String? error,  String? fileName,  bool isReflowable,  int pageCount,  int currentPage,  List<String?>? pageHtmls,  List<List<ReaderLink>?>? pageLinks,  List<ui.Image?>? pageImages,  Set<int> loadingPages,  List<OutlineItem>? outline,  String? bookTitle,  String? author,  String? documentPath,  UiFeedback? transientFeedback,  bool ttsActive,  int? ttsCurrentPage,  ReaderEngineMode engineMode,  int? virtualPageCount,  int? currentVirtualPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.loading,_that.failure,_that.error,_that.fileName,_that.isReflowable,_that.pageCount,_that.currentPage,_that.pageHtmls,_that.pageLinks,_that.pageImages,_that.loadingPages,_that.outline,_that.bookTitle,_that.author,_that.documentPath,_that.transientFeedback,_that.ttsActive,_that.ttsCurrentPage,_that.engineMode,_that.virtualPageCount,_that.currentVirtualPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool loading,  Failure? failure,  String? error,  String? fileName,  bool isReflowable,  int pageCount,  int currentPage,  List<String?>? pageHtmls,  List<List<ReaderLink>?>? pageLinks,  List<ui.Image?>? pageImages,  Set<int> loadingPages,  List<OutlineItem>? outline,  String? bookTitle,  String? author,  String? documentPath,  UiFeedback? transientFeedback,  bool ttsActive,  int? ttsCurrentPage,  ReaderEngineMode engineMode,  int? virtualPageCount,  int? currentVirtualPage)  $default,) {final _that = this;
switch (_that) {
case _ReaderState():
return $default(_that.loading,_that.failure,_that.error,_that.fileName,_that.isReflowable,_that.pageCount,_that.currentPage,_that.pageHtmls,_that.pageLinks,_that.pageImages,_that.loadingPages,_that.outline,_that.bookTitle,_that.author,_that.documentPath,_that.transientFeedback,_that.ttsActive,_that.ttsCurrentPage,_that.engineMode,_that.virtualPageCount,_that.currentVirtualPage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool loading,  Failure? failure,  String? error,  String? fileName,  bool isReflowable,  int pageCount,  int currentPage,  List<String?>? pageHtmls,  List<List<ReaderLink>?>? pageLinks,  List<ui.Image?>? pageImages,  Set<int> loadingPages,  List<OutlineItem>? outline,  String? bookTitle,  String? author,  String? documentPath,  UiFeedback? transientFeedback,  bool ttsActive,  int? ttsCurrentPage,  ReaderEngineMode engineMode,  int? virtualPageCount,  int? currentVirtualPage)?  $default,) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.loading,_that.failure,_that.error,_that.fileName,_that.isReflowable,_that.pageCount,_that.currentPage,_that.pageHtmls,_that.pageLinks,_that.pageImages,_that.loadingPages,_that.outline,_that.bookTitle,_that.author,_that.documentPath,_that.transientFeedback,_that.ttsActive,_that.ttsCurrentPage,_that.engineMode,_that.virtualPageCount,_that.currentVirtualPage);case _:
  return null;

}
}

}

/// @nodoc


class _ReaderState extends ReaderState {
  const _ReaderState({this.loading = false, this.failure, this.error, this.fileName, this.isReflowable = false, this.pageCount = 0, this.currentPage = 0, final  List<String?>? pageHtmls, final  List<List<ReaderLink>?>? pageLinks, final  List<ui.Image?>? pageImages, final  Set<int> loadingPages = const <int>{}, final  List<OutlineItem>? outline, this.bookTitle, this.author, this.documentPath, this.transientFeedback, this.ttsActive = false, this.ttsCurrentPage, this.engineMode = ReaderEngineMode.customFlow, this.virtualPageCount, this.currentVirtualPage}): _pageHtmls = pageHtmls,_pageLinks = pageLinks,_pageImages = pageImages,_loadingPages = loadingPages,_outline = outline,super._();
  

@override@JsonKey() final  bool loading;
@override final  Failure? failure;
@override final  String? error;
@override final  String? fileName;
@override@JsonKey() final  bool isReflowable;
@override@JsonKey() final  int pageCount;
@override@JsonKey() final  int currentPage;
 final  List<String?>? _pageHtmls;
@override List<String?>? get pageHtmls {
  final value = _pageHtmls;
  if (value == null) return null;
  if (_pageHtmls is EqualUnmodifiableListView) return _pageHtmls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<List<ReaderLink>?>? _pageLinks;
@override List<List<ReaderLink>?>? get pageLinks {
  final value = _pageLinks;
  if (value == null) return null;
  if (_pageLinks is EqualUnmodifiableListView) return _pageLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<ui.Image?>? _pageImages;
@override List<ui.Image?>? get pageImages {
  final value = _pageImages;
  if (value == null) return null;
  if (_pageImages is EqualUnmodifiableListView) return _pageImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Set<int> _loadingPages;
@override@JsonKey() Set<int> get loadingPages {
  if (_loadingPages is EqualUnmodifiableSetView) return _loadingPages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_loadingPages);
}

 final  List<OutlineItem>? _outline;
@override List<OutlineItem>? get outline {
  final value = _outline;
  if (value == null) return null;
  if (_outline is EqualUnmodifiableListView) return _outline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? bookTitle;
@override final  String? author;
@override final  String? documentPath;
@override final  UiFeedback? transientFeedback;
@override@JsonKey() final  bool ttsActive;
@override final  int? ttsCurrentPage;
@override@JsonKey() final  ReaderEngineMode engineMode;
@override final  int? virtualPageCount;
@override final  int? currentVirtualPage;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReaderStateCopyWith<_ReaderState> get copyWith => __$ReaderStateCopyWithImpl<_ReaderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReaderState&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.error, error) || other.error == error)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.isReflowable, isReflowable) || other.isReflowable == isReflowable)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&const DeepCollectionEquality().equals(other._pageHtmls, _pageHtmls)&&const DeepCollectionEquality().equals(other._pageLinks, _pageLinks)&&const DeepCollectionEquality().equals(other._pageImages, _pageImages)&&const DeepCollectionEquality().equals(other._loadingPages, _loadingPages)&&const DeepCollectionEquality().equals(other._outline, _outline)&&(identical(other.bookTitle, bookTitle) || other.bookTitle == bookTitle)&&(identical(other.author, author) || other.author == author)&&(identical(other.documentPath, documentPath) || other.documentPath == documentPath)&&(identical(other.transientFeedback, transientFeedback) || other.transientFeedback == transientFeedback)&&(identical(other.ttsActive, ttsActive) || other.ttsActive == ttsActive)&&(identical(other.ttsCurrentPage, ttsCurrentPage) || other.ttsCurrentPage == ttsCurrentPage)&&(identical(other.engineMode, engineMode) || other.engineMode == engineMode)&&(identical(other.virtualPageCount, virtualPageCount) || other.virtualPageCount == virtualPageCount)&&(identical(other.currentVirtualPage, currentVirtualPage) || other.currentVirtualPage == currentVirtualPage));
}


@override
int get hashCode => Object.hashAll([runtimeType,loading,failure,error,fileName,isReflowable,pageCount,currentPage,const DeepCollectionEquality().hash(_pageHtmls),const DeepCollectionEquality().hash(_pageLinks),const DeepCollectionEquality().hash(_pageImages),const DeepCollectionEquality().hash(_loadingPages),const DeepCollectionEquality().hash(_outline),bookTitle,author,documentPath,transientFeedback,ttsActive,ttsCurrentPage,engineMode,virtualPageCount,currentVirtualPage]);

@override
String toString() {
  return 'ReaderState(loading: $loading, failure: $failure, error: $error, fileName: $fileName, isReflowable: $isReflowable, pageCount: $pageCount, currentPage: $currentPage, pageHtmls: $pageHtmls, pageLinks: $pageLinks, pageImages: $pageImages, loadingPages: $loadingPages, outline: $outline, bookTitle: $bookTitle, author: $author, documentPath: $documentPath, transientFeedback: $transientFeedback, ttsActive: $ttsActive, ttsCurrentPage: $ttsCurrentPage, engineMode: $engineMode, virtualPageCount: $virtualPageCount, currentVirtualPage: $currentVirtualPage)';
}


}

/// @nodoc
abstract mixin class _$ReaderStateCopyWith<$Res> implements $ReaderStateCopyWith<$Res> {
  factory _$ReaderStateCopyWith(_ReaderState value, $Res Function(_ReaderState) _then) = __$ReaderStateCopyWithImpl;
@override @useResult
$Res call({
 bool loading, Failure? failure, String? error, String? fileName, bool isReflowable, int pageCount, int currentPage, List<String?>? pageHtmls, List<List<ReaderLink>?>? pageLinks, List<ui.Image?>? pageImages, Set<int> loadingPages, List<OutlineItem>? outline, String? bookTitle, String? author, String? documentPath, UiFeedback? transientFeedback, bool ttsActive, int? ttsCurrentPage, ReaderEngineMode engineMode, int? virtualPageCount, int? currentVirtualPage
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
@override @pragma('vm:prefer-inline') $Res call({Object? loading = null,Object? failure = freezed,Object? error = freezed,Object? fileName = freezed,Object? isReflowable = null,Object? pageCount = null,Object? currentPage = null,Object? pageHtmls = freezed,Object? pageLinks = freezed,Object? pageImages = freezed,Object? loadingPages = null,Object? outline = freezed,Object? bookTitle = freezed,Object? author = freezed,Object? documentPath = freezed,Object? transientFeedback = freezed,Object? ttsActive = null,Object? ttsCurrentPage = freezed,Object? engineMode = null,Object? virtualPageCount = freezed,Object? currentVirtualPage = freezed,}) {
  return _then(_ReaderState(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,isReflowable: null == isReflowable ? _self.isReflowable : isReflowable // ignore: cast_nullable_to_non_nullable
as bool,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,pageHtmls: freezed == pageHtmls ? _self._pageHtmls : pageHtmls // ignore: cast_nullable_to_non_nullable
as List<String?>?,pageLinks: freezed == pageLinks ? _self._pageLinks : pageLinks // ignore: cast_nullable_to_non_nullable
as List<List<ReaderLink>?>?,pageImages: freezed == pageImages ? _self._pageImages : pageImages // ignore: cast_nullable_to_non_nullable
as List<ui.Image?>?,loadingPages: null == loadingPages ? _self._loadingPages : loadingPages // ignore: cast_nullable_to_non_nullable
as Set<int>,outline: freezed == outline ? _self._outline : outline // ignore: cast_nullable_to_non_nullable
as List<OutlineItem>?,bookTitle: freezed == bookTitle ? _self.bookTitle : bookTitle // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,documentPath: freezed == documentPath ? _self.documentPath : documentPath // ignore: cast_nullable_to_non_nullable
as String?,transientFeedback: freezed == transientFeedback ? _self.transientFeedback : transientFeedback // ignore: cast_nullable_to_non_nullable
as UiFeedback?,ttsActive: null == ttsActive ? _self.ttsActive : ttsActive // ignore: cast_nullable_to_non_nullable
as bool,ttsCurrentPage: freezed == ttsCurrentPage ? _self.ttsCurrentPage : ttsCurrentPage // ignore: cast_nullable_to_non_nullable
as int?,engineMode: null == engineMode ? _self.engineMode : engineMode // ignore: cast_nullable_to_non_nullable
as ReaderEngineMode,virtualPageCount: freezed == virtualPageCount ? _self.virtualPageCount : virtualPageCount // ignore: cast_nullable_to_non_nullable
as int?,currentVirtualPage: freezed == currentVirtualPage ? _self.currentVirtualPage : currentVirtualPage // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
