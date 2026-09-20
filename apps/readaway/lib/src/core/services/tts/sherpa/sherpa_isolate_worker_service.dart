import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:readaway_core/readaway_core.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../stream/wav_encoder.dart';
import '../tts_models.dart';

const sherpaTtsIsolateName = 'sherpa-tts';

void sherpaTtsIsolateEntryPoint(SendPort mainSendPort) {
  sherpa.initBindings();

  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  sherpa.OfflineTts? tts;

  void reply(dynamic id, {Object? result, String? error}) {
    mainSendPort.send({
      'id': id,
      if (error != null) 'error': error else 'result': result,
    });
  }

  commandPort.listen((message) {
    if (message is! Map) return;
    final id = message['id'];
    final type = message['type'] as String?;

    try {
      switch (type) {
        case 'loadModel':
          tts?.free();
          tts = null;

          final modelConfig = buildSherpaConfigFromMessage(message);
          final ruleFsts = message['ruleFsts'] as String? ?? '';
          final ruleFars = message['ruleFars'] as String? ?? '';
          final silenceScale =
              (message['silenceScale'] as num?)?.toDouble() ?? 0.2;
          final config = sherpa.OfflineTtsConfig(
            model: modelConfig,
            ruleFsts: ruleFsts,
            ruleFars: ruleFars,
            silenceScale: silenceScale,
            maxNumSenetences: 1,
          );
          final newTts = sherpa.OfflineTts(config);
          tts = newTts;
          reply(
            id,
            result: {
              'sampleRate': newTts.sampleRate,
              'speakerCount': newTts.numSpeakers,
            },
          );
          break;

        case 'generate':
          final engine = tts;
          if (engine == null) {
            reply(id, error: 'No model loaded in TTS isolate.');
            break;
          }
          final text = message['text'] as String;

          if (text.trim().isEmpty) {
            reply(
              id,
              result: {
                'samples': Float32List(0),
                'sampleRate': engine.sampleRate,
              },
            );
            break;
          }
          final genConfig = buildGenerationConfigFromMessage(message);
          final gapSec = (message['gapSec'] as num?)?.toDouble() ?? 0.0;
          final sentenceGapMs =
              (message['sentenceGapMs'] as num?)?.toInt() ?? 0;
          final out = _synthesizeWithProsody(
            engine,
            text,
            genConfig,
            gapSec,
            sentenceGapMs: sentenceGapMs,
          );
          reply(
            id,
            result: {
              'samples': out,
              'sampleRate': engine.sampleRate,
            },
          );
          break;

        case 'generateToFile':
          final engine = tts;
          if (engine == null) {
            reply(id, error: 'No model loaded in TTS isolate.');
            break;
          }
          final text = message['text'] as String;
          final outputPath = message['outputPath'] as String;

          if (text.trim().isEmpty) {
            reply(
              id,
              result: {
                'outputPath': outputPath,
                'duration': 0.0,
                'sampleRate': engine.sampleRate,
              },
            );
            break;
          }
          final genConfig = buildGenerationConfigFromMessage(message);
          final gapSec = (message['gapSec'] as num?)?.toDouble() ?? 0.0;
          final sentenceGapMs =
              (message['sentenceGapMs'] as num?)?.toInt() ?? 0;
          final out = _synthesizeWithProsody(
            engine,
            text,
            genConfig,
            gapSec,
            sentenceGapMs: sentenceGapMs,
          );

          final ok = sherpa.writeWave(
            filename: outputPath,
            samples: out,
            sampleRate: engine.sampleRate,
          );
          if (!ok) {
            reply(id, error: 'Failed to write WAV to $outputPath');
            break;
          }
          final duration = out.length / engine.sampleRate;
          final peaks = _extractPeaks(out, targetBars: 64);
          reply(
            id,
            result: {
              'outputPath': outputPath,
              'duration': duration,
              'sampleRate': engine.sampleRate,
              'waveform': peaks,
            },
          );
          break;

        case 'generateToBytes':
          final engine = tts;
          if (engine == null) {
            reply(id, error: 'No model loaded in TTS isolate.');
            break;
          }
          final text = message['text'] as String;
          final gapSec = (message['gapSec'] as num?)?.toDouble() ?? 0.0;
          final sentenceGapMs =
              (message['sentenceGapMs'] as num?)?.toInt() ?? 0;

          if (text.trim().isEmpty) {
            reply(
              id,
              result: {
                'wavBytes': Uint8List(0),
                'duration': 0.0,
                'sampleRate': engine.sampleRate,
                'waveform': <double>[],
              },
            );
            break;
          }
          final genConfig = buildGenerationConfigFromMessage(message);
          final out = _synthesizeWithProsody(
            engine,
            text,
            genConfig,
            gapSec,
            sentenceGapMs: sentenceGapMs,
          );
          final wavBytes = encodeWavFromPcm(out, engine.sampleRate);
          final duration = out.length / engine.sampleRate;
          final peaks = _extractPeaks(out, targetBars: 64);
          reply(
            id,
            result: {
              'wavBytes': wavBytes,
              'duration': duration,
              'sampleRate': engine.sampleRate,
              'waveform': peaks,
            },
          );
          break;

        case 'generateStream':
          final engine = tts;
          if (engine == null) {
            reply(id, error: 'No model loaded in TTS isolate.');
            break;
          }
          final text = message['text'] as String;
          final genConfig = buildGenerationConfigFromMessage(message);

          engine.generateWithConfig(
            text: text,
            config: genConfig,
            onProgress: (samples, progress) {
              mainSendPort.send({'id': id, 'chunk': samples});
              return 1;
            },
          );
          mainSendPort.send({'id': id, 'done': true});
          break;

        case 'unload':
          tts?.free();
          tts = null;
          reply(id, result: true);
          break;

        default:
          reply(id, error: 'Unknown command "$type"');
      }
    } catch (e, st) {
      reply(id, error: '$e\n$st');
    }
  });
}

@visibleForTesting
sherpa.OfflineTtsGenerationConfig buildGenerationConfigFromMessage(Map message) {
  final speakerId = message['speakerId'] as int? ?? 0;
  final speed = (message['speed'] as num?)?.toDouble() ?? 1.0;
  final silenceScale = (message['silenceScale'] as num?)?.toDouble() ?? 0.2;
  final numSteps = message['numSteps'] as int? ?? 5;

  return sherpa.OfflineTtsGenerationConfig(
    sid: speakerId,
    speed: speed,
    silenceScale: silenceScale,
    numSteps: numSteps,
  );
}

@visibleForTesting
sherpa.OfflineTtsModelConfig buildSherpaConfigFromMessage(Map message) {
  final type = message['modelType'] as String;
  final numThreads = message['numThreads'] as int? ?? 2;
  final debug = message['debug'] as bool? ?? false;
  final tokens = message['tokens'] as String;
  final lexicon = message['lexicon'] as String? ?? '';
  final dataDir = message['dataDir'] as String? ?? '';
  final dictDir = message['dictDir'] as String? ?? '';
  final noiseScale = (message['noiseScale'] as num?)?.toDouble() ?? 0.667;
  final noiseScaleW = (message['noiseScaleW'] as num?)?.toDouble() ?? 0.8;
  final lengthScale = (message['lengthScale'] as num?)?.toDouble() ?? 1.0;

  switch (type) {
    case 'vits':
      return sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: message['modelPath'] as String,
          tokens: tokens,
          lexicon: lexicon,
          dataDir: dataDir,
          dictDir: dictDir,
          noiseScale: noiseScale,
          noiseScaleW: noiseScaleW,
          lengthScale: lengthScale,
        ),
        numThreads: numThreads,
        debug: debug,
        provider: 'cpu',
      );

    case 'kokoro':
      return sherpa.OfflineTtsModelConfig(
        kokoro: sherpa.OfflineTtsKokoroModelConfig(
          model: message['modelPath'] as String,
          voices: message['voicesPath'] as String,
          tokens: tokens,
          dataDir: dataDir,
          dictDir: dictDir,
          lexicon: lexicon,
          lang: message['lang'] as String? ?? '',
          lengthScale: lengthScale,
        ),
        numThreads: numThreads,
        debug: debug,
        provider: 'cpu',
      );

    case 'matcha':
      return sherpa.OfflineTtsModelConfig(
        matcha: sherpa.OfflineTtsMatchaModelConfig(
          acousticModel: message['acousticPath'] as String,
          vocoder: message['vocoderPath'] as String,
          tokens: tokens,
          lexicon: lexicon,
          dataDir: dataDir,
          dictDir: dictDir,
          noiseScale: noiseScale,
          lengthScale: lengthScale,
        ),
        numThreads: numThreads,
        debug: debug,
        provider: 'cpu',
      );

    default:
      throw SherpaTtsException('Unknown model type "$type"');
  }
}

/// Synthesizes [text] by splitting into punctuation-aware prosody spans,
/// generating speech for each span, applying speech boundary trimming and
/// edge fades, and inserting physical zero-PCM silence gaps.
///
/// If [gapSec] > 0, it is applied after the final span; otherwise the final
/// span's prosodic pause is used.
Float32List _synthesizeWithProsody(
  sherpa.OfflineTts engine,
  String text,
  sherpa.OfflineTtsGenerationConfig genConfig,
  double gapSec, {
  int sentenceGapMs = 0,
}) {
  final spans = splitProsodySpans(
    text,
    sentenceGapMs: sentenceGapMs,
    silenceScaleMultiplier: 1.0,
  );

  if (spans.isEmpty) {
    return Float32List(0);
  }

  // Fast path for single span without internal punctuation breaks
  if (spans.length == 1) {
    final audio = engine.generateWithConfig(
      text: spans.first.text,
      config: genConfig,
    );
    final effectiveGap = gapSec > 0 ? gapSec : spans.first.pauseAfterSec;
    return _trimFadeAndGap(audio.samples, audio.sampleRate, effectiveGap);
  }

  // Multi-span prosody synthesis
  final buffers = <Float32List>[];
  var totalLength = 0;
  final sampleRate = engine.sampleRate;

  for (var i = 0; i < spans.length; i++) {
    final span = spans[i];
    if (span.text.trim().isEmpty) continue;

    final audio = engine.generateWithConfig(
      text: span.text,
      config: genConfig,
    );

    final isLast = (i == spans.length - 1);
    final pauseSec = isLast
        ? (gapSec > 0 ? gapSec : span.pauseAfterSec)
        : span.pauseAfterSec;

    final processed = _trimFadeAndGap(audio.samples, sampleRate, pauseSec);
    if (processed.isNotEmpty) {
      buffers.add(processed);
      totalLength += processed.length;
    }
  }

  if (buffers.isEmpty) return Float32List(0);
  if (buffers.length == 1) return buffers.first;

  final combined = Float32List(totalLength);
  var offset = 0;
  for (final buf in buffers) {
    combined.setAll(offset, buf);
    offset += buf.length;
  }
  return combined;
}

/// Trims leading/trailing silence, applies edge fades, and appends [gapSec]
/// of baked silence. Shared by the file and in-memory synthesis paths.
///
/// The buffer is freshly produced by the engine so ownership is unconditional
/// — no aliasing concern with the caller.
Float32List _trimFadeAndGap(
  Float32List samples,
  int sampleRate,
  double gapSec,
) {
  final bounds = findSpeechBounds(samples, sampleRate);
  final startIdx = (bounds.startSec * sampleRate).round().clamp(
    0,
    samples.length,
  );
  final endIdx = (bounds.endSec * sampleRate).round().clamp(
    0,
    samples.length,
  );
  final trimmed = startIdx < endIdx
      ? samples.sublist(startIdx, endIdx)
      : samples;
  var out = trimmed;
  if (out.isNotEmpty) {
    applyEdgeFade(out, sampleRate);
  }

  // Append the inter-chunk pause as baked silence. The player's speed
  // stretches it, so the controller passes the already-compensated
  // duration via bakedGapForRate.
  final gapSamples = (gapSec * sampleRate).round();
  if (gapSamples > 0) {
    final withGap = Float32List(out.length + gapSamples);
    withGap.setAll(0, out);
    out = withGap;
  }
  return out;
}

/// Computes normalized waveform amplitude peaks (0.12 to 1.0) from raw PCM samples.
List<double> _extractPeaks(Float32List samples, {int targetBars = 64}) {
  if (samples.isEmpty) return List.filled(targetBars, 0.2);
  final peaks = List<double>.filled(targetBars, 0.0);
  final samplesPerBar = (samples.length / targetBars).ceil();
  if (samplesPerBar <= 0) return List.filled(targetBars, 0.2);

  var maxGlobal = 0.0;
  for (var i = 0; i < targetBars; i++) {
    final start = i * samplesPerBar;
    final end = (start + samplesPerBar).clamp(0, samples.length);
    var peak = 0.0;
    for (var j = start; j < end; j++) {
      final abs = samples[j].abs();
      if (abs > peak) peak = abs;
    }
    peaks[i] = peak;
    if (peak > maxGlobal) maxGlobal = peak;
  }

  if (maxGlobal > 0.0) {
    for (var i = 0; i < targetBars; i++) {
      peaks[i] = (peaks[i] / maxGlobal).clamp(0.12, 1.0);
    }
  } else {
    peaks.fillRange(0, targetBars, 0.2);
  }
  return peaks;
}
