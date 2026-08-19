import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:readaway/src/router/router.dart';

import 'src/features/reader/presentation/bloc/reader_bloc.dart';

class ReadAway extends StatelessWidget {
  const ReadAway({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GetIt.I.get<AppRouter>().router;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I.get<ReaderBloc>(),
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
