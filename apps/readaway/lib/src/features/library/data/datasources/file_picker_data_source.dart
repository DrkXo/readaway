import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/models/reader/supported_document_formats.dart';
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
    return RecentDocument(
      path: file.path!,
      fileName: file.name,
      lastOpened: DateTime.now(),
    );
  }
}
