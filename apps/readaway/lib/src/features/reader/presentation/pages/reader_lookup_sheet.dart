import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/services.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entity/reader_lookup.dart';

/// In-app results sheet for dictionary / translate lookups, opened from the
/// reader selection popup as its own route (`/reader/lookup`).
class ReaderLookupSheet extends StatefulWidget {
  const ReaderLookupSheet({super.key, required this.request});

  final ReaderLookupRequest request;

  @override
  State<ReaderLookupSheet> createState() => _ReaderLookupSheetState();
}

class _ReaderLookupSheetState extends State<ReaderLookupSheet> {
  /// Session-persisted so reopening translate keeps the last language.
  static String _lastTargetLanguage = 'en';

  static const _languages = {
    'en': 'English',
    'de': 'German',
    'fr': 'French',
    'es': 'Spanish',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'tr': 'Turkish',
    'uk': 'Ukrainian',
    'zh-CN': 'Chinese',
    'ja': 'Japanese',
    'ar': 'Arabic',
  };

  late String _targetLanguage = _lastTargetLanguage;
  late Future<Object> _future = _fetch();

  Future<Object> _fetch() {
    var text = widget.request.text.trim();
    if (widget.request.kind == ReaderLookupKind.dictionary) {
      // ponytail: the dictionary API is word-based; multi-word selections
      // look up their first word. Full-phrase semantics would need another
      // source.
      text = text.split(RegExp(r'\s+')).first;
    }

    final service = GetIt.I<LookupService>();
    return switch (widget.request.kind) {
      ReaderLookupKind.dictionary => service.define(text),
      ReaderLookupKind.translate => service.translate(
        text,
        targetLanguage: _targetLanguage,
      ),
    };
  }

  void _retry() => setState(() => _future = _fetch());

  void _changeLanguage(String? language) {
    if (language == null || language == _targetLanguage) return;
    setState(() {
      _targetLanguage = _lastTargetLanguage = language;
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColors.scheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: context.appColors.shadowLg,
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                widget.request.kind == ReaderLookupKind.dictionary
                    ? 'Dictionary'
                    : 'Translate',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (widget.request.kind == ReaderLookupKind.translate)
                DropdownButton<String>(
                  value: _targetLanguage,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: [
                    for (final entry in _languages.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: _changeLanguage,
                ),
              IconButton(
                tooltip: 'Close',
                onPressed: context.pop,
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: SingleChildScrollView(
                child: FutureBuilder<Object>(
                  future: _future,
                  builder: (context, snapshot) {
                    final error = snapshot.error;
                    if (error != null) {
                      return _ErrorView(error: error, onRetry: _retry);
                    }
                    if (snapshot.data case final LookupDefinition result) {
                      return _DefinitionView(result: result);
                    }
                    if (snapshot.data case final LookupTranslation result) {
                      return _TranslationView(result: result);
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefinitionView extends StatelessWidget {
  const _DefinitionView({required this.result});

  final LookupDefinition result;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColors.scheme;
    final body = TextStyle(
      fontSize: 14.5,
      height: 1.5,
      color: scheme.onSurface,
    );
    final muted = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: scheme.onSurfaceVariant,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.phonetic != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(result.phonetic!, style: muted),
          ),
        for (final meaning in result.meanings) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              meaning.partOfSpeech,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
          for (final sense in meaning.senses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\u2022 ',
                        style: body.copyWith(color: scheme.primary),
                      ),
                      Expanded(child: Text(sense.definition, style: body)),
                    ],
                  ),
                  if (sense.example != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 1),
                      child: Text(sense.example!, style: muted),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _TranslationView extends StatelessWidget {
  const _TranslationView({required this.result});

  final LookupTranslation result;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColors.scheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.text,
          style: TextStyle(fontSize: 17, height: 1.45, color: scheme.onSurface),
        ),
        if (result.sourceLanguage != null && result.sourceLanguage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'from ${result.sourceLanguage}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColors.scheme;
    final err = error;
    final message = err.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 28, color: scheme.error),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
