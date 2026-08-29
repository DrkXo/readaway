part of 'services.dart';

/// Thrown when a command sent to a worker isolate fails on the other side,
/// or when the isolate itself crashes/exits while a command is pending.
class IsolateCommandException implements Exception {
  IsolateCommandException(this.message);
  final String message;

  @override
  String toString() => 'IsolateCommandException: $message';
}

class _IsolateInstance {
  Isolate? isolate;
  SendPort? sendPort;
  ReceivePort? receivePort;
  ReceivePort? errorPort;
  ReceivePort? exitPort;

  // Plain broadcast controller — no external dependency needed for this.
  final responseController = StreamController<dynamic>.broadcast();
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

  /// Spawns [entryPoint] as isolate [name]. [entryPoint] must, as its first
  /// action, send its own `SendPort` back over the `SendPort` it receives —
  /// that's how this method knows the isolate is ready to accept commands.
  ///
  /// Unlike the original version, a crash or unexpected exit inside the
  /// isolate now surfaces as an [IsolateCommandException] on every pending
  /// (and future) [sendCommand]/[sendStreamCommand] call instead of hanging
  /// forever.
  Future<SendPort> spawn({
    required String name,
    required void Function(SendPort) entryPoint,
  }) async {
    if (isSpawned(name)) {
      throw StateError('Isolate "$name" already spawned');
    }

    final instance = _IsolateInstance();
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    instance.receivePort = receivePort;
    instance.errorPort = errorPort;
    instance.exitPort = exitPort;
    _instances[name] = instance;

    final completer = Completer<SendPort>();

    void failAll(Object error) {
      if (!completer.isCompleted) completer.completeError(error);
      if (!instance.responseController.isClosed) {
        instance.responseController.addError(error);
      }
    }

    errorPort.listen((error) {
      _log.severe('Isolate "$name" uncaught error: $error');
      failAll(IsolateCommandException('Isolate "$name" crashed: $error'));
    });

    exitPort.listen((_) {
      _log.info('Isolate "$name" exited.');
      failAll(IsolateCommandException('Isolate "$name" exited unexpectedly'));
      _instances.remove(name);
    });

    _log.info('Spawning isolate "$name"...');
    instance.isolate = await Isolate.spawn(
      entryPoint,
      receivePort.sendPort,
      debugName: name,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    receivePort.listen((message) {
      if (message is SendPort) {
        if (!completer.isCompleted) completer.complete(message);
      } else {
        instance.responseController.add(message);
      }
    });

    instance.sendPort = await completer.future;
    _log.info('Isolate "$name" ready.');
    return instance.sendPort!;
  }

  /// Sends [command] (must contain a unique `'id'`) and resolves with the
  /// matching `{'id': ..., 'result': ...}` response's `result` field.
  Future<T> sendCommand<T>(String name, Map<String, dynamic> command) async {
    final instance = _instances[name];
    if (instance == null || instance.sendPort == null) {
      throw StateError('Isolate "$name" not spawned');
    }

    final id = command['id'];
    final completer = Completer<T>();
    late final StreamSubscription subscription;
    subscription = instance.responseController.stream.listen(
      (response) {
        if (response is Map && response['id'] == id) {
          subscription.cancel();
          if (response.containsKey('error')) {
            completer.completeError(
              IsolateCommandException(response['error'].toString()),
            );
          } else if (!completer.isCompleted) {
            completer.complete(response['result'] as T);
          }
        }
      },
      onError: (Object e, StackTrace st) {
        subscription.cancel();
        if (!completer.isCompleted) completer.completeError(e, st);
      },
    );

    instance.sendPort!.send(command);
    return completer.future;
  }

  /// Like [sendCommand], but for handlers that stream back multiple partial
  /// results before finishing (e.g. TTS synthesis callbacks).
  ///
  /// The isolate-side handler should send `{'id': id, 'chunk': ...}` for
  /// each item, then finally either `{'id': id, 'done': true}` or
  /// `{'id': id, 'error': ...}`.
  Stream<T> sendStreamCommand<T>(String name, Map<String, dynamic> command) {
    final instance = _instances[name];
    if (instance == null || instance.sendPort == null) {
      throw StateError('Isolate "$name" not spawned');
    }

    final id = command['id'];
    final controller = StreamController<T>();
    StreamSubscription? subscription;

    controller.onListen = () {
      subscription = instance.responseController.stream.listen(
        (response) {
          if (response is! Map || response['id'] != id) return;
          if (response.containsKey('error')) {
            controller.addError(
              IsolateCommandException(response['error'].toString()),
            );
            controller.close();
            subscription?.cancel();
          } else if (response['done'] == true) {
            controller.close();
            subscription?.cancel();
          } else if (response.containsKey('chunk')) {
            controller.add(response['chunk'] as T);
          }
        },
        onError: (Object e, StackTrace st) {
          controller.addError(e, st);
          controller.close();
          subscription?.cancel();
        },
      );
      instance.sendPort!.send(command);
    };
    controller.onCancel = () => subscription?.cancel();
    return controller.stream;
  }

  Future<void> disposeIsolate(String name) async {
    final instance = _instances.remove(name);
    if (instance == null) return;
    await instance.responseController.close();
    instance.receivePort?.close();
    instance.errorPort?.close();
    instance.exitPort?.close();
    instance.isolate?.kill(priority: Isolate.immediate);
  }

  @disposeMethod
  Future<void> dispose() async {
    for (final name in List<String>.from(_instances.keys)) {
      await disposeIsolate(name);
    }
  }
}
