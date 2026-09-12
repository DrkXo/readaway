// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentMetadata _$DocumentMetadataFromJson(Map<String, dynamic> json) =>
    _DocumentMetadata(
      title: json['title'] as String?,
      creator: json['creator'] as String?,
      language: json['language'] as String?,
      identifier: json['identifier'] as String?,
      publisher: json['publisher'] as String?,
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      modified: json['modified'] == null
          ? null
          : DateTime.parse(json['modified'] as String),
    );

Map<String, dynamic> _$DocumentMetadataToJson(_DocumentMetadata instance) =>
    <String, dynamic>{
      'title': instance.title,
      'creator': instance.creator,
      'language': instance.language,
      'identifier': instance.identifier,
      'publisher': instance.publisher,
      'description': instance.description,
      'subject': instance.subject,
      'modified': instance.modified?.toIso8601String(),
    };

_DocumentSection _$DocumentSectionFromJson(Map<String, dynamic> json) =>
    _DocumentSection(
      index: (json['index'] as num).toInt(),
      id: json['id'] as String,
      href: json['href'] as String,
      mediaType: json['mediaType'] as String,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$DocumentSectionToJson(_DocumentSection instance) =>
    <String, dynamic>{
      'index': instance.index,
      'id': instance.id,
      'href': instance.href,
      'mediaType': instance.mediaType,
      'title': instance.title,
    };

_OpfData _$OpfDataFromJson(Map<String, dynamic> json) => _OpfData(
  metadata: DocumentMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
  sections: (json['sections'] as List<dynamic>)
      .map((e) => DocumentSection.fromJson(e as Map<String, dynamic>))
      .toList(),
  ncxHref: json['ncxHref'] as String?,
  navHref: json['navHref'] as String?,
  opfDir: json['opfDir'] as String? ?? '',
  coverImagePath: json['coverImagePath'] as String?,
);

Map<String, dynamic> _$OpfDataToJson(_OpfData instance) => <String, dynamic>{
  'metadata': instance.metadata,
  'sections': instance.sections,
  'ncxHref': instance.ncxHref,
  'navHref': instance.navHref,
  'opfDir': instance.opfDir,
  'coverImagePath': instance.coverImagePath,
};

_OutlineItem _$OutlineItemFromJson(Map<String, dynamic> json) => _OutlineItem(
  title: json['title'] as String,
  href: json['href'] as String?,
  level: (json['level'] as num?)?.toInt() ?? 0,
  chapterIndex: (json['chapterIndex'] as num?)?.toInt(),
  children:
      (json['children'] as List<dynamic>?)
          ?.map((e) => OutlineItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$OutlineItemToJson(_OutlineItem instance) =>
    <String, dynamic>{
      'title': instance.title,
      'href': instance.href,
      'level': instance.level,
      'chapterIndex': instance.chapterIndex,
      'children': instance.children,
    };

_PageCoordinate _$PageCoordinateFromJson(Map<String, dynamic> json) =>
    _PageCoordinate(
      chapterIndex: (json['chapterIndex'] as num).toInt(),
      pageInChapter: (json['pageInChapter'] as num).toInt(),
      totalPagesInChapter: (json['totalPagesInChapter'] as num).toInt(),
      globalPage: (json['globalPage'] as num).toInt(),
    );

Map<String, dynamic> _$PageCoordinateToJson(_PageCoordinate instance) =>
    <String, dynamic>{
      'chapterIndex': instance.chapterIndex,
      'pageInChapter': instance.pageInChapter,
      'totalPagesInChapter': instance.totalPagesInChapter,
      'globalPage': instance.globalPage,
    };

_PaginationState _$PaginationStateFromJson(Map<String, dynamic> json) =>
    _PaginationState(
      chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 0,
      pageInChapter: (json['pageInChapter'] as num?)?.toInt() ?? 0,
      totalPagesInChapter: (json['totalPagesInChapter'] as num?)?.toInt() ?? 1,
      globalPage: (json['globalPage'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      viewportHeight: (json['viewportHeight'] as num?)?.toDouble() ?? 0.0,
      chapterHeights:
          (json['chapterHeights'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), (e as num).toDouble()),
          ) ??
          const {},
      chapterPageCounts:
          (json['chapterPageCounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$PaginationStateToJson(_PaginationState instance) =>
    <String, dynamic>{
      'chapterIndex': instance.chapterIndex,
      'pageInChapter': instance.pageInChapter,
      'totalPagesInChapter': instance.totalPagesInChapter,
      'globalPage': instance.globalPage,
      'totalPages': instance.totalPages,
      'viewportHeight': instance.viewportHeight,
      'chapterHeights': instance.chapterHeights.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'chapterPageCounts': instance.chapterPageCounts.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
    };

_ReadingAnchor _$ReadingAnchorFromJson(Map<String, dynamic> json) =>
    _ReadingAnchor(
      chapterIndex: (json['chapterIndex'] as num).toInt(),
      progressionInChapter: (json['progressionInChapter'] as num).toDouble(),
    );

Map<String, dynamic> _$ReadingAnchorToJson(_ReadingAnchor instance) =>
    <String, dynamic>{
      'chapterIndex': instance.chapterIndex,
      'progressionInChapter': instance.progressionInChapter,
    };
