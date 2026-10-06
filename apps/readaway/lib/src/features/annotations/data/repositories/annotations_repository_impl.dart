import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/document_notes.dart';
import '../../domain/repositories/annotations_repository.dart';
import '../datasources/annotations_local_data_source.dart';

/// Persists each document's bookmarks, highlights and notes through
/// [AnnotationsLocalDataSource].
@LazySingleton(as: AnnotationsRepository)
class AnnotationsRepositoryImpl implements AnnotationsRepository {
  final AnnotationsLocalDataSource _local;

  AnnotationsRepositoryImpl(this._local);

  @override
  Future<Result<DocumentNotes>> getForDocument(String documentPath) {
    return guard(
      () async => _local.read(documentPath) ?? _blankFor(documentPath),
      onError: (error, stack) => StorageReadFailure(
        _keyFor(documentPath),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<DocumentNotes>> save(DocumentNotes document) {
    // Stamping lives here rather than at the call sites so a schema bump or a
    // clock change is applied in exactly one place.
    final stamped = document.copyWith(
      schemaVersion: kDocumentNotesSchemaVersion,
      updatedAt: DateTime.now(),
    );
    return guard(
      () async {
        await _local.write(stamped);
        return stamped;
      },
      onError: (error, stack) => StorageWriteFailure(
        _keyFor(document.documentPath),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> purgeForDocument(String documentPath) {
    return guard(
      () async {
        await _local.remove(documentPath);
      },
      onError: (error, stack) => StorageWriteFailure(
        _keyFor(documentPath),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  /// A record for a document that has never been annotated.
  DocumentNotes _blankFor(String documentPath) => DocumentNotes(
    documentPath: documentPath,
    schemaVersion: kDocumentNotesSchemaVersion,
    updatedAt: DateTime.now(),
  );

  String _keyFor(String documentPath) => 'annotations:$documentPath';
}
