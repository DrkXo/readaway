library;

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
  Routes get reader => Routes(path: '/reader', name: 'Reader');
  Routes get library => Routes(path: '/library', name: 'Library');
  Routes get settings => Routes(path: '/settings', name: 'Settings');
  Routes get readerLookup => Routes(path: '/reader/lookup', name: 'ReaderLookup');
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
