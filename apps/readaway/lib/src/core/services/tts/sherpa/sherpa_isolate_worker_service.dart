import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

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

          final modelConfig = _sherpaConfigFromMessage(message);
          final config = sherpa.OfflineTtsConfig(
            model: modelConfig,
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
          final speakerId = message['speakerId'] as int? ?? 0;
          final speed = (message['speed'] as num?)?.toDouble() ?? 1.0;

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
          final audio = engine.generate(
            text: text,
            sid: speakerId,
            speed: speed,
          );
          reply(
            id,
            result: {
              'samples': audio.samples,
              'sampleRate': audio.sampleRate,
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
          final speakerId = message['speakerId'] as int? ?? 0;
          final speed = (message['speed'] as num?)?.toDouble() ?? 1.0;

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
          final audio = engine.generate(
            text: text,
            sid: speakerId,
            speed: speed,
          );
          final ok = sherpa.writeWave(
            filename: outputPath,
            samples: audio.samples,
            sampleRate: audio.sampleRate,
          );
          if (!ok) {
            reply(id, error: 'Failed to write WAV to $outputPath');
            break;
          }
          final duration = audio.samples.length / audio.sampleRate;
          final peaks = _extractPeaks(audio.samples, targetBars: 64);
          reply(
            id,
            result: {
              'outputPath': outputPath,
              'duration': duration,
              'sampleRate': audio.sampleRate,
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
          final speakerId = message['speakerId'] as int? ?? 0;
          final speed = (message['speed'] as num?)?.toDouble() ?? 1.0;

          engine.generateWithCallback(
            text: text,
            sid: speakerId,
            speed: speed,
            callback: (samples) {
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

sherpa.OfflineTtsModelConfig _sherpaConfigFromMessage(Map message) {
  final type = message['modelType'] as String;
  final numThreads = message['numThreads'] as int? ?? 2;
  final debug = message['debug'] as bool? ?? false;
  final tokens = message['tokens'] as String;
  final lexicon = message['lexicon'] as String? ?? '';
  final dataDir = message['dataDir'] as String? ?? '';
  final dictDir = message['dictDir'] as String? ?? '';

  switch (type) {
    case 'vits':
      return sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: message['modelPath'] as String,
          tokens: tokens,
          lexicon: lexicon,
          dataDir: dataDir,
          dictDir: dictDir,
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
        ),
        numThreads: numThreads,
        debug: debug,
        provider: 'cpu',
      );

    default:
      throw SherpaTtsException('Unknown model type "$type"');
  }
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
