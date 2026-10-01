import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:hyper_render_devtools/hyper_render_devtools.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'src/app.dart';
import 'src/core/bootstrap/single_instance_bootstrap.dart';
import 'src/core/config/injection.dart';
import 'src/core/services/file_open_service.dart';

Future<void> main([List<String> args = const []]) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Register DevTools service extensions (debug mode only, no-op in release).
      assert(() {
        HyperRenderDevtools.register();
        return true;
      }());

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

      // Before timezone setup and DI: a duplicate launch has already handed its
      // document to the running instance, so it should not boot the app at all.
      if (!await SingleInstanceBootstrap.claim(args: args)) {
        exit(0);
      }

      // Initialise the timezone database used for scheduling notifications.
      tz.initializeTimeZones();

      await configureDependencies();

      // A duplicate that launched while this process was still booting queued
      // its document for us; services exist now, so replay it.
      SingleInstanceBootstrap.drainPendingHandoffs();

      if (args.isNotEmpty) {
        GetIt.I<FileOpenService>().initializeWithArgs(args);
      }

      runApp(const Readaway());
    },
    (error, stackTrace) {
      // crashAnalytics.onUncaughtError(error, stackTrace);
      debugPrint('UNCAUGHT ERROR: $error\n$stackTrace');
    },
  );
}
