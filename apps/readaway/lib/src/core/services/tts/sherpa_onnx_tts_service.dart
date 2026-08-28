part of '../services.dart';

@singleton
class SherpaOnnxTtsService {
  SherpaOnnxTtsService({
    required this._downloader,
    required this._sherpaTtsModelCatalog,
  });

  final SherpaTtsModelDownloader _downloader;

  sherpa.OfflineTts? _tts;
  SherpaTtsModelInfo? _activeModel;
  Directory? _modelsRootDir;

  final SherpaTtsModelCatalog _sherpaTtsModelCatalog;

  bool _bindingsInitialized = false;

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  /// Call once at app startup (or via an injectable `@preResolve` module)
  /// before using any other method.
  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (!_bindingsInitialized) {
      // Loads the native sherpa-onnx shared library. Required on desktop;
      // harmless to call on mobile too.
      sherpa.initBindings();
      _bindingsInitialized = true;
    }
    _modelsRootDir ??= await _resolveModelsRootDir();
    await _sherpaTtsModelCatalog.load();
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
  void dispose() {
    _tts?.free();
    _tts = null;
    _activeModel = null;
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
      _tts?.free();
      _tts = null;
      _activeModel = null;
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
  Stream<ModelDownloadProgress> downloadModel(SherpaTtsModelInfo model) {
    return _downloader.downloadModel(model, _modelDir(model.id));
  }

  // ---------------------------------------------------------------------
  // Loading a model for synthesis
  // ---------------------------------------------------------------------

  SherpaTtsModelInfo? get activeModel => _activeModel;
  bool get hasLoadedModel => _tts != null;

  /// Loads [modelId] (must already be downloaded) into memory, replacing
  /// whatever was previously loaded. Cheap to call again to switch voices —
  /// the previous native instance is freed first.
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
    final modelConfig = _buildModelConfig(
      model,
      files,
      numThreads,
      debugLogging,
    );

    final config = sherpa.OfflineTtsConfig(
      model: modelConfig,
      // Batches multiple sentences per generate() call for VITS-family
      // models; higher can be a little more efficient for long paragraphs.
      maxNumSenetences: 1,
    );

    final newTts = sherpa.OfflineTts(config);

    // Swap only after the new engine constructed successfully.
    _tts?.free();
    _tts = newTts;
    _activeModel = model;
  }

  /// Scans an extracted model directory and buckets files by role so we
  /// don't have to hardcode exact filenames per model (they vary release
  /// to release).
  Future<_ModelFiles> _indexModelFiles(Directory dir) async {
    String? onnxA, onnxB, tokens, lexicon, voicesBin, dataDir, dictDir;
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
      } else if (e is File && (name == 'lexicon.txt')) {
        lexicon = e.path;
      } else if (e is File &&
          (name.endsWith('.bin') && name.contains('voices'))) {
        voicesBin = e.path;
      } else if (e is Directory && name.contains('espeak-ng-data')) {
        dataDir = e.path;
      } else if (e is Directory && name.contains('dict')) {
        dictDir = e.path;
      }
    }

    if (tokens == null) {
      throw SherpaTtsException(
        'tokens.txt not found in ${dir.path} — is this a valid sherpa-onnx TTS model?',
      );
    }

    return _ModelFiles(
      onnxPrimary: onnxA,
      onnxSecondary: onnxB,
      tokens: tokens,
      lexicon: lexicon,
      voicesBin: voicesBin,
      espeakDataDir: dataDir,
      dictDir: dictDir,
    );
  }

  sherpa.OfflineTtsModelConfig _buildModelConfig(
    SherpaTtsModelInfo model,
    _ModelFiles files,
    int numThreads,
    bool debug,
  ) {
    switch (model.type) {
      case SherpaTtsModelType.vits:
        if (files.onnxPrimary == null) {
          throw SherpaTtsException(
            'No .onnx file found for VITS model ${model.id}',
          );
        }
        return sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: files.onnxPrimary!,
            tokens: files.tokens,
            lexicon: files.lexicon ?? '',
            dataDir: files.espeakDataDir ?? '',
            dictDir: files.dictDir ?? '',
          ),
          numThreads: numThreads,
          debug: debug,
          provider: 'cpu',
        );

      case SherpaTtsModelType.kokoro:
        if (files.onnxPrimary == null || files.voicesBin == null) {
          throw SherpaTtsException(
            'Kokoro model ${model.id} needs both a .onnx file and a voices .bin file.',
          );
        }
        return sherpa.OfflineTtsModelConfig(
          kokoro: sherpa.OfflineTtsKokoroModelConfig(
            model: files.onnxPrimary!,
            voices: files.voicesBin!,
            tokens: files.tokens,
            dataDir: files.espeakDataDir ?? '',
            dictDir: files.dictDir ?? '',
            lexicon: files.lexicon ?? '',
            lang: model.languageCode == 'multi' ? '' : model.languageCode,
          ),
          numThreads: numThreads,
          debug: debug,
          provider: 'cpu',
        );

      case SherpaTtsModelType.matcha:
        // Vocoder is downloaded next to the acoustic model (see
        // downloadModel), so the two .onnx files live in the same dir.
        // We disambiguate by filename: the vocoder is the one whose name
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
        return sherpa.OfflineTtsModelConfig(
          matcha: sherpa.OfflineTtsMatchaModelConfig(
            acousticModel: acoustic,
            vocoder: vocoder,
            tokens: files.tokens,
            lexicon: files.lexicon ?? '',
            dataDir: files.espeakDataDir ?? '',
            dictDir: files.dictDir ?? '',
          ),
          numThreads: numThreads,
          debug: debug,
          provider: 'cpu',
        );
    }
  }

  // ---------------------------------------------------------------------
  // Speakers (multi-speaker models like Kokoro)
  // ---------------------------------------------------------------------

  int get sampleRate {
    final tts = _tts;
    if (tts == null) throw SherpaTtsException('No model loaded.');
    return tts.sampleRate;
  }

  int get speakerCount {
    final tts = _tts;
    if (tts == null) throw SherpaTtsException('No model loaded.');
    return tts.numSpeakers;
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
  /// Runs on the calling isolate — for very long text (multiple paragraphs)
  /// prefer chunking with a text splitter and calling this per-chunk so the
  /// UI can start playing the first chunk while later ones are still being
  /// generated, and so a single call doesn't block the UI thread for too
  /// long. See `TextChunker` alongside this service.
  TtsAudio generate({
    required String text,
    int speakerId = 0,
    double speed = 1.0,
  }) {
    final tts = _tts;
    if (tts == null) {
      throw SherpaTtsException('No model loaded. Call loadModel() first.');
    }
    if (text.trim().isEmpty) {
      return TtsAudio(samples: Float32List(0), sampleRate: tts.sampleRate);
    }
    final audio = tts.generate(text: text, sid: speakerId, speed: speed);
    return TtsAudio(samples: audio.samples, sampleRate: audio.sampleRate);
  }

  /// Like [generate], but streams partial sample chunks as they're produced
  /// (useful for starting playback before the whole utterance is ready, or
  /// for a live waveform / word-progress indicator).
  ///
  /// The returned stream completes after the final chunk.
  Stream<Float32List> generateStreaming({
    required String text,
    int speakerId = 0,
    double speed = 1.0,
  }) {
    final tts = _tts;
    if (tts == null) {
      throw SherpaTtsException('No model loaded. Call loadModel() first.');
    }
    final controller = StreamController<Float32List>();
    controller.onListen = () {
      try {
        tts.generateWithCallback(
          text: text,
          sid: speakerId,
          speed: speed,
          callback: (samples) {
            controller.add(samples);
            // Return 1 to keep generating, 0 would stop early.
            return 1;
          },
        );
        controller.close();
      } catch (e) {
        controller.addError(
          SherpaTtsException('Streaming synthesis failed: $e'),
        );
        controller.close();
      }
    };
    return controller.stream;
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
    final audio = generate(text: text, speakerId: speakerId, speed: speed);
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
