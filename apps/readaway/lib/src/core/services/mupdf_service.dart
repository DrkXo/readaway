part of 'services.dart';

@singleton
class DocumentParserService {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  final _responseController = BehaviorSubject<dynamic>();

  final LoggingService _loggingService;

  Logger get _log => _loggingService.logger;

  DocumentParserService({
    required this._loggingService,
  });

  Future<void> _ensureIsolate() async {
    if (_isolate != null) return;

    _log.info(
      'Spawning ReadAway background isolate...',
    );
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort!.sendPort);

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
      'ReadAway background isolate ready.',
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

  Future<int> getPageCount() {
    return _sendCommand<int>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'getPageCount',
    });
  }

  Future<bool> isReflowable() {
    return _sendCommand<bool>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'isReflowable',
    });
  }

  Future<String?> extractPageHtml(int pageIndex) {
    return _sendCommand<String?>({
      'id': DateTime.now().microsecondsSinceEpoch,
      'type': 'extractHtml',
      'index': pageIndex,
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
          } else if (type == 'getPageCount') {
            mainSendPort.send({'id': id, 'result': doc?.pageCount ?? 0});
          } else if (type == 'isReflowable') {
            mainSendPort.send({'id': id, 'result': doc?.isReflowable ?? false});
          } else if (type == 'extractHtml') {
            final index = message['index'] as int;
            if (doc == null) {
              throw Exception('No document open');
            }
            final page = doc!.loadPage(index);
            final html = page.extractHtml();
            page.dispose();
            mainSendPort.send({'id': id, 'result': html});
          } else if (type == 'close') {
            doc?.dispose();
            doc = null;
            mainSendPort.send({'id': id, 'result': null});
          }
        } catch (e) {
          mainSendPort.send({'id': id, 'error': e.toString()});
        }
      }
    });
  }
}
