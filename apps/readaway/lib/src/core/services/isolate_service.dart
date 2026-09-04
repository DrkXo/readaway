import 'dart:async';
import 'dart:isolate';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import 'logging_service.dart';

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

  final responseSubject = PublishSubject<dynamic>();

  Future<void> dispose() async {
    await responseSubject.close();
    receivePort?.close();
    errorPort?.close();
    exitPort?.close();
    isolate?.kill(priority: Isolate.immediate);
  }
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
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    instance.receivePort = receivePort;
    instance.errorPort = errorPort;
    instance.exitPort = exitPort;
    _instances[name] = instance;

    final completer = Completer<SendPort>();

    void failAll(Object error) {
      if (!completer.isCompleted) completer.completeError(error);
      if (!instance.responseSubject.isClosed) {
        instance.responseSubject.addError(error);
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
        if (!instance.responseSubject.isClosed) {
          instance.responseSubject.add(message);
        }
      }
    });

    instance.sendPort = await completer.future;
    _log.info('Isolate "$name" ready.');
    return instance.sendPort!;
  }

  Future<T> sendCommand<T>(String name, Map<String, dynamic> command) async {
    final instance = _instances[name];
    if (instance == null || instance.sendPort == null) {
      throw StateError('Isolate "$name" not spawned');
    }

    final id = command['id'];

    instance.sendPort!.send(command);

    final response = await instance.responseSubject.stream
        .whereType<Map<String, dynamic>>()
        .firstWhere(
          (msg) => msg['id'] == id,
          orElse: () =>
              throw IsolateCommandException('No response received for id: $id'),
        );

    if (response.containsKey('error')) {
      throw IsolateCommandException(response['error'].toString());
    }

    return response['result'] as T;
  }

  Stream<T> sendStreamCommand<T>(String name, Map<String, dynamic> command) {
    final instance = _instances[name];
    if (instance == null || instance.sendPort == null) {
      throw StateError('Isolate "$name" not spawned');
    }

    final id = command['id'];

    final stream = instance.responseSubject.stream
        .whereType<Map<String, dynamic>>()
        .where((msg) => msg['id'] == id)
        .takeWhile((msg) => msg['done'] != true)
        .map<T>((msg) {
          if (msg.containsKey('error')) {
            throw IsolateCommandException(msg['error'].toString());
          }
          if (msg.containsKey('chunk')) {
            return msg['chunk'] as T;
          }
          throw IsolateCommandException(
            'Malformed isolate message for id: $id',
          );
        })
        .doOnListen(() {
          instance.sendPort!.send(command);
        });

    return stream;
  }

  Future<void> disposeIsolate(String name) async {
    final instance = _instances.remove(name);
    if (instance == null) return;

    await instance.dispose();
  }

  @disposeMethod
  Future<void> dispose() async {
    for (final name in List<String>.from(_instances.keys)) {
      await disposeIsolate(name);
    }
  }
}
