import 'package:equatable/equatable.dart';

/// Configuration for a user-configured translation engine (such as OpenAI,
/// DeepSeek, Groq, OpenRouter, or a local server).
class CustomTranslatorConfig extends Equatable {
  const CustomTranslatorConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiKey,
    required this.model,
    this.temperature = 0.3,
    this.thinkingMode = 'off',
    this.promptTemplate,
    this.isEnabled = true,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String? apiKey;
  final String model;
  final double temperature;
  final String thinkingMode; // 'off', 'enabled', 'native'
  final String? promptTemplate;
  final bool isEnabled;

  static const String defaultPrompt =
      'You are a professional literary translator translating a book from {{sourceLang}} into {{targetLang}}.\n'
      'Book: {{bookTitle}} by {{bookAuthor}}\n'
      'Translate faithfully and naturally, preserving the tone, style and meaning of the original. Keep names and terminology consistent.';

  CustomTranslatorConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    String? thinkingMode,
    String? promptTemplate,
    bool? isEnabled,
  }) {
    return CustomTranslatorConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      thinkingMode: thinkingMode ?? this.thinkingMode,
      promptTemplate: promptTemplate ?? this.promptTemplate,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
    'temperature': temperature,
    'thinkingMode': thinkingMode,
    'promptTemplate': promptTemplate,
    'isEnabled': isEnabled,
  };

  factory CustomTranslatorConfig.fromJson(Map<String, dynamic> json) =>
      CustomTranslatorConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        baseUrl: json['baseUrl'] as String,
        apiKey: json['apiKey'] as String?,
        model: json['model'] as String,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
        thinkingMode: json['thinkingMode'] as String? ?? 'off',
        promptTemplate: json['promptTemplate'] as String?,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    baseUrl,
    apiKey,
    model,
    temperature,
    thinkingMode,
    promptTemplate,
    isEnabled,
  ];
}
