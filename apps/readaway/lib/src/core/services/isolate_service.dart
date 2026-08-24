part of 'services.dart';

class _IsolateInstance {
  Isolate? isolate;
  SendPort? sendPort;
  ReceivePort? receivePort;
  final responseController = BehaviorSubject<dynamic>();
}

@singleton
class IsolateService {
  final LoggingService _loggingService;
  final Map<String, _IsolateInstance> _instances = {};

  Logger get _log => _loggingService.logger;

  IsolateService({
    required this._loggingService,
  });

  bool isSpawned(String name) => _instances[name]?.sendPort != null;

  Future<SendPort> spawn({
    required String name,
    required void Function(SendPort) entryPoint,
  }) async {
    if (isSpawned(name)) {
      throw StateError('Isolate "$name" already spawned');
    }

    final instance = _IsolateInstance();
    final receivePort = ReceivePort();
    instance.receivePort = receivePort;

    _log.info('Spawning isolate "$name"...');
    instance.isolate = await Isolate.spawn(
      entryPoint,
      receivePort.sendPort,
      debugName: name,
    );

    final completer = Completer<SendPort>();
    receivePort.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else {
        instance.responseController.add(message);
      }
    });

    instance.sendPort = await completer.future;
    _instances[name] = instance;
    _log.info('Isolate "$name" ready.');
    return instance.sendPort!;
  }

  Future<T> sendCommand<T>(String name, dynamic command) async {
    final instance = _instances[name];
    if (instance == null || instance.sendPort == null) {
      throw StateError('Isolate "$name" not spawned');
    }

    final completer = Completer<T>();
    StreamSubscription? subscription;
    subscription = instance.responseController.stream.listen((response) {
      if (response is Map && response['id'] == command['id']) {
        subscription?.cancel();
        if (response.containsKey('error')) {
          completer.completeError(Exception(response['error']));
        } else {
          completer.complete(response['result'] as T);
        }
      }
    });

    instance.sendPort!.send(command);
    return completer.future;
  }

  Future<void> disposeIsolate(String name) async {
    final instance = _instances.remove(name);
    if (instance == null) return;

    await instance.responseController.close();
    instance.receivePort?.close();
    instance.isolate?.kill();
  }

  @disposeMethod
  Future<void> dispose() async {
    for (final name in List<String>.from(_instances.keys)) {
      await disposeIsolate(name);
    }
  }
}
