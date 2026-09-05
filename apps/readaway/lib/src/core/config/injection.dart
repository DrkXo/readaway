import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

part 'keyboard.dart';

final GetIt _sl = GetIt.instance;

@InjectableInit(
  preferRelativeImports: true,
  throwOnMissingDependencies: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  if (!kReleaseMode) {
    GetIt.instance.debugEventsEnabled = true;
  }

  await _sl.init();

  // waits for worker + all async deps
  await _sl.allReady();
}

