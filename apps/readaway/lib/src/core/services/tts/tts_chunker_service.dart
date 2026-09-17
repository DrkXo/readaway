import 'dart:async';
import 'dart:isolate';

import 'package:injectable/injectable.dart';
import 'package:readaway_core_rust/readaway_core_rust.dart';

import '../isolate_service.dart';
import '../logging_service.dart';

/// Top-level entry point executed inside the worker isolate.
///
/// Owns the isolate lifetime and forwards every received command straight to
/// the pure-logic [TextChunker]; responses travel back as JSON maps so the
/// payload survives the `SendPort` hop regardless of platform.
void _textChunkerIsolateEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();

  // 1. Handshake: Send worker's SendPort back to the host process
  mainSendPort.send(receivePort.sendPort);

  const chunker = TextChunker();

  // 2. Listen for incoming chunking commands
  receivePort.listen((message) {
    if (message is Map && message['id'] != null) {
      final Object id = message['id'];
      final text = message['text'] as String;
      final maxChunkChars = message['maxChunkChars'] as int? ?? 450;
      final sanitizeForSpeech = message['sanitizeForSpeech'] as bool? ?? true;

      try {
        final chunks = chunker.chunkSentences(
          text,
          maxChunkChars: maxChunkChars,
          sanitizeForSpeech: sanitizeForSpeech,
        );

        // Serialize TtsChunk objects into primitive maps for SendPort transfer.
        final rawChunks = chunks.map((c) => c.toJson()).toList(growable: false);

        mainSendPort.send({'id': id, 'result': rawChunks});
      } catch (e, st) {
        mainSendPort.send({'id': id, 'error': '$e\n$st'});
      }
    }
  });
}

/// Facade service managing background isolate text chunking for TTS.
///
/// The heavy lifting lives in [TextChunker] from `readaway_core`; this service
/// merely schedules it on a reusable worker isolate owned by [IsolateService].
/// [chunkText] awaits the isolate reply and transparently falls back to
/// in-place chunking if the worker ever dies.
@lazySingleton
class TtsChunkingService {
  final IsolateService _isolateService;
  static const String _isolateName = 'text_chunker_worker';

  int _nextCommandId = 0;

  TtsChunkingService(this._isolateService);

  /// Spawns the worker isolate on demand. Idempotent.
  Future<void> start() async {
    if (_isolateService.isSpawned(_isolateName)) return;

    await _isolateService.spawn(
      name: _isolateName,
      entryPoint: _textChunkerIsolateEntryPoint,
    );
  }

  /// Kills the worker isolate.
  Future<void> stop() => dispose();

  /// Fully tears down the isolate.
  @disposeMethod
  Future<void> dispose() async {
    await _isolateService.disposeIsolate(_isolateName);
  }

  /// Offloads text chunking to the background worker isolate.
  ///
  /// Returns a list of [TtsChunk]s enriched with exact offsets, paragraph
  /// metadata, speech sanitization, word boundaries, and inferred language.
  Future<List<TtsChunk>> chunkText(
    String text, {
    int maxChunkChars = 450,
    bool sanitizeForSpeech = true,
  }) async {
    if (text.trim().isEmpty) return const [];

    try {
      await start();

      final commandId = _nextCommandId++;
      final response = await _isolateService.sendCommand<List<dynamic>>(
        _isolateName,
        {
          'id': commandId,
          'text': text,
          'maxChunkChars': maxChunkChars,
          'sanitizeForSpeech': sanitizeForSpeech,
        },
      );

      return response
          .whereType<Map<Object?, Object?>>()
          .map((map) => TtsChunk.fromJson(Map<String, dynamic>.from(map)))
          .toList(growable: false);
    } catch (e, st) {
      logger.w(
        'Worker isolate chunking failed, falling back to sync chunker',
        e,
        st,
      );
      const fallbackChunker = TextChunker();
      return fallbackChunker.chunkSentences(
        text,
        maxChunkChars: maxChunkChars,
        sanitizeForSpeech: sanitizeForSpeech,
      );
    }
  }
}
