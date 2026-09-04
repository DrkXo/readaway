import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../isolate_service.dart';
import '../../logging_service.dart';
import '../../path_service.dart';
import '../tts_models.dart';
import 'sherpa_isolate_worker_service.dart';
import 'sherpa_model_catalog.dart';
import 'sherpa_tts_model_downloader.dart';

@singleton
class SherpaOnnxTtsService {
  SherpaOnnxTtsService({
    required this._downloader,
    required this._sherpaTtsModelCatalog,
    required this._isolateService,
    required this._pathService,
  });

  final SherpaTtsModelDownloaderService _downloader;
  final SherpaTtsModelCatalogService _sherpaTtsModelCatalog;
  final IsolateService _isolateService;
  final AppPathService _pathService;

  SherpaTtsModelInfo? _activeModel;
  Directory? _modelsRootDir;
  int? _sampleRate;
  int? _speakerCount;

  int _commandId = 0;
  String _nextId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_commandId++}';

  bool _bindingsInitialized = false;

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (!_bindingsInitialized) {
      sherpa.initBindings();
      _bindingsInitialized = true;
    }
    _modelsRootDir ??= await _resolveModelsRootDir();
    await _sherpaTtsModelCatalog.load();

    if (!_isolateService.isSpawned(sherpaTtsIsolateName)) {
      await _isolateService.spawn(
        name: sherpaTtsIsolateName,
        entryPoint: sherpaTtsIsolateEntryPoint,
      );
    }
  }

  Future<Directory> _resolveModelsRootDir() async {
    return _pathService.getTtsModelsDirectory();
  }

  @disposeMethod
  Future<void> dispose() async {
    await _isolateService.disposeIsolate(sherpaTtsIsolateName);
    _activeModel = null;
    _sampleRate = null;
    _speakerCount = null;
  }

  List<SherpaTtsModelInfo> get availableModels => _sherpaTtsModelCatalog.models;

  Directory _modelDir(String modelId) {
    final root = _modelsRootDir;
    if (root == null) {
      throw SherpaTtsException('SherpaOnnxTtsService.init() was not called.');
    }
    return Directory(p.join(root.path, modelId));
  }

  Future<bool> isModelDownloaded(String modelId) async {
    final dir = _modelDir(modelId);
    if (!await dir.exists()) return false;

    final model = _sherpaTtsModelCatalog.byId(modelId);
    if (model == null) return false;

    try {
      final files = await _indexModelFiles(dir);

      final bool structurallyComplete;
      switch (model.type) {
        case SherpaTtsModelType.vits:
          structurallyComplete = files.onnxPrimary != null;
          break;
        case SherpaTtsModelType.kokoro:
          structurallyComplete =
              files.onnxPrimary != null && files.voicesBin != null;
          break;
        case SherpaTtsModelType.matcha:
          structurallyComplete =
              files.onnxPrimary != null && files.onnxSecondary != null;
          break;
      }
      if (!structurallyComplete) return false;

      if (model.needsEspeakData && files.espeakDataDir == null) return false;

      return true;
    } on SherpaTtsException {
      return false;
    }
  }

  Future<List<SherpaTtsModelInfo>> getDownloadedModels() async {
    final result = <SherpaTtsModelInfo>[];
    for (final m in availableModels) {
      if (await isModelDownloaded(m.id)) result.add(m);
    }
    return result;
  }

  Future<void> deleteModel(String modelId) async {
    if (_activeModel?.id == modelId) {
      await _isolateService.sendCommand<bool>(sherpaTtsIsolateName, {
        'id': _nextId(),
        'type': 'unload',
      });
      _activeModel = null;
      _sampleRate = null;
      _speakerCount = null;
    }
    final dir = _modelDir(modelId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Stream<ModelDownloadProgress> downloadModel(SherpaTtsModelInfo model) {
    return _downloader.downloadModel(model, _modelDir(model.id));
  }

  SherpaTtsModelInfo? get activeModel => _activeModel;
  bool get hasLoadedModel => _sampleRate != null;

  Future<void> loadModel(
    String modelId, {
    int numThreads = 2,
    bool debugLogging = false,
  }) async {
    if (_modelsRootDir == null) {
      throw SherpaTtsException('Call init() before loadModel().');
    }
    final model = _sherpaTtsModelCatalog.byId(modelId);
    if (model == null) {
      throw SherpaTtsException('Unknown model id: $modelId');
    }
    final dir = _modelDir(modelId);
    if (!await dir.exists()) {
      throw SherpaTtsException('Model $modelId is not downloaded yet.');
    }

    final files = await _indexModelFiles(dir);
    final message = _buildLoadModelMessage(
      model,
      files,
      numThreads: numThreads,
      debug: debugLogging,
    );

    final result = await _isolateService.sendCommand<Map>(
      sherpaTtsIsolateName,
      message,
    );

    _activeModel = model;
    _sampleRate = result['sampleRate'] as int;
    _speakerCount = result['speakerCount'] as int;
  }

  Future<_ModelFiles> _indexModelFiles(Directory dir) async {
    String? onnxA, onnxB, tokens, voicesBin, dataDir, dictDir;

    final lexiconFiles = <String>[];
    final entries = await dir.list(recursive: true).toList();

    for (final e in entries) {
      final name = p.basename(e.path);
      if (e is File && name.endsWith('.onnx')) {
        if (onnxA == null) {
          onnxA = e.path;
        } else {
          onnxB = e.path;
        }
      } else if (e is File && name == 'tokens.txt') {
        tokens = e.path;
      } else if (e is File &&
          name.startsWith('lexicon') &&
          name.endsWith('.txt')) {
        lexiconFiles.add(e.path);
      } else if (e is File &&
          (name.endsWith('.bin') && name.contains('voices'))) {
        voicesBin = e.path;
      } else if (e is Directory && name.contains('espeak-ng-data')) {
        dataDir = e.path;
      } else if (e is Directory && name.contains('dict')) {
        dictDir = e.path;
      }
    }

    if (dataDir == null && _modelsRootDir != null) {
      final shared = Directory(p.join(_modelsRootDir!.path, 'espeak-ng-data'));
      if (await shared.exists()) {
        dataDir = shared.path;
      }
    }

    if (tokens == null) {
      throw SherpaTtsException(
        'tokens.txt not found in ${dir.path} — is this a valid sherpa-onnx TTS model?',
      );
    }

    lexiconFiles.sort();

    return _ModelFiles(
      onnxPrimary: onnxA,
      onnxSecondary: onnxB,
      tokens: tokens,
      lexicon: lexiconFiles.isEmpty ? null : lexiconFiles.join(','),
      voicesBin: voicesBin,
      espeakDataDir: dataDir,
      dictDir: dictDir,
    );
  }

  Map<String, dynamic> _buildLoadModelMessage(
    SherpaTtsModelInfo model,
    _ModelFiles files, {
    required int numThreads,
    required bool debug,
  }) {
    final base = <String, dynamic>{
      'id': _nextId(),
      'type': 'loadModel',
      'numThreads': numThreads,
      'debug': debug,
      'tokens': files.tokens,
      'lexicon': files.lexicon ?? '',
      'dataDir': files.espeakDataDir ?? '',
      'dictDir': files.dictDir ?? '',
    };

    switch (model.type) {
      case SherpaTtsModelType.vits:
        if (files.onnxPrimary == null) {
          throw SherpaTtsException(
            'No .onnx file found for VITS model ${model.id}',
          );
        }
        return {
          ...base,
          'modelType': 'vits',
          'modelPath': files.onnxPrimary,
        };

      case SherpaTtsModelType.kokoro:
        if (files.onnxPrimary == null || files.voicesBin == null) {
          throw SherpaTtsException(
            'Kokoro model ${model.id} needs both a .onnx file and a voices .bin file.',
          );
        }

        final isMultiLingual = model.languageCode == 'multi';
        if (isMultiLingual &&
            (files.lexicon == null || files.lexicon!.isEmpty)) {
          throw SherpaTtsException(
            'Kokoro model ${model.id} is multi-lingual but no lexicon*.txt '
            'files were found — re-download the model, the archive is '
            'likely incomplete.',
          );
        }
        return {
          ...base,
          'modelType': 'kokoro',
          'modelPath': files.onnxPrimary,
          'voicesPath': files.voicesBin,
          'lang': isMultiLingual ? '' : model.languageCode,
        };

      case SherpaTtsModelType.matcha:
        final vocoderName = model.vocoderFileName;
        String? acoustic, vocoder;
        for (final f in [files.onnxPrimary, files.onnxSecondary]) {
          if (f == null) continue;
          if (vocoderName != null && p.basename(f) == vocoderName) {
            vocoder = f;
          } else {
            acoustic = f;
          }
        }
        if (acoustic == null || vocoder == null) {
          throw SherpaTtsException(
            'Matcha model ${model.id} needs an acoustic model and a vocoder .onnx.',
          );
        }
        return {
          ...base,
          'modelType': 'matcha',
          'acousticPath': acoustic,
          'vocoderPath': vocoder,
        };
    }
  }

  int get sampleRate {
    final rate = _sampleRate;
    if (rate == null) throw SherpaTtsException('No model loaded.');
    return rate;
  }

  int get speakerCount {
    final count = _speakerCount;
    if (count == null) throw SherpaTtsException('No model loaded.');
    return count;
  }

  List<SherpaTtsSpeaker> get speakers {
    final count = speakerCount;
    return List.generate(
      count,
      (i) => SherpaTtsSpeaker(id: i, label: 'Speaker $i'),
    );
  }

  Future<TtsAudio> generate({
    required String text,
    int speakerId = 0,
    double speed = 1.0,
  }) async {
    if (!hasLoadedModel) {
      throw SherpaTtsException('No model loaded. Call loadModel() first.');
    }
    final result = await _isolateService.sendCommand<Map>(
      sherpaTtsIsolateName,
      {
        'id': _nextId(),
        'type': 'generate',
        'text': text,
        'speakerId': speakerId,
        'speed': speed,
      },
    );
    return TtsAudio(
      samples: result['samples'] as Float32List,
      sampleRate: result['sampleRate'] as int,
    );
  }

  /// Synthesizes text directly to a WAV file inside the worker isolate.
  Future<({File file, double duration, List<double> waveform})> generateToFile({
    required String text,
    required String outputPath,
    int speakerId = 0,
    double speed = 1.0,
  }) async {
    if (!hasLoadedModel) {
      throw const TtsModelNotLoadedException();
    }
    try {
      final result = await _isolateService.sendCommand<Map>(
        sherpaTtsIsolateName,
        {
          'id': _nextId(),
          'type': 'generateToFile',
          'text': text,
          'outputPath': outputPath,
          'speakerId': speakerId,
          'speed': speed,
        },
      );
      final rawWaveform = result['waveform'] as List<dynamic>?;
      final waveform = rawWaveform?.map((e) => (e as num).toDouble()).toList(growable: false) ?? const <double>[];

      return (
        file: File(result['outputPath'] as String),
        duration: (result['duration'] as num).toDouble(),
        waveform: waveform,
      );
    } catch (e, st) {
      logger.e('Failed to generate WAV file with Sherpa ONNX', e, st);
      if (e is TtsException) rethrow;
      throw TtsSynthesisException('Synthesis to file failed: $e', e);
    }
  }

  Stream<Float32List> generateStreaming({
    required String text,
    int speakerId = 0,
    double speed = 1.0,
  }) {
    if (!hasLoadedModel) {
      throw SherpaTtsException('No model loaded. Call loadModel() first.');
    }
    return _isolateService.sendStreamCommand<Float32List>(
      sherpaTtsIsolateName,
      {
        'id': _nextId(),
        'type': 'generateStream',
        'text': text,
        'speakerId': speakerId,
        'speed': speed,
      },
    );
  }

  Future<File> synthesizeToFile({
    required String text,
    required String outputPath,
    int speakerId = 0,
    double speed = 1.0,
  }) async {
    final audio = await generate(
      text: text,
      speakerId: speakerId,
      speed: speed,
    );
    final ok = sherpa.writeWave(
      filename: outputPath,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );
    if (!ok) {
      throw SherpaTtsException('Failed to write WAV to $outputPath');
    }
    return File(outputPath);
  }
}

class _ModelFiles {
  _ModelFiles({
    this.onnxPrimary,
    this.onnxSecondary,
    required this.tokens,
    this.lexicon,
    this.voicesBin,
    this.espeakDataDir,
    this.dictDir,
  });

  final String? onnxPrimary;
  final String? onnxSecondary;
  final String tokens;
  final String? lexicon;
  final String? voicesBin;
  final String? espeakDataDir;
  final String? dictDir;
}
