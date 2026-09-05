import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/reader/supported_document_formats.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/core_widgets.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  Future<void> _pickAndOpen(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: SupportedDocumentFormats.pickerExtensions,
    );

    if (result.isEmpty || result.first.path == null) return;

    final path = result.first.path!;
    final fileName = result.first.name;

    if (context.mounted) {
      GoRouter.of(context).push(
        '${appRoutes.reader.path}?path=${Uri.encodeComponent(path)}&fileName=${Uri.encodeComponent(fileName)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        titleText: 'ReadAway',
      ),
      floatingActionButton: FloatingActionButton.small(
        child: Icon(LucideIcons.folderOpen),
        onPressed: () => _pickAndOpen(context),
      ),
    );
  }
}
