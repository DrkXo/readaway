part of '../../services.dart';

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
