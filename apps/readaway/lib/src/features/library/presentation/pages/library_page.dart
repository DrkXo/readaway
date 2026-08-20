import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  Future<void> _pickAndOpen(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xps', 'epub'],
    );

    if (result.isEmpty || result.first.path == null) return;

    final path = result.first.path!;
    final fileName = result.first.name;

    if (context.mounted) {
      context.read<ReaderBloc>().add(
            ReaderEvent.openDocument(path: path, fileName: fileName),
          );
      GoRouter.of(context).push(
        '/reader?path=${Uri.encodeComponent(path)}&fileName=${Uri.encodeComponent(fileName)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _pickAndOpen(context),
          icon: const Icon(Icons.file_open),
          label: const Text('Open Document'),
        ),
      ),
    );
  }
}
