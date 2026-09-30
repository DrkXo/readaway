import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

class Routes extends Equatable {
  final String path;
  final String name;

  const Routes({
    required this.path,
    required this.name,
  });

  @override
  List<Object?> get props => [path, name];

  @override
  bool? get stringify => true;

  /// Non-empty path segments: '/settings/fonts' -> ['settings', 'fonts'].
  /// Tolerates trailing slashes: '/settings/fonts/' -> same result.
  List<String> get segments =>
      path.split('/').where((s) => s.isNotEmpty).toList(growable: false);

  /// Last segment without a slash: '/settings/fonts' -> 'fonts'.
  /// Use this as the relative `path` of a nested GoRoute.
  /// Returns '' for the root route '/'.
  String get lastSegment => segments.isEmpty ? '' : segments.last;

  /// Last segment with a leading slash: '/settings/fonts' -> '/fonts'.
  /// Returns '/' for the root route.
  String get lastPath => segments.isEmpty ? '/' : '/${segments.last}';

  /// Everything before the last segment: '/settings/fonts' -> '/settings'.
  /// Returns '/' for top-level routes ('/settings' -> '/').
  String get parentPath => segments.length <= 1
      ? '/'
      : '/${segments.sublist(0, segments.length - 1).join('/')}';

  /// settings.child('voices', name: 'VoiceLibrary') -> '/settings/voices'
  Routes child(String segment, {required String name}) => Routes(
    path: '${path == '/' ? '' : path}/$segment',
    name: name,
  );

  Routes copyWith({
    String? path,
    String? name,
  }) => Routes(
    path: path ?? this.path,
    name: name ?? this.name,
  );
}

AppRoutes get appRoutes => GetIt.I<AppRoutes>();

@singleton
class AppRoutes {
  final library = const Routes(path: '/', name: 'Library');
  final reader = const Routes(path: '/reader', name: 'Reader');
  final ttsPlayer = const Routes(path: '/tts-player', name: 'TtsPlayer');

  final settings = const Routes(path: '/settings', name: 'Settings');
  late final settingsVoices = settings.child('voices', name: 'VoiceLibrary');
  late final settingsFonts = settings.child('fonts', name: 'CustomFonts');
}

extension RoutesX on Routes {
  Routes withQueryParameters(
    Map<String, String> queryParameters,
  ) {
    return copyWith(
      path:
          '$path?${queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}',
    );
  }
}
