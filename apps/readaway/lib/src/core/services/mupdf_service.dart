import 'dart:isolate';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:mupdf/mupdf.dart';

import 'isolate_service.dart';
import 'logging_service.dart';

export 'package:mupdf/mupdf.dart';

@singleton
class MuPdfService {
  static const String _isolateName = 'mupdf';
  final IsolateService _isolateService;
  final LoggingService _loggingService;

  Logger get _log => _loggingService.logger;

  MuPdfService({
    required this._isolateService,
    required this._loggingService,
  });

  Future<void> _ensureIsolate() async {
    if (_isolateService.isSpawned(_isolateName)) return;

    _log.info('Spawning MuPdfService background isolate...');
    await _isolateService.spawn(
      name: _isolateName,
      entryPoint: _isolateEntryPoint,
    );
    _log.info('[MuPdfService] background isolate ready.');
  }

  int _nextId = 0;
  int _generateId() => ++_nextId;

  Future<T> _sendCommand<T>(dynamic command) async {
    await _ensureIsolate();
    return _isolateService.sendCommand<T>(_isolateName, command);
  }

  Future<void> openDocument(String path) {
    return _sendCommand({
      'id': _generateId(),
      'type': 'open',
      'path': path,
    });
  }

  Future<String?> getMetaData(String key) {
    return _sendCommand<String?>({
      'id': _generateId(),
      'type': 'getMetaData',
      'key': key,
    });
  }

  Future<int> getPageCount() {
    return _sendCommand<int>({
      'id': _generateId(),
      'type': 'getPageCount',
    });
  }

  Future<int> getChapterCount() {
    return _sendCommand<int>({
      'id': _generateId(),
      'type': 'getChapterCount',
    });
  }

  Future<int> getSpineCount() {
    return _sendCommand<int>({
      'id': _generateId(),
      'type': 'getSpineCount',
    });
  }

  Future<String?> loadChapterSource(int chapter) {
    return _sendCommand<String?>({
      'id': _generateId(),
      'type': 'loadChapterSource',
      'chapter': chapter,
    });
  }

  Future<Uint8List?> loadChapterAsset(String assetPath) {
    return _sendCommand<Uint8List?>({
      'id': _generateId(),
      'type': 'loadChapterAsset',
      'path': assetPath,
    });
  }

  Future<int> getChapterPageCount(int chapter) {
    return _sendCommand<int>({
      'id': _generateId(),
      'type': 'getChapterPageCount',
      'chapter': chapter,
    });
  }

  Future<List<OutlineItem>> getOutLine() async {
    return _sendCommand<List<OutlineItem>>({
      'id': _generateId(),
      'type': 'getOutLine',
    });
  }

  Future<bool> isReflowable() {
    return _sendCommand<bool>({
      'id': _generateId(),
      'type': 'isReflowable',
    });
  }

  Future<bool> hasPermission(int permission) {
    return _sendCommand<bool>({
      'id': _generateId(),
      'type': 'hasPermission',
      'permission': permission,
    });
  }

  Future<bool> needsPassword() {
    return _sendCommand<bool>({
      'id': _generateId(),
      'type': 'needsPassword',
    });
  }

  Future<void> layoutReflowable({
    required double width,
    required double height,
    double em = 12.0,
  }) {
    return _sendCommand({
      'id': _generateId(),
      'type': 'layoutReflowable',
      'width': width,
      'height': height,
      'em': em,
    });
  }

  Future<void> styleReflowable({
    bool usePublisherCss = true,
    String? userCss,
  }) {
    return _sendCommand({
      'id': _generateId(),
      'type': 'styleReflowable',
      'usePublisherCss': usePublisherCss,
      'userCss': userCss,
    });
  }

  Future<void> setUserCss(String css) {
    return _sendCommand({
      'id': _generateId(),
      'type': 'setUserCss',
      'css': css,
    });
  }

  Future<int> makeBookmark({required int chapter, required int page}) {
    return _sendCommand<int>({
      'id': _generateId(),
      'type': 'makeBookmark',
      'chapter': chapter,
      'page': page,
    });
  }

  Future<MuPdfLocation> lookupBookmark(int bookmark) {
    return _sendCommand<MuPdfLocation>({
      'id': _generateId(),
      'type': 'lookupBookmark',
      'bookmark': bookmark,
    });
  }

  Future<MuPdfLocation> locationFromPage(int pageNumber) {
    return _sendCommand<MuPdfLocation>({
      'id': _generateId(),
      'type': 'locationFromPage',
      'pageNumber': pageNumber,
    });
  }

  Future<int> pageFromLocation(MuPdfLocation loc) {
    return _sendCommand<int>({
      'id': _generateId(),
      'type': 'pageFromLocation',
      'chapter': loc.chapter,
      'page': loc.page,
    });
  }

  Future<String?> extractPageHtml(int pageIndex) {
    return _sendCommand<String?>({
      'id': _generateId(),
      'type': 'extractHtml',
      'index': pageIndex,
    });
  }

  Future<String?> extractPageText(int pageIndex) {
    return _sendCommand<String?>({
      'id': _generateId(),
      'type': 'extractText',
      'index': pageIndex,
    });
  }

  Future<List<PageLink>> getPageLinks(int pageIndex) {
    return _sendCommand<List<PageLink>>({
      'id': _generateId(),
      'type': 'extractLinks',
      'index': pageIndex,
    });
  }

  Future<int> resolveUri(String uri) {
    return _sendCommand<int>({
      'id': _generateId(),
      'type': 'resolveUri',
      'uri': uri,
    });
  }

  Future<Map<String, dynamic>?> renderPage(
    int pageIndex, {
    double scaleX = 2.0,
    double scaleY = 2.0,
  }) {
    return _sendCommand<Map<String, dynamic>?>({
      'id': _generateId(),
      'type': 'renderPage',
      'pageIndex': pageIndex,
      'scaleX': scaleX,
      'scaleY': scaleY,
    });
  }

  Future<Map<String, dynamic>?> renderPageFromFile(
    String filePath,
    int pageIndex, {
    double scaleX = 1.0,
    double scaleY = 1.0,
  }) {
    return _sendCommand<Map<String, dynamic>?>({
      'id': _generateId(),
      'type': 'renderPageFromFile',
      'path': filePath,
      'pageIndex': pageIndex,
      'scaleX': scaleX,
      'scaleY': scaleY,
    });
  }

  Future<void> closeDocument() {
    return _sendCommand({
      'id': _generateId(),
      'type': 'close',
    });
  }

  @disposeMethod
  Future<void> dispose() async {
    await _isolateService.disposeIsolate(_isolateName);
  }

  static void _isolateEntryPoint(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    MuPdfDocument? doc;

    receivePort.listen((message) {
      if (message is Map) {
        final id = message['id'];
        final type = message['type'];

        try {
          if (type == 'open') {
            doc?.dispose();
            doc = null;
            doc = MuPdfDocument.openFile(message['path'] as String);
            mainSendPort.send({'id': id, 'result': null});
          } else if (type == 'getMetaData') {
            if (doc == null) throw Exception('No document open');
            final key = message['key'] as String;
            mainSendPort.send({'id': id, 'result': doc!.metadata(key)});
          } else if (type == 'getPageCount') {
            mainSendPort.send({'id': id, 'result': doc?.pageCount ?? 0});
          } else if (type == 'getChapterCount') {
            if (doc == null) throw Exception('No document open');
            mainSendPort.send({'id': id, 'result': doc!.chapterCount});
          } else if (type == 'getSpineCount') {
            if (doc == null) throw Exception('No document open');
            mainSendPort.send({'id': id, 'result': doc!.epubSpine?.count ?? doc!.chapterCount});
          } else if (type == 'loadChapterSource') {
            if (doc == null) throw Exception('No document open');
            final chapter = message['chapter'] as int;
            final html = doc!.readChapterXhtml(chapter);
            mainSendPort.send({'id': id, 'result': html});
          } else if (type == 'loadChapterAsset') {
            if (doc == null) throw Exception('No document open');
            final assetPath = message['path'] as String;
            final bytes = doc!.readAsset(assetPath);
            mainSendPort.send({'id': id, 'result': bytes});
          } else if (type == 'getChapterPageCount') {
            if (doc == null) throw Exception('No document open');
            final chapter = message['chapter'] as int;
            mainSendPort.send({
              'id': id,
              'result': doc!.chapterPageCount(chapter),
            });
          } else if (type == 'getOutLine') {
            if (doc == null) throw Exception('No document open');
            mainSendPort.send({'id': id, 'result': doc!.outline});
          } else if (type == 'isReflowable') {
            mainSendPort.send({'id': id, 'result': doc?.isReflowable ?? false});
          } else if (type == 'hasPermission') {
            if (doc == null) throw Exception('No document open');
            final permission = message['permission'] as int;
            mainSendPort.send({
              'id': id,
              'result': doc!.hasPermission(permission),
            });
          } else if (type == 'needsPassword') {
            if (doc == null) throw Exception('No document open');
            mainSendPort.send({'id': id, 'result': doc!.needsPassword});
          } else if (type == 'authenticatePassword') {
            if (doc == null) throw Exception('No document open');
            final pass = message['pass'] as String;
            mainSendPort.send({
              'id': id,
              'result': doc!.authenticatePassword(pass),
            });
          } else if (type == 'layoutReflowable') {
            if (doc == null) throw Exception('No document open');
            final width = (message['width'] as num).toDouble();
            final height = (message['height'] as num).toDouble();
            final em = (message['em'] as num?)?.toDouble() ?? 12.0;
            doc!.layout(width: width, height: height, em: em);
            mainSendPort.send({'id': id, 'result': null});
          } else if (type == 'styleReflowable') {
            if (doc == null) throw Exception('No document open');
            final usePublisherCss = message['usePublisherCss'] as bool? ?? true;
            final userCss = message['userCss'] as String?;
            doc!.style(usePublisherCss: usePublisherCss, userCss: userCss);
            mainSendPort.send({'id': id, 'result': null});
          } else if (type == 'setUserCss') {
            if (doc == null) throw Exception('No document open');
            final css = message['css'] as String;
            doc!.setUserCss(css);
            mainSendPort.send({'id': id, 'result': null});
          } else if (type == 'makeBookmark') {
            if (doc == null) throw Exception('No document open');
            final chapter = message['chapter'] as int;
            final page = message['page'] as int;
            final mark = doc!.makeBookmark(MuPdfLocation(chapter: chapter, page: page));
            mainSendPort.send({'id': id, 'result': mark});
          } else if (type == 'lookupBookmark') {
            if (doc == null) throw Exception('No document open');
            final bookmark = message['bookmark'] as int;
            final loc = doc!.lookupBookmark(bookmark);
            mainSendPort.send({'id': id, 'result': loc});
          } else if (type == 'locationFromPage') {
            if (doc == null) throw Exception('No document open');
            final pageNumber = message['pageNumber'] as int;
            final loc = doc!.locationFromPage(pageNumber);
            mainSendPort.send({'id': id, 'result': loc});
          } else if (type == 'pageFromLocation') {
            if (doc == null) throw Exception('No document open');
            final chapter = message['chapter'] as int;
            final page = message['page'] as int;
            final p = doc!.pageFromLocation(MuPdfLocation(chapter: chapter, page: page));
            mainSendPort.send({'id': id, 'result': p});
          } else if (type == 'extractHtml') {
            final index = message['index'] as int;
            if (doc == null) {
              throw Exception('No document open');
            }
            final page = doc!.loadPage(index);
            final html = page.extractHtml();
            page.dispose();
            mainSendPort.send({'id': id, 'result': html});
          } else if (type == 'extractText') {
            final index = message['index'] as int;
            if (doc == null) {
              throw Exception('No document open');
            }
            final page = doc!.loadPage(index);
            final text = page.extractText();
            page.dispose();
            mainSendPort.send({'id': id, 'result': text});
          } else if (type == 'extractLinks') {
            final index = message['index'] as int;
            if (doc == null) throw Exception('No document open');
            mainSendPort.send({'id': id, 'result': doc!.pageLinks(index)});
          } else if (type == 'resolveUri') {
            final uri = message['uri'] as String;
            if (doc == null) throw Exception('No document open');
            mainSendPort.send({'id': id, 'result': doc!.resolveUri(uri)});
          } else if (type == 'renderPage') {
            if (doc == null) throw Exception('No document open');
            final pageIndex = message['pageIndex'] as int;
            final scaleX = (message['scaleX'] as num?)?.toDouble() ?? 2.0;
            final scaleY = (message['scaleY'] as num?)?.toDouble() ?? 2.0;
            final page = doc!.loadPage(pageIndex);
            try {
              final rendered = page.render(scaleX: scaleX, scaleY: scaleY);
              mainSendPort.send({
                'id': id,
                'result': {
                  'width': rendered.width,
                  'height': rendered.height,
                  'stride': rendered.stride,
                  'components': rendered.components,
                  'pixels': rendered.pixels,
                },
              });
            } finally {
              page.dispose();
            }
          } else if (type == 'renderPageFromFile') {
            final filePath = message['path'] as String;
            final pageIndex = message['pageIndex'] as int;
            final scaleX = (message['scaleX'] as num?)?.toDouble() ?? 1.0;
            final scaleY = (message['scaleY'] as num?)?.toDouble() ?? 1.0;
            final tempDoc = MuPdfDocument.openFile(filePath);
            try {
              if (tempDoc.pageCount <= pageIndex) {
                mainSendPort.send({'id': id, 'result': null});
              } else {
                final page = tempDoc.loadPage(pageIndex);
                try {
                  final rendered = page.render(scaleX: scaleX, scaleY: scaleY);
                  mainSendPort.send({
                    'id': id,
                    'result': {
                      'width': rendered.width,
                      'height': rendered.height,
                      'stride': rendered.stride,
                      'components': rendered.components,
                      'pixels': rendered.pixels,
                    },
                  });
                } finally {
                  page.dispose();
                }
              }
            } finally {
              tempDoc.dispose();
            }
          } else if (type == 'close') {
            doc?.dispose();
            doc = null;
            mainSendPort.send({'id': id, 'result': null});
          } else {
            mainSendPort.send({
              'id': id,
              'error': 'Unknown command type: $type',
            });
          }
        } catch (e) {
          mainSendPort.send({'id': id, 'error': e.toString()});
        }
      }
    });
  }
}
