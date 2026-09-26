part of 'models.dart';

/// Metadata for an individual cached audio chunk within a chapter.
@freezed
sealed class TtsCachedChunk with _$TtsCachedChunk {
  const TtsCachedChunk._();

  const factory TtsCachedChunk({
    required int chunkIndex,
    required String fileName,
    required int startOffset,
    required int endOffset,
    required double durationSec,
    @Default(<double>[]) List<double> waveform,
    @Default(0.0) double gapSec,
  }) = _TtsCachedChunk;

  factory TtsCachedChunk.fromJson(Map<String, dynamic> json) => TtsCachedChunk(
        chunkIndex: (json['chunkIndex'] as num).toInt(),
        fileName: json['fileName'] as String,
        startOffset: (json['startOffset'] as num).toInt(),
        endOffset: (json['endOffset'] as num).toInt(),
        durationSec: (json['durationSec'] as num).toDouble(),
        waveform: (json['waveform'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            const [],
        gapSec: (json['gapSec'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  Map<String, dynamic> toJson() => {
        'chunkIndex': chunkIndex,
        'fileName': fileName,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'durationSec': durationSec,
        'waveform': waveform,
        'gapSec': gapSec,
      };
}

/// Persistent manifest describing the synthesized TTS audio cache for a specific chapter/section.
@freezed
sealed class TtsChapterCacheManifest with _$TtsChapterCacheManifest {
  const TtsChapterCacheManifest._();

  const factory TtsChapterCacheManifest({
    required int chapterIndex,
    required String textHash,
    required String voiceId,
    @Default(0) int speakerId,
    @Default('') String configHash,
    @Default(22050) int sampleRate,
    @Default(0.0) double totalDurationSec,
    @Default(false) bool isComplete,
    required DateTime createdAt,
    required DateTime lastAccessedAt,
    @Default(<TtsCachedChunk>[]) List<TtsCachedChunk> chunks,
  }) = _TtsChapterCacheManifest;

  factory TtsChapterCacheManifest.fromJson(Map<String, dynamic> json) =>
      TtsChapterCacheManifest(
        chapterIndex: (json['chapterIndex'] as num).toInt(),
        textHash: json['textHash'] as String,
        voiceId: json['voiceId'] as String,
        speakerId: (json['speakerId'] as num?)?.toInt() ?? 0,
        configHash: json['configHash'] as String? ?? '',
        sampleRate: (json['sampleRate'] as num?)?.toInt() ?? 22050,
        totalDurationSec:
            (json['totalDurationSec'] as num?)?.toDouble() ?? 0.0,
        isComplete: json['isComplete'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
        chunks: (json['chunks'] as List<dynamic>?)
                ?.map((e) => e is TtsCachedChunk
                    ? e
                    : TtsCachedChunk.fromJson(
                        Map<String, dynamic>.from(e as Map),
                      ))
                .toList() ??
            const [],
      );

  @override
  Map<String, dynamic> toJson() => {
        'chapterIndex': chapterIndex,
        'textHash': textHash,
        'voiceId': voiceId,
        'speakerId': speakerId,
        'configHash': configHash,
        'sampleRate': sampleRate,
        'totalDurationSec': totalDurationSec,
        'isComplete': isComplete,
        'createdAt': createdAt.toIso8601String(),
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
        'chunks': chunks.map((c) => c.toJson()).toList(),
      };

  /// Retrieves cached chunk metadata for [index] if present.
  TtsCachedChunk? getChunk(int index) {
    for (final chunk in chunks) {
      if (chunk.chunkIndex == index) return chunk;
    }
    return null;
  }

  /// Whether chunk with [index] is recorded in this manifest.
  bool hasChunk(int index) => getChunk(index) != null;

  /// Returns a copy of this manifest with updated [lastAccessedAt].
  TtsChapterCacheManifest touch([DateTime? timestamp]) =>
      copyWith(lastAccessedAt: timestamp ?? DateTime.now());

  /// Returns a copy of this manifest with a new or updated [chunk].
  TtsChapterCacheManifest withChunk(TtsCachedChunk chunk) {
    final updatedList = List<TtsCachedChunk>.from(chunks);
    final existingIdx = updatedList.indexWhere(
      (c) => c.chunkIndex == chunk.chunkIndex,
    );
    if (existingIdx >= 0) {
      updatedList[existingIdx] = chunk;
    } else {
      updatedList.add(chunk);
      updatedList.sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
    }

    final newTotalDuration = updatedList.fold<double>(
      0.0,
      (sum, c) => sum + c.durationSec,
    );

    return copyWith(
      chunks: updatedList,
      totalDurationSec: newTotalDuration,
      lastAccessedAt: DateTime.now(),
    );
  }
}
