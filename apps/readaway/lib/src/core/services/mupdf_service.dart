part of 'services.dart';

@singleton
class MuPdfService {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  final _responseController = BehaviorSubject<dynamic>();

  final LoggingService _loggingService;

  Logger get _log => _loggingService.logger;

  MuPdfService({
    required this._loggingService,
  });

  Future<void> _ensureIsolate() async {
    if (_isolate != null) return;

    _log.info(
      'Spawning MuPdfService background isolate...',
    );
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort!.sendPort,
      debugName: 'MuPdfService Document Parser Isolate',
    );

    final completer = Completer<SendPort>();
    _receivePort!.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else {
        _responseController.add(message);
      }
    });

    _sendPort = await completer.future;
    _log.info(
      '[MuPdfService] background isolate ready.',
    );
  }

  Future<T> _sendCommand<T>(dynamic command) async {
    await _ensureIsolate();
    final completer = Completer<T>();

    StreamSubscription? subscription;
    subscription = _responseController.stream.listen((response) {
      if (response is Map && response['id'] == command['id']) {
        subscription?.cancel();
        if (response.containsKey('error')) {
          completer.completeError(Exception(response['error']));
        } else {
          completer.complete(response['result'] as T);
        }
      }
    });

    _sendPort!.send(command);
    return completer.future;
  }

  Future<void> openDocument(String path) {
    return _sendCommand({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'open',
      'path': path,
    });
  }

  Future<String?> getMetaData(String key) {
    return _sendCommand<String?>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'getMetaData',
      'key': key,
    });
  }

  Future<int> getPageCount() {
    return _sendCommand<int>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'getPageCount',
    });
  }

  Future<int> getChapterCount() {
    return _sendCommand<int>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'getChapterCount',
    });
  }

  Future<int> getChapterPageCount(int chapter) {
    return _sendCommand<int>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'getChapterPageCount',
      'chapter': chapter,
    });
  }

  Future<List<OutlineItem>> getOutLine() async {
    return _sendCommand<List<OutlineItem>>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'getOutLine',
    });
  }

  Future<bool> isReflowable() {
    return _sendCommand<bool>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'isReflowable',
    });
  }

  Future<bool> hasPermission(int permission) {
    return _sendCommand<bool>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'hasPermission',
      'permission': permission,
    });
  }

  Future<bool> needsPassword() {
    return _sendCommand<bool>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'needsPassword',
    });
  }

  Future<bool> authenticatePassword(String pass) {
    return _sendCommand<bool>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'authenticatePassword',
      'pass': pass,
    });
  }

  Future<String?> extractPageHtml(int pageIndex) {
    return _sendCommand<String?>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'extractHtml',
      'index': pageIndex,
    });
  }

  Future<List<PageLink>> getPageLinks(int pageIndex) {
    return _sendCommand<List<PageLink>>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'extractLinks',
      'index': pageIndex,
    });
  }

  Future<Map<String, dynamic>?> renderPage(int pageIndex, {double scaleX = 2.0, double scaleY = 2.0}) {
    return _sendCommand<Map<String, dynamic>?>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'renderPage',
      'pageIndex': pageIndex,
      'scaleX': scaleX,
      'scaleY': scaleY,
    });
  }

  Future<void> closeDocument() {
    return _sendCommand({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'close',
    });
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
          } else if (type == 'extractHtml') {
            final index = message['index'] as int;
            if (doc == null) {
              throw Exception('No document open');
            }
            final page = doc!.loadPage(index);
            final html = page.extractHtml();
            page.dispose();
            mainSendPort.send({'id': id, 'result': html});
          } else if (type == 'extractLinks') {
            final index = message['index'] as int;
            if (doc == null) throw Exception('No document open');
            mainSendPort.send({'id': id, 'result': doc!.pageLinks(index)});
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
