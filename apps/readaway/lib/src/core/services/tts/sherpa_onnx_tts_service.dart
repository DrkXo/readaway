part of '../services.dart';

@singleton
class SherpaOnnxTtsService {
  SherpaOnnxTtsService({
    required this._downloader,
    required this._sherpaTtsModelCatalog,
    required this._isolateService,
  });

  final SherpaTtsModelDownloader _downloader;
  final SherpaTtsModelCatalog _sherpaTtsModelCatalog;
  final IsolateService _isolateService;

  SherpaTtsModelInfo? _activeModel;
  Directory? _modelsRootDir;
  int? _sampleRate;
  int? _speakerCount;

  int _commandId = 0;
  String _nextId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_commandId++}';

  bool _bindingsInitialized = false;

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  /// Call once at app startup (or via an injectable `@preResolve` module)
  /// before using any other method.
  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (!_bindingsInitialized) {
      // Needed on the main isolate too, for the lightweight sherpa.writeWave
      // call used by synthesizeToFile. The heavy engine itself lives in the
      // dedicated worker isolate spawned below.
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
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'tts_models'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @disposeMethod
  Future<void> dispose() async {
    await _isolateService.disposeIsolate(sherpaTtsIsolateName);
    _activeModel = null;
    _sampleRate = null;
    _speakerCount = null;
  }

  // ---------------------------------------------------------------------
  // Catalog / model discovery
  // ---------------------------------------------------------------------

  /// Every voice the user could download, derived from the bundled
  /// sherpa-onnx release manifest.
  List<SherpaTtsModelInfo> get availableModels => _sherpaTtsModelCatalog.models;

  Directory _modelDir(String modelId) {
    final root = _modelsRootDir;
    if (root == null) {
      throw SherpaTtsException('SherpaOnnxTtsService.init() was not called.');
    }
    return Directory(p.join(root.path, modelId));
  }

  /// Whether [modelId]'s files are already extracted on disk.
  Future<bool> isModelDownloaded(String modelId) async {
    final dir = _modelDir(modelId);
    if (!await dir.exists()) return false;
    final files = await dir.list(recursive: true).toList();
    return files.any((f) => f is File && f.path.endsWith('.onnx'));
  }

  Future<List<SherpaTtsModelInfo>> getDownloadedModels() async {
    final result = <SherpaTtsModelInfo>[];
    for (final m in availableModels) {
      if (await isModelDownloaded(m.id)) result.add(m);
    }
    return result;
  }

  /// Frees disk space by deleting a downloaded voice. If it's the active
  /// model, unloads it first.
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

  // ---------------------------------------------------------------------
  // Download + extract
  // ---------------------------------------------------------------------

  /// Downloads and extracts [model], reporting progress. Safe to call again
  /// for an already-downloaded model (re-downloads/overwrites); check
  /// [isModelDownloaded] first if you want to skip that.
  ///
  /// Cancel by cancelling your subscription to the returned stream; the
  /// underlying Dio request is cancelled with it.
  ///
  /// This stays on the main isolate — it's I/O bound (network + disk), not
  /// CPU/memory heavy, so there's no jank/OOM risk here.
  Stream<ModelDownloadProgress> downloadModel(SherpaTtsModelInfo model) {
    return _downloader.downloadModel(model, _modelDir(model.id));
  }

  // ---------------------------------------------------------------------
  // Loading a model for synthesis
  // ---------------------------------------------------------------------

  SherpaTtsModelInfo? get activeModel => _activeModel;
  bool get hasLoadedModel => _sampleRate != null;

  /// Loads [modelId] (must already be downloaded) into memory, replacing
  /// whatever was previously loaded. Cheap to call again to switch voices —
  /// the previous native instance is freed *before* the new one is built,
  /// inside the worker isolate, so peak memory never has to hold two
  /// engines at once.
  ///
  /// File indexing/validation happens here on the main isolate (cheap
  /// directory listing) so obviously-missing-file errors fail fast without
  /// a round trip; the actual model construction happens in the isolate.
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

  /// Scans an extracted model directory and buckets files by role so we
  /// don't have to hardcode exact filenames per model (they vary release
  /// to release). Pure directory listing — safe on the main isolate.
  Future<_ModelFiles> _indexModelFiles(Directory dir) async {
    String? onnxA, onnxB, tokens, voicesBin, dataDir, dictDir;
    // Multi-lingual Kokoro models (>= v1.0) ship one lexicon file per
    // language — e.g. lexicon-us-en.txt, lexicon-gb-en.txt, lexicon-zh.txt
    // — instead of a single lexicon.txt. The native API wants all of them
    // as one comma-joined string (mirrors the --kokoro-lexicon=a.txt,b.txt
    // CLI flag), so collect every lexicon*.txt rather than matching only
    // the exact filename.
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

    // Piper-family models (and kokoro/matcha/melo) need the shared
    // espeak-ng-data directory, which the downloader installs once into the
    // models root rather than inside each model folder.
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

    // Sort for deterministic ordering — directory listing order isn't
    // guaranteed to be stable across platforms/filesystems, and the join
    // order shouldn't matter for lexicon lookups but stability makes this
    // reproducible/debuggable.
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

  /// Builds the plain-data `loadModel` command sent to the worker isolate.
  /// Deliberately does NOT construct any `sherpa.*ModelConfig` object here —
  /// those wrap native state and can't cross the isolate boundary, so the
  /// equivalent construction happens inside `sherpaTtsIsolateEntryPoint`.
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
        // Multi-lingual Kokoro (>= v1.0) is driven by the per-language
        // lexicon files (already joined into `base['lexicon']` above) with
        // `lang` left empty; single-language voices go the other way and
        // just set `lang`. Passing neither is what produces the native
        // "please pass --kokoro-lexicon or --kokoro-lang" warning and
        // silently wrong/empty pronunciation.
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
        // Vocoder is downloaded next to the acoustic model (see
        // downloadModel), so the two .onnx files live in the same dir. We
        // disambiguate by filename: the vocoder is the one whose name
        // matches model.vocoderFileName.
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

  // ---------------------------------------------------------------------
  // Speakers (multi-speaker models like Kokoro)
  // ---------------------------------------------------------------------

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

  /// Best-effort speaker list. sherpa-onnx doesn't expose per-speaker
  /// names, only a count — so beyond "Speaker 0, Speaker 1, ..." you'll
  /// want to ship your own id->name mapping per model (e.g. Kokoro's voice
  /// ids like `af_heart`, `bm_george` are documented on its model card).
  List<SherpaTtsSpeaker> get speakers {
    final count = speakerCount;
    return List.generate(
      count,
      (i) => SherpaTtsSpeaker(id: i, label: 'Speaker $i'),
    );
  }

  // ---------------------------------------------------------------------
  // Synthesis
  // ---------------------------------------------------------------------

  /// Synthesizes [text] with the currently loaded model.
  ///
  /// [speakerId] selects a built-in speaker for multi-speaker models
  /// (ignored otherwise). [speed] is a multiplier: 1.0 normal, <1.0 slower,
  /// >1.0 faster.
  ///
  /// Runs entirely in the dedicated TTS isolate, so a long synthesis never
  /// blocks the UI thread. For very long text (multiple paragraphs) prefer
  /// chunking with a text splitter and calling this per-chunk so playback
  /// can start on the first chunk while later ones are still generating.
  /// See `TextChunker` alongside this service.
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

  /// Like [generate], but streams partial sample chunks as they're produced
  /// (useful for starting playback before the whole utterance is ready, or
  /// for a live waveform / word-progress indicator).
  ///
  /// The returned stream completes after the final chunk. Note: cancelling
  /// your subscription stops delivering chunks to you, but the native
  /// generation call inside the isolate currently runs to completion
  /// regardless (sherpa's callback API doesn't expose a cancel token) — if
  /// you need hard cancellation, kill/respawn the isolate.
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

  /// Synthesizes [text] and writes it straight to a WAV file at
  /// [outputPath] — handy for pre-rendering a whole chapter for offline
  /// listening/downloads within the app.
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
