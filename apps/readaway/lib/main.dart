import 'dart:async';

import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'src/app.dart';
import 'src/core/config/injection.dart';
import 'src/core/services/file_open_service.dart';

Future<void> main([List<String> args = const []]) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      LicenseRegistry.addLicense(() async* {
        for (final family in [
          'NotoSerif',
          'NotoSans',
          'FiraCode',
          'JetBrainsMono',
        ]) {
          yield LicenseEntryWithLineBreaks(
            ['google_fonts'],
            await rootBundle.loadString('assets/google_fonts/OFL-$family.txt'),
          );
        }
      });

      // Initialise the timezone database used for scheduling notifications.
      tz.initializeTimeZones();

      await configureDependencies();

      if (args.isNotEmpty) {
        GetIt.I<FileOpenService>().initializeWithArgs(args);
      }

      runApp(const ReadAway());
    },
    (error, stackTrace) {
      // crashAnalytics.onUncaughtError(error, stackTrace);
      debugPrint('UNCAUGHT ERROR: $error\n$stackTrace');
    },
  );
}
