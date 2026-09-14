// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DetectedEncoding _$DetectedEncodingFromJson(Map<String, dynamic> json) =>
    _DetectedEncoding(
      name: json['name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      hasBom: json['hasBom'] as bool? ?? false,
    );

Map<String, dynamic> _$DetectedEncodingToJson(_DetectedEncoding instance) =>
    <String, dynamic>{
      'name': instance.name,
      'confidence': instance.confidence,
      'hasBom': instance.hasBom,
    };

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

_FootnoteItem _$FootnoteItemFromJson(Map<String, dynamic> json) =>
    _FootnoteItem(
      id: json['id'] as String,
      referenceId: json['referenceId'] as String?,
      title: json['title'] as String?,
      contentHtml: json['contentHtml'] as String,
      type: json['type'] as String? ?? 'footnote',
    );

Map<String, dynamic> _$FootnoteItemToJson(_FootnoteItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'referenceId': instance.referenceId,
      'title': instance.title,
      'contentHtml': instance.contentHtml,
      'type': instance.type,
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

_TransformContext _$TransformContextFromJson(Map<String, dynamic> json) =>
    _TransformContext(
      content: json['content'] as String,
      language: json['language'] as String?,
      vertical: json['vertical'] as bool? ?? false,
      replaceQuotationMarks: json['replaceQuotationMarks'] as bool? ?? false,
      convertChineseVariant: json['convertChineseVariant'] as String?,
      overrideLayout: json['overrideLayout'] as bool? ?? false,
      extra:
          json['extra'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$TransformContextToJson(_TransformContext instance) =>
    <String, dynamic>{
      'content': instance.content,
      'language': instance.language,
      'vertical': instance.vertical,
      'replaceQuotationMarks': instance.replaceQuotationMarks,
      'convertChineseVariant': instance.convertChineseVariant,
      'overrideLayout': instance.overrideLayout,
      'extra': instance.extra,
    };

_TtsWordSpan _$TtsWordSpanFromJson(Map<String, dynamic> json) => _TtsWordSpan(
  word: json['word'] as String,
  startOffset: (json['startOffset'] as num).toInt(),
  endOffset: (json['endOffset'] as num).toInt(),
);

Map<String, dynamic> _$TtsWordSpanToJson(_TtsWordSpan instance) =>
    <String, dynamic>{
      'word': instance.word,
      'startOffset': instance.startOffset,
      'endOffset': instance.endOffset,
    };

_TtsChunk _$TtsChunkFromJson(Map<String, dynamic> json) => _TtsChunk(
  text: json['text'] as String,
  startOffset: (json['startOffset'] as num).toInt(),
  endOffset: (json['endOffset'] as num).toInt(),
  spokenText: json['spokenText'] as String?,
  rawStartOffset: (json['rawStartOffset'] as num?)?.toInt(),
  rawEndOffset: (json['rawEndOffset'] as num?)?.toInt(),
  isParagraphEnd: json['isParagraphEnd'] as bool? ?? false,
  paragraphIndex: (json['paragraphIndex'] as num?)?.toInt() ?? 0,
  words: json['words'] == null
      ? const <TtsWordSpan>[]
      : _decodeWordSpans(json['words']),
  language: json['language'] as String? ?? 'en',
);

Map<String, dynamic> _$TtsChunkToJson(_TtsChunk instance) => <String, dynamic>{
  'text': instance.text,
  'startOffset': instance.startOffset,
  'endOffset': instance.endOffset,
  'spokenText': instance.spokenText,
  'rawStartOffset': instance.rawStartOffset,
  'rawEndOffset': instance.rawEndOffset,
  'isParagraphEnd': instance.isParagraphEnd,
  'paragraphIndex': instance.paragraphIndex,
  'words': _encodeWordSpans(instance.words),
  'language': instance.language,
};

_TxtChapter _$TxtChapterFromJson(Map<String, dynamic> json) => _TxtChapter(
  index: (json['index'] as num).toInt(),
  title: json['title'] as String,
  contentHtml: json['contentHtml'] as String,
  isVolume: json['isVolume'] as bool? ?? false,
  detected: json['detected'] as bool? ?? true,
);

Map<String, dynamic> _$TxtChapterToJson(_TxtChapter instance) =>
    <String, dynamic>{
      'index': instance.index,
      'title': instance.title,
      'contentHtml': instance.contentHtml,
      'isVolume': instance.isVolume,
      'detected': instance.detected,
    };

_TxtMetadata _$TxtMetadataFromJson(Map<String, dynamic> json) => _TxtMetadata(
  title: json['title'] as String,
  author: json['author'] as String?,
  language: json['language'] as String?,
  encoding: json['encoding'] as String,
  identifier: json['identifier'] as String?,
);

Map<String, dynamic> _$TxtMetadataToJson(_TxtMetadata instance) =>
    <String, dynamic>{
      'title': instance.title,
      'author': instance.author,
      'language': instance.language,
      'encoding': instance.encoding,
      'identifier': instance.identifier,
    };
