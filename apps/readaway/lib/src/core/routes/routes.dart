library;

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

class Routes {
  final String path;
  final String name;

  const Routes({
    required this.path,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Routes &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          name == other.name);

  @override
  int get hashCode => Object.hash(runtimeType, path, name);

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
  Routes get library => Routes(path: '/', name: 'Library');
  Routes get reader => Routes(path: '/reader', name: 'Reader');
  Routes get settings => Routes(path: '/settings', name: 'Settings');
  Routes get customFonts => Routes(path: 'custom-fonts', name: 'CustomFonts');
  Routes get ttsPlayer => Routes(path: '/tts-player', name: 'TtsPlayer');
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
