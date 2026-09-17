import 'dart:io';
import 'dart:typed_data';

import 'tts_models.dart';

/// Result of a speech synthesis operation to an audio file.
class TtsSynthesisResult {
  final File file;
  final double duration;
  final int sampleRate;
  final List<double> waveform;

  const TtsSynthesisResult({
    required this.file,
    required this.duration,
    this.sampleRate = 22050,
    this.waveform = const [],
  });
}

/// Result of a speech synthesis operation to an in-memory WAV byte buffer.
class TtsSynthesisBytesResult {
  final Uint8List wavBytes;
  final double duration;
  final int sampleRate;
  final List<double> waveform;

  const TtsSynthesisBytesResult({
    required this.wavBytes,
    required this.duration,
    this.sampleRate = 22050,
    this.waveform = const [],
  });
}

/// Abstract contract for a pluggable TTS engine.
///
/// Implementations can include on-device neural engines (Sherpa ONNX),
/// native operating system voices (Android TextToSpeech / iOS AVSpeechSynthesizer),
/// or remote cloud TTS (Edge TTS / Azure Speech).
abstract interface class TtsEngine {
  /// The specific kind of TTS engine.
  TtsEngineKind get kind;

  /// Whether the engine is initialized and ready to perform speech synthesis.
  bool get isReady;

  /// Initializes engine resources (e.g. loads bindings, spawns worker isolates,
  /// or connects to platform channels).
  Future<void> initialize();

  /// Releases engine resources, unloads models, and terminates worker isolates.
  Future<void> dispose();

  /// Retrieves voices provided by this engine that are currently available/installed.
  Future<List<TtsVoiceOption>> getAvailableVoices();

  /// Synthesizes [text] to an audio file at [outputPath].
  ///
  /// [gapSec] is trailing silence baked into the file so the pause before the
  /// next chunk matches the natural-voice curve. Rate and pitch are expected to
  /// be controlled by the audio player, not the engine.
  Future<TtsSynthesisResult> synthesizeToFile({
    required String text,
    required String outputPath,
    required TtsVoiceOption voice,
    double speed = 1.0,
    double pitch = 1.0,
    double gapSec = 0.0,
  });

  /// Synthesizes [text] to an in-memory WAV byte buffer.
  ///
  /// [gapSec] is trailing silence baked into the buffer so the pause before
  /// the next chunk matches the natural-voice curve. Rate and pitch are
  /// expected to be controlled by the audio player, not the engine.
  Future<TtsSynthesisBytesResult> synthesizeToBytes({
    required String text,
    required TtsVoiceOption voice,
    double speed = 1.0,
    double pitch = 1.0,
    double gapSec = 0.0,
  });
}

/// Manages and coordinates multiple [TtsEngine] instances.
abstract interface class TtsEngineRegistry {
  /// Registers a [TtsEngine].
  void registerEngine(TtsEngine engine);

  /// Retrieves an engine by its [kind], if registered.
  TtsEngine? getEngine(TtsEngineKind kind);

  /// Retrieves the engine responsible for the specified [voice].
  TtsEngine getEngineForVoice(TtsVoiceOption voice);

  /// Collects available/installed voices from all registered engines.
  Future<List<TtsVoiceOption>> getAllInstalledVoices();

  /// Initializes a specific engine by [kind].
  Future<void> initializeEngine(TtsEngineKind kind);

  /// Disposes all registered engines.
  Future<void> disposeAll();
}
