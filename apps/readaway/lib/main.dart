import 'package:flutter/material.dart';
import 'package:readaway/src/app.dart';

import 'src/core/config/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  runApp(const ReadAway());
}
