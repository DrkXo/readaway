part of '../services.dart';

/// A word sense listed under one part of speech.
class LookupSense {
  const LookupSense({required this.definition, this.example});

  final String definition;
  final String? example;
}

/// All senses sharing one part of speech.
class LookupMeaning {
  const LookupMeaning({required this.partOfSpeech, required this.senses});

  final String partOfSpeech;
  final List<LookupSense> senses;
}

/// Dictionary lookup result.
class LookupDefinition {
  const LookupDefinition({
    required this.word,
    required this.meanings,
    this.phonetic,
  });

  final String word;
  final String? phonetic;
  final List<LookupMeaning> meanings;
}

/// Translation result.
class LookupTranslation {
  const LookupTranslation({required this.text, this.sourceLanguage});

  final String text;
  final String? sourceLanguage;
}

@lazySingleton
class LookupService {
  LookupService(this._client);

  final HttpService _client;

  /// Defines [word] using Google's unofficial keyless dictionary endpoint.
  Future<LookupDefinition> defineWithGoogle(
    String word, {
    String language = 'en',
  }) async {
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gtx',
      'sl': language,
      'tl': language,
      'hl': language,
      'dt': 'md', // Requests dictionary/meaning definitions
      'q': word,
    });

    final data = asList(await getJson(uri));
    if (data.isEmpty) throw LookupNotFound('No definition found.');

    // Google returns definition objects in the 12th element (index 11 or 12 depending on parameters)
    // Structure: [null, null, null, ..., [ [ "partOfSpeech", [ [ "definition", ... ] ] ] ]]
    final definitionsBlock = data.length > 12 ? asList(data[12]) : const [];
    if (definitionsBlock.isEmpty) throw LookupNotFound('No definition found.');

    final meanings = <LookupMeaning>[];

    for (final rawBlock in definitionsBlock) {
      final block = asList(rawBlock);
      if (block.length < 2) continue;

      final partOfSpeech = block[0] as String? ?? '';
      final rawSenses = asList(block[1]);
      final senses = <LookupSense>[];

      for (final rawSense in rawSenses) {
        final senseList = asList(rawSense);
        if (senseList.isEmpty) continue;

        final definition = senseList[0] as String? ?? '';
        if (definition.isEmpty) continue;

        // Example sentence is usually at index 2 if present
        final example = senseList.length > 2 ? senseList[2] as String? : null;

        senses.add(LookupSense(definition: definition, example: example));
      }

      if (senses.isNotEmpty) {
        meanings.add(LookupMeaning(partOfSpeech: partOfSpeech, senses: senses));
      }
    }

    if (meanings.isEmpty) throw LookupNotFound('No definition found.');

    return LookupDefinition(
      word: word,
      meanings: meanings,
    );
  }

  /// Defines [word] via the keyless Free Dictionary API (English).
  Future<LookupDefinition> define(String word) async {
    final uri = Uri(
      scheme: 'https',
      host: 'api.dictionaryapi.dev',
      pathSegments: ['api', 'v2', 'entries', 'en', word],
    );

    final entries = asList(await getJson(uri));
    if (entries.isEmpty) throw LookupNotFound('No definition found.');

    final entry = asMap(entries.first);
    final meanings = <LookupMeaning>[];
    for (final raw in asList(entry['meanings'])) {
      final meaning = asMap(raw);
      final senses = <LookupSense>[];
      for (final rawSense in asList(meaning['definitions'])) {
        final sense = asMap(rawSense);
        final definition = sense['definition'] as String?;
        if (definition == null || definition.isEmpty) continue;
        senses.add(
          LookupSense(
            definition: definition,
            example: sense['example'] as String?,
          ),
        );
      }
      if (senses.isNotEmpty) {
        meanings.add(
          LookupMeaning(
            partOfSpeech: meaning['partOfSpeech'] as String? ?? '',
            senses: senses,
          ),
        );
      }
    }
    if (meanings.isEmpty) throw LookupNotFound('No definition found.');

    return LookupDefinition(
      word: entry['word'] as String? ?? word,
      phonetic: firstPhonetic(entry),
      meanings: meanings,
    );
  }

  /// Translates [text] with auto-detected source language.
  ///
  /// ponytail: uses Google's keyless `gdt` web endpoint — unofficial and
  /// unversioned; swap for a proper translation API if it starts failing.
  Future<LookupTranslation> translate(
    String text, {
    required String targetLanguage,
  }) async {
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gdt',
      'sl': 'auto',
      'tl': targetLanguage,
      'dt': 't',
      'q': text,
    });

    final data = asList(await getJson(uri));
    final translated = asList(
      data.first,
    ).whereType<List>().map((c) => c.first).join();
    if (translated.isEmpty) throw LookupNotFound('No translation found.');

    return LookupTranslation(
      text: translated,
      sourceLanguage: data.length > 2 ? data[2] as String? : null,
    );
  }

  static List asList(Object? value) => value is List ? value : const [];

  static Map<String, Object?> asMap(Object? value) =>
      value is Map ? value.cast<String, Object?>() : {};

  static String? firstPhonetic(Map<String, Object?> entry) {
    final direct = entry['phonetic'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    for (final raw in asList(entry['phonetics'])) {
      final candidate = asMap(raw)['text'] as String?;
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  /// GETs [uri] and returns the decoded JSON body, mapping network/status
  /// errors onto [LookupException]s. Static so tests exercise the same
  /// mapping without subclassing [LookupService].
  Future<Object?> getJson(Uri uri) async {
    late final Response<Object?> response;
    try {
      response = await _client.get<Object?>(
        path: uri.toString(),
      );

      final data = response.data;
      if (data is String) {
        // Endpoint replied without a JSON content type.
        try {
          return jsonDecode(data);
        } on FormatException {
          throw LookupException('Unexpected response format.');
        }
      }
      return data;
    } catch (error) {
      rethrow;
    }
  }
}
