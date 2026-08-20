import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:readaway/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:readaway/src/router/router.dart';

import 'src/core/services/services.dart';
import 'src/features/reader/presentation/bloc/reader_bloc.dart';

class ReadAway extends StatefulWidget {
  const ReadAway({super.key});

  @override
  State<ReadAway> createState() => _ReadAwayState();
}

class _ReadAwayState extends State<ReadAway> {
  @override
  void initState() {
    // Initialize the app lifecycle manager
    appLifecycleManager.initialize();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final router = GetIt.I.get<AppRouter>().router;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I.get<ReaderBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I.get<SettingsBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'ReadAway',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        routerConfig: router,
      ),
    );
  }
}
