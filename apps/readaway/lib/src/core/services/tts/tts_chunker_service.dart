part of '../services.dart';

/// Top-level entry point executed inside the worker isolate.
void _textChunkerIsolateEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();

  // 1. Handshake: Send worker's SendPort back to the host process
  mainSendPort.send(receivePort.sendPort);

  final chunker = TextChunker();

  // 2. Listen for incoming chunking commands
  receivePort.listen((message) {
    if (message is Map && message['id'] != null) {
      final Object id = message['id'];
      final text = message['text'] as String;
      final maxChunkChars = message['maxChunkChars'] as int? ?? 400;

      try {
        final chunks = chunker.chunkSentences(
          text,
          maxChunkChars: maxChunkChars,
        );

        // Convert TtsChunk objects into primitive Maps for SendPort transfer
        final rawChunks = chunks
            .map(
              (c) => {
                'text': c.text,
                'startOffset': c.startOffset,
                'endOffset': c.endOffset,
              },
            )
            .toList(growable: false);

        mainSendPort.send({'id': id, 'result': rawChunks});
      } catch (e) {
        mainSendPort.send({'id': id, 'error': e.toString()});
      }
    }
  });
}

/// Facade service managing background isolate text chunking for TTS.
@lazySingleton
class TtsChunkingService {
  final IsolateService _isolateService;
  static const String _isolateName = 'text_chunker_worker';

  int _nextCommandId = 0;

  TtsChunkingService(this._isolateService);

  /// Spawns worker isolate using a thread-safe initializer guard.
  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (_isolateService.isSpawned(_isolateName)) return;

    await _isolateService.spawn(
      name: _isolateName,
      entryPoint: _textChunkerIsolateEntryPoint,
    );
  }

  /// Kills the worker isolate. Called by the DI container on shutdown so
  /// the isolate doesn't leak across app restarts.
  @disposeMethod
  Future<void> dispose() async {
    await _isolateService.disposeIsolate(_isolateName);
  }

  /// Offloads text chunking to the background worker isolate.
  Future<List<TtsChunk>> chunkText(
    String text, {
    int maxChunkChars = 400,
  }) async {
    if (text.trim().isEmpty) return const [];

    await init();

    final commandId = _nextCommandId++;
    final response = await _isolateService.sendCommand<List<dynamic>>(
      _isolateName,
      {
        'id': commandId,
        'text': text,
        'maxChunkChars': maxChunkChars,
      },
    );

    return response
        .map(
          (dynamic item) {
            final map = item as Map<String, dynamic>;
            return TtsChunk(
              text: map['text'] as String,
              startOffset: map['startOffset'] as int,
              endOffset: map['endOffset'] as int,
            );
          },
        )
        .toList(growable: false);
  }
}

/// Represents a single sentence or clause payload for TTS playback and text-highlighting.
class TtsChunk {
  const TtsChunk({
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });

  /// Trimmed text chunk.
  final String text;

  /// Absolute character index start bound in source text.
  final int startOffset;

  /// Absolute character index end bound in source text.
  final int endOffset;
}

/// Synchronous text-chunking engine running inside the isolate worker.
@LazySingleton()
class TextChunker {
  final RegExp _sentenceBoundary = RegExp(
    r'(?<=[.!?\u2026])(?=\s|$)|(?<=\n)\s*\n',
  );

  final _abbreviations = const {
    'mr.',
    'mrs.',
    'ms.',
    'dr.',
    'prof.',
    'sr.',
    'jr.',
    'st.',
    'vs.',
    'etc.',
    'e.g.',
    'i.e.',
    'no.',
    'fig.',
    'approx.',
  };

  /// Splits [text] into sentence-ish chunks.
  List<TtsChunk> chunkSentences(
    String text, {
    int maxChunkChars = 400,
  }) {
    if (text.trim().isEmpty) return const [];

    final rawParts = <_RawSpan>[];
    var start = 0;
    for (final match in _sentenceBoundary.allMatches(text)) {
      final end = match.end;
      if (end > start) {
        rawParts.add(_RawSpan(start, end));
      }
      start = end;
    }
    if (start < text.length) {
      rawParts.add(_RawSpan(start, text.length));
    }

    final merged = _mergeAbbreviations(text, rawParts);
    final chunks = <TtsChunk>[];

    for (final span in merged) {
      final piece = text.substring(span.start, span.end).trim();
      if (piece.isEmpty) continue;

      if (piece.length <= maxChunkChars) {
        chunks.add(
          TtsChunk(text: piece, startOffset: span.start, endOffset: span.end),
        );
      } else {
        chunks.addAll(_hardWrap(text, span.start, span.end, maxChunkChars));
      }
    }
    return chunks;
  }

  List<_RawSpan> _mergeAbbreviations(String text, List<_RawSpan> spans) {
    final result = <_RawSpan>[];
    for (final span in spans) {
      if (result.isNotEmpty) {
        final prevText = text
            .substring(result.last.start, result.last.end)
            .trimRight()
            .toLowerCase();
        final lastWord = prevText.split(RegExp(r'\s+')).lastOrNull ?? '';
        if (_abbreviations.contains(lastWord)) {
          result[result.length - 1] = _RawSpan(result.last.start, span.end);
          continue;
        }
      }
      result.add(span);
    }
    return result;
  }

  static List<TtsChunk> _hardWrap(
    String text,
    int start,
    int end,
    int maxChars,
  ) {
    final chunks = <TtsChunk>[];
    var cursor = start;
    while (cursor < end) {
      var sliceEnd = (cursor + maxChars).clamp(cursor, end);
      if (sliceEnd < end) {
        final lastSpace = text.lastIndexOf(RegExp(r'\s'), sliceEnd);
        if (lastSpace > cursor) sliceEnd = lastSpace;
      }
      final piece = text.substring(cursor, sliceEnd).trim();
      if (piece.isNotEmpty) {
        chunks.add(
          TtsChunk(text: piece, startOffset: cursor, endOffset: sliceEnd),
        );
      }
      cursor = sliceEnd;
    }
    return chunks;
  }
}

class _RawSpan {
  const _RawSpan(this.start, this.end);
  final int start;
  final int end;
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
