import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../../../core/models/reader/supported_document_formats.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';

@lazySingleton
class FilePickerDataSource {
  Future<RecentDocument?> pickDocumentFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: SupportedDocumentFormats.pickerExtensions,
    );

    if (result.isEmpty || result.first.path == null) {
      return null;
    }

    final file = result.first;
    final filePath = file.path!;
    final ext = p.extension(file.name).replaceAll('.', '').toUpperCase();
    final rawTitle = p.basenameWithoutExtension(file.name);

    int size = 0;
    try {
      final f = File(filePath);
      if (f.existsSync()) {
        size = f.lengthSync();
      }
    } catch (_) {
      size = 0;
    }

    final now = DateTime.now();

    return RecentDocument(
      path: filePath,
      fileName: file.name,
      title: rawTitle,
      dateAdded: now,
      lastOpened: now,
      fileSize: size,
      format: ext.isNotEmpty ? ext : 'DOC',
      readingStatus: ReadingStatus.unread,
    );
  }
}
