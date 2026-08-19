import 'package:flutter/material.dart';
import 'package:readaway/test_page.dart';

Future<void> main() async {
  runApp(
    const ReadAway(),
  );
}

class ReadAway extends StatelessWidget {
  const ReadAway({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadAway Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}
