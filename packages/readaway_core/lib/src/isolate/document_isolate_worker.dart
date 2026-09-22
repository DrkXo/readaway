import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import '../abstracts/document_reader.dart';
import '../abstracts/page_document_reader.dart';
import '../abstracts/reflowable_document_reader.dart';
import '../errors/document_exception.dart';
import '../readers/document_reader_factory.dart';
import '../readers/html_text_extractor.dart';
import '../transformers/footnote_transformer.dart';
import 'document_isolate_messages.dart';

/// Lightweight LinkedHashMap-based LRU cache for the document isolate worker.
class _IsolateLruCache<K, V> {
  _IsolateLruCache({this.maximumSize = 50});

  final int maximumSize;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  V? get(K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > maximumSize) {
      _map.remove(_map.keys.first);
    }
  }

  bool containsKey(K key) => _map.containsKey(key);

  void clear() => _map.clear();
}

/// Entry point function executed inside the dedicated document isolate.
void documentIsolateEntryPoint(SendPort hostSendPort) {
  final receivePort = ReceivePort();
  hostSendPort.send(receivePort.sendPort);

  DocumentReader? reader;

  // Single-source-of-truth isolate memory caches
  final htmlCache = _IsolateLruCache<int, String>(maximumSize: 40);
  final textCache = _IsolateLruCache<int, String>(maximumSize: 40);
  final speechTextCache = _IsolateLruCache<int, String>(maximumSize: 40);
  final assetCache = _IsolateLruCache<String, Uint8List>(maximumSize: 60);
  final pageImageCache = _IsolateLruCache<String, Uint8List>(maximumSize: 30);

  void clearCaches() {
    htmlCache.clear();
    textCache.clear();
    speechTextCache.clear();
    assetCache.clear();
    pageImageCache.clear();
  }

  void schedulePrefetch(int currentIndex, int sectionCount) {
    // Lazily warm neighboring chapters in the isolate during idle time
    Future.microtask(() {
      if (reader is! ReflowableDocumentReader) return;
      final reflow = reader as ReflowableDocumentReader;

      final next = currentIndex + 1;
      if (next < sectionCount && !htmlCache.containsKey(next)) {
        try {
          final html = reflow.loadSectionHtml(next);
          htmlCache.put(next, html);
        } catch (_) {}
      }

      final prev = currentIndex - 1;
      if (prev >= 0 && !htmlCache.containsKey(prev)) {
        try {
          final html = reflow.loadSectionHtml(prev);
          htmlCache.put(prev, html);
        } catch (_) {}
      }
    });
  }

  receivePort.listen((message) async {
    if (message is! DocumentRequest) return;

    try {
      await message.when(
        open: (id, filePath, password) async {
          reader?.dispose();
          clearCaches();

          try {
            final opened = await DocumentReaderFactory().open(
              filePath,
              password: password,
            );
            reader = opened;

            final sectionCount =
                opened is ReflowableDocumentReader ? opened.sectionCount : 0;
            final pageCount =
                opened is PageDocumentReader ? opened.pageCount : 0;

            // Warm up section 0 if reflowable
            if (sectionCount > 0 && opened is ReflowableDocumentReader) {
              try {
                final html = opened.loadSectionHtml(0);
                htmlCache.put(0, html);
              } catch (_) {}
            }

            hostSendPort.send(
              DocumentResponse.opened(
                id: id,
                title: opened.title,
                metadata: opened.metadata,
                outline: opened.outline,
                sectionCount: sectionCount,
                pageCount: pageCount,
                coverImagePath: opened.coverImagePath,
                isReflowable: opened.isReflowable,
                format: opened.format,
              ),
            );
          } on DocumentEncryptedException catch (e) {
            hostSendPort.send(
              DocumentResponse.encryptedError(
                id: id,
                message: e.message,
                isInvalidPassword: e.isInvalidPassword,
              ),
            );
          }
        },
        loadSectionHtml: (id, sectionIndex) {
          if (reader is! ReflowableDocumentReader) {
            throw StateError('Current document is not reflowable');
          }
          final reflow = reader as ReflowableDocumentReader;

          String? html = htmlCache.get(sectionIndex);
          if (html == null) {
            html = reflow.loadSectionHtml(sectionIndex);
            htmlCache.put(sectionIndex, html);
          }

          schedulePrefetch(sectionIndex, reflow.sectionCount);

          hostSendPort.send(
            DocumentResponse.sectionHtml(id: id, html: html),
          );
        },
        extractSectionText: (id, sectionIndex) {
          if (reader is! ReflowableDocumentReader) {
            throw StateError('Current document is not reflowable');
          }
          final reflow = reader as ReflowableDocumentReader;

          String? text = textCache.get(sectionIndex);
          if (text == null) {
            text = reflow.extractSectionText(sectionIndex);
            textCache.put(sectionIndex, text);
          }

          hostSendPort.send(
            DocumentResponse.sectionText(id: id, text: text),
          );
        },
        extractSectionSpeechText: (id, sectionIndex) {
          if (reader is! ReflowableDocumentReader) {
            throw StateError('Current document is not reflowable');
          }
          final reflow = reader as ReflowableDocumentReader;

          String? speechText = speechTextCache.get(sectionIndex);
          if (speechText == null) {
            speechText = reflow.extractSectionSpeechText(sectionIndex);
            speechTextCache.put(sectionIndex, speechText);
          }

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
            final html = htmlCache.get(targetSectionIndex) ??
                reflow.loadSectionHtml(targetSectionIndex);
            htmlCache.put(targetSectionIndex, html);
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

          final cacheKey = '$sectionIndex:$assetPath';
          Uint8List? bytes = assetCache.get(cacheKey);

          if (bytes == null) {
            if (sectionIndex != null && reader is ReflowableDocumentReader) {
              final resolved = (reader as ReflowableDocumentReader)
                  .resolveAssetPath(sectionIndex, assetPath);
              bytes = reader!.loadAsset(resolved) ?? reader!.loadAsset(assetPath);
            } else {
              bytes = reader!.loadAsset(assetPath);
            }
            if (bytes != null && bytes.isNotEmpty) {
              assetCache.put(cacheKey, bytes);
            }
          }

          final transferable = bytes != null && bytes.isNotEmpty
              ? TransferableTypedData.fromList([bytes])
              : null;

          hostSendPort.send(
            DocumentResponse.assetLoaded(id: id, assetData: transferable),
          );
        },
        loadPageImage: (id, pageIndex, scale, targetWidth, targetHeight) async {
          if (reader is! PageDocumentReader) {
            throw StateError('Current document is not a fixed-layout document');
          }
          final pageReader = reader as PageDocumentReader;
          final cacheKey = '$pageIndex:$scale:$targetWidth:$targetHeight';

          Uint8List? bytes = pageImageCache.get(cacheKey);
          if (bytes == null) {
            bytes = await pageReader.loadPageImage(
              pageIndex,
              scale: scale,
              targetWidth: targetWidth,
              targetHeight: targetHeight,
            );
            if (bytes.isNotEmpty) {
              pageImageCache.put(cacheKey, bytes);
            }
          }

          final transferable = bytes.isNotEmpty
              ? TransferableTypedData.fromList([bytes])
              : null;

          hostSendPort.send(
            DocumentResponse.pageImageLoaded(id: id, imageData: transferable),
          );
        },
        getPageSize: (id, pageIndex) {
          if (reader is! PageDocumentReader) {
            throw StateError('Current document is not a fixed-layout document');
          }
          final pageReader = reader as PageDocumentReader;
          final pageSize = pageReader.getPageSize(pageIndex);
          hostSendPort.send(
            DocumentResponse.pageSizeLoaded(id: id, pageSize: pageSize),
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
          clearCaches();
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
