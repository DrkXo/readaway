import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:timezone/data/latest_all.dart' as tz;

import 'src/app.dart';
import 'src/core/config/injection.dart';

Future<void> main() async {
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

  runApp(const ReadAway());
}
