import 'dart:isolate';
import 'dart:typed_data';

import '../abstracts/document_reader.dart';
import '../abstracts/reflowable_document_reader.dart';
import '../readers/document_reader_factory.dart';
import '../readers/html_text_extractor.dart';
import '../transformers/footnote_transformer.dart';
import 'document_isolate_messages.dart';

/// Entry point function executed inside the dedicated document isolate.
void documentIsolateEntryPoint(SendPort hostSendPort) {
  final receivePort = ReceivePort();
  hostSendPort.send(receivePort.sendPort);

  DocumentReader? reader;

  receivePort.listen((message) async {
    if (message is! DocumentRequest) return;

    try {
      await message.when(
        open: (id, filePath) async {
          reader?.dispose();
          final opened = await DocumentReaderFactory().open(filePath);
          reader = opened;

          final sectionCount =
              opened is ReflowableDocumentReader ? opened.sectionCount : 0;

          hostSendPort.send(
            DocumentResponse.opened(
              id: id,
              title: opened.title,
              metadata: opened.metadata,
              outline: opened.outline,
              sectionCount: sectionCount,
              coverImagePath: opened.coverImagePath,
              isReflowable: opened.isReflowable,
              format: opened.format,
            ),
          );
        },
        loadSectionHtml: (id, sectionIndex) {
          if (reader is! ReflowableDocumentReader) {
            throw StateError('Current document is not reflowable');
          }
          final html =
              (reader as ReflowableDocumentReader).loadSectionHtml(sectionIndex);
          hostSendPort.send(
            DocumentResponse.sectionHtml(id: id, html: html),
          );
        },
        extractSectionText: (id, sectionIndex) {
          if (reader is! ReflowableDocumentReader) {
            throw StateError('Current document is not reflowable');
          }
          final text =
              (reader as ReflowableDocumentReader).extractSectionText(sectionIndex);
          hostSendPort.send(
            DocumentResponse.sectionText(id: id, text: text),
          );
        },
        extractSectionSpeechText: (id, sectionIndex) {
          if (reader is! ReflowableDocumentReader) {
            throw StateError('Current document is not reflowable');
          }
          final speechText =
              (reader as ReflowableDocumentReader).extractSectionSpeechText(
                sectionIndex,
              );
          hostSendPort.send(
            DocumentResponse.sectionSpeechText(
              id: id,
              speechText: speechText,
            ),
          );
        },
        resolveFootnote: (id, url, currentChapterIndex) {
          if (reader is! ReflowableDocumentReader || url.trim().isEmpty) {
            hostSendPort.send(
              DocumentResponse.footnoteResolved(id: id, footnote: null),
            );
            return;
          }

          final reflow = reader as ReflowableDocumentReader;
          String? targetHref;
          String? anchorId;
          if (url.contains('#')) {
            final parts = url.split('#');
            targetHref = parts.first.trim().isEmpty ? null : parts.first.trim();
            anchorId = parts.length > 1 ? parts[1].trim() : null;
          } else {
            targetHref = url.trim();
          }

          if (anchorId == null || anchorId.isEmpty) {
            hostSendPort.send(
              DocumentResponse.footnoteResolved(id: id, footnote: null),
            );
            return;
          }

          int? targetSectionIndex;
          if (targetHref != null && targetHref.isNotEmpty) {
            targetSectionIndex = reflow.resolveSectionIndex(targetHref);
          }
          targetSectionIndex ??= currentChapterIndex;

          if (targetSectionIndex != null &&
              targetSectionIndex >= 0 &&
              targetSectionIndex < reflow.sectionCount) {
            final html = reflow.loadSectionHtml(targetSectionIndex);
            final footnote = FootnoteTransformer.findFootnote(html, anchorId);
            hostSendPort.send(
              DocumentResponse.footnoteResolved(id: id, footnote: footnote),
            );
            return;
          }

          hostSendPort.send(
            DocumentResponse.footnoteResolved(id: id, footnote: null),
          );
        },
        loadAsset: (id, assetPath, sectionIndex) {
          if (reader == null) {
            throw StateError('No document is currently open');
          }

          Uint8List? bytes;
          if (sectionIndex != null && reader is ReflowableDocumentReader) {
            final resolved = (reader as ReflowableDocumentReader)
                .resolveAssetPath(sectionIndex, assetPath);
            bytes = reader!.loadAsset(resolved) ?? reader!.loadAsset(assetPath);
          } else {
            bytes = reader!.loadAsset(assetPath);
          }

          final transferable = bytes != null && bytes.isNotEmpty
              ? TransferableTypedData.fromList([bytes])
              : null;

          hostSendPort.send(
            DocumentResponse.assetLoaded(id: id, assetData: transferable),
          );
        },
        resolveSectionIndex: (id, href) {
          if (reader is! ReflowableDocumentReader) {
            throw StateError('Current document is not reflowable');
          }
          final idx =
              (reader as ReflowableDocumentReader).resolveSectionIndex(href);
          hostSendPort.send(
            DocumentResponse.sectionIndexResolved(
              id: id,
              sectionIndex: idx,
            ),
          );
        },
        resolveAssetPath: (id, sectionIndex, relativePath) {
          if (reader is! ReflowableDocumentReader) {
            throw StateError('Current document is not reflowable');
          }
          final resolved = (reader as ReflowableDocumentReader)
              .resolveAssetPath(sectionIndex, relativePath);
          hostSendPort.send(
            DocumentResponse.assetPathResolved(
              id: id,
              resolvedPath: resolved,
            ),
          );
        },
        dispose: (id) {
          reader?.dispose();
          reader = null;
          hostSendPort.send(DocumentResponse.disposed(id: id));
          receivePort.close();
        },
      );
    } catch (e, st) {
      hostSendPort.send(
        DocumentResponse.error(
          id: message.id,
          message: e.toString(),
          stackTrace: st.toString(),
        ),
      );
    }
  });
}
