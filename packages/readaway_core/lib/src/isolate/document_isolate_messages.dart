import 'dart:isolate';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/models.dart';

part 'document_isolate_messages.freezed.dart';

/// Request sent from the host isolate to the document worker isolate.
@Freezed(toJson: false, fromJson: false)
sealed class DocumentRequest with _$DocumentRequest {
  const factory DocumentRequest.open({
    required int id,
    required String filePath,
  }) = _OpenDocReq;

  const factory DocumentRequest.loadSectionHtml({
    required int id,
    required int sectionIndex,
  }) = _LoadSectionHtmlReq;

  const factory DocumentRequest.extractSectionText({
    required int id,
    required int sectionIndex,
  }) = _ExtractSectionTextReq;

  const factory DocumentRequest.extractSectionSpeechText({
    required int id,
    required int sectionIndex,
  }) = _ExtractSectionSpeechTextReq;

  const factory DocumentRequest.resolveFootnote({
    required int id,
    required String url,
    int? currentChapterIndex,
  }) = _ResolveFootnoteReq;

  const factory DocumentRequest.loadAsset({
    required int id,
    required String assetPath,
    int? sectionIndex,
  }) = _LoadAssetReq;

  const factory DocumentRequest.resolveSectionIndex({
    required int id,
    required String href,
  }) = _ResolveSectionIndexReq;

  const factory DocumentRequest.resolveAssetPath({
    required int id,
    required int sectionIndex,
    required String relativePath,
  }) = _ResolveAssetPathReq;

  const factory DocumentRequest.dispose({
    required int id,
  }) = _DisposeDocReq;
}

/// Response returned from the document worker isolate to the host isolate.
@Freezed(toJson: false, fromJson: false)
sealed class DocumentResponse with _$DocumentResponse {
  const factory DocumentResponse.opened({
    required int id,
    required String? title,
    required DocumentMetadata? metadata,
    required List<OutlineItem> outline,
    required int sectionCount,
    required String? coverImagePath,
    required bool isReflowable,
    required String format,
  }) = _OpenedDocResp;

  const factory DocumentResponse.sectionHtml({
    required int id,
    required String html,
  }) = _SectionHtmlResp;

  const factory DocumentResponse.sectionText({
    required int id,
    required String text,
  }) = _SectionTextResp;

  const factory DocumentResponse.sectionSpeechText({
    required int id,
    required String speechText,
  }) = _SectionSpeechTextResp;

  const factory DocumentResponse.footnoteResolved({
    required int id,
    required FootnoteItem? footnote,
  }) = _FootnoteResolvedResp;

  const factory DocumentResponse.assetLoaded({
    required int id,
    required TransferableTypedData? assetData,
  }) = _AssetLoadedResp;

  const factory DocumentResponse.sectionIndexResolved({
    required int id,
    required int? sectionIndex,
  }) = _SectionIndexResolvedResp;

  const factory DocumentResponse.assetPathResolved({
    required int id,
    required String resolvedPath,
  }) = _AssetPathResolvedResp;

  const factory DocumentResponse.disposed({
    required int id,
  }) = _DisposedResp;

  const factory DocumentResponse.error({
    required int id,
    required String message,
    String? stackTrace,
  }) = _ErrorResp;
}
