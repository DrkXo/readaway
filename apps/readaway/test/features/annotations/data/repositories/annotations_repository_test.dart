import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/services/storage/hive/app_storage_service.dart';
import 'package:readaway/src/core/services/storage/hive/hive_boxes.dart';
import 'package:readaway/src/core/services/storage/hive/hive_config_service.dart';
import 'package:readaway/src/features/annotations/data/datasources/annotations_local_data_source.dart';
import 'package:readaway/src/features/annotations/data/repositories/annotations_repository_impl.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';

import '../../../../helpers/test_mocks.dart';

/// A minimal highlight anchored to characters 10..20 of chapter 3.
ReaderNote _highlight({
  String id = 'note-1',
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime(2026, 1, 1, 12);
  return ReaderNote(
    id: id,
    type: ReaderNoteType.highlight,
    anchor: const ReaderNoteAnchor(
      chapterIndex: 3,
      startChar: 10,
      endChar: 20,
      pageIndex: 5,
      text: 'a passage',
      prefix: 'before ',
      suffix: ' after',
    ),
    style: HighlightStyle.squiggly,
    colorValue: '#FF8800',
    note: 'why it matters',
    createdAt: at,
    updatedAt: at,
  );
}

/// A bookmark on page 7 of a fixed-layout document.
ReaderNote _bookmark({
  String id = 'note-2',
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime(2026, 2, 2, 9, 30);
  return ReaderNote(
    id: id,
    type: ReaderNoteType.bookmark,
    anchor: const ReaderNoteAnchor(
      kind: NoteAnchorKind.page,
      chapterIndex: 7,
      pageIndex: 7,
      text: 'Page 8',
    ),
    createdAt: at,
    updatedAt: at,
  );
}

DocumentNotes _record(List<ReaderNote> notes) => DocumentNotes(
  documentPath: '/books/a.epub',
  schemaVersion: kDocumentNotesSchemaVersion,
  notes: notes,
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late Directory tempDir;
  late AppStorageService storageService;
  late AnnotationsRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('annotations_test_');
    final pathService = MockAppPathService();
    when(pathService.getHiveDirectory()).thenAnswer((_) async => tempDir);

    final hiveBoxes = HiveBoxes();
    storageService = AppStorageService(
      config: HiveConfigService(pathService, hiveBoxes),
      boxes: hiveBoxes,
    );
    await storageService.init();

    repository = AnnotationsRepositoryImpl(
      AnnotationsLocalDataSource(storageService),
    );
  });

  tearDown(() async {
    try {
      await storageService.dispose();
    } catch (_) {}
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('getForDocument', () {
    test('returns an empty record for a document with no notes', () async {
      final result = await repository.getForDocument('/books/a.epub');

      final record = result.dataOrNull;
      expect(record, isNotNull);
      expect(record!.documentPath, '/books/a.epub');
      expect(record.notes, isEmpty);
      expect(record.schemaVersion, kDocumentNotesSchemaVersion);
    });
  });

  group('save', () {
    test('round-trips every field through Hive', () async {
      final saved = await repository.save(_record([_highlight()]));
      expect(saved.isSuccess, isTrue);

      final reloaded = (await repository.getForDocument(
        '/books/a.epub',
      )).dataOrNull!;

      expect(reloaded.notes, hasLength(1));
      final note = reloaded.notes.single;
      expect(note.id, 'note-1');
      expect(note.type, ReaderNoteType.highlight);
      expect(note.style, HighlightStyle.squiggly);
      expect(note.colorValue, '#FF8800');
      expect(note.note, 'why it matters');
      expect(note.createdAt, DateTime(2026, 1, 1, 12));
      expect(note.deletedAt, isNull);

      // The nested anchor survives too — it is the part the reader needs to
      // re-resolve a highlight after a relayout.
      expect(note.anchor.kind, NoteAnchorKind.reflowable);
      expect(note.anchor.chapterIndex, 3);
      expect(note.anchor.startChar, 10);
      expect(note.anchor.endChar, 20);
      expect(note.anchor.pageIndex, 5);
      expect(note.anchor.text, 'a passage');
      expect(note.anchor.prefix, 'before ');
      expect(note.anchor.suffix, ' after');
      expect(note.anchor.orphaned, isFalse);
    });

    test('round-trips a page-anchored bookmark', () async {
      await repository.save(_record([_bookmark()]));

      final note = (await repository.getForDocument(
        '/books/a.epub',
      )).dataOrNull!.notes.single;

      expect(note.type, ReaderNoteType.bookmark);
      expect(note.anchor.kind, NoteAnchorKind.page);
      expect(note.anchor.pageIndex, 7);
      expect(note.isPainted, isFalse);
    });

    test('stamps the schema version and a fresh modified time', () async {
      final stale = DocumentNotes(
        documentPath: '/books/a.epub',
        schemaVersion: 0,
        notes: const [],
        updatedAt: DateTime(2020),
      );

      final saved = (await repository.save(stale)).dataOrNull!;

      expect(saved.schemaVersion, kDocumentNotesSchemaVersion);
      expect(saved.updatedAt.isAfter(DateTime(2020)), isTrue);
      expect(saved.documentPath, '/books/a.epub');
    });

    test('keeps documents isolated from each other', () async {
      await repository.save(_record([_highlight()]));
      await repository.save(
        DocumentNotes(
          documentPath: '/books/b.epub',
          updatedAt: DateTime(2026),
          notes: [_highlight(id: 'other')],
        ),
      );

      final a = (await repository.getForDocument('/books/a.epub')).dataOrNull!;
      final b = (await repository.getForDocument('/books/b.epub')).dataOrNull!;

      expect(a.notes.map((n) => n.id), ['note-1']);
      expect(b.notes.map((n) => n.id), ['other']);
    });
  });

  group('soft delete', () {
    test('a tombstoned note is persisted but excluded from live', () async {
      final note = _highlight();
      await repository.save(
        _record([note.copyWith(deletedAt: DateTime(2026, 3, 1))]),
      );

      final reloaded = (await repository.getForDocument(
        '/books/a.epub',
      )).dataOrNull!;

      // Persisted, so undo can still find it...
      expect(reloaded.notes, hasLength(1));
      expect(reloaded.notes.single.isDeleted, isTrue);
      expect(reloaded.notes.single.deletedAt, DateTime(2026, 3, 1));
      // ...but hidden from every read path.
      expect(reloaded.live, isEmpty);
      expect(reloaded.liveOfType(ReaderNoteType.highlight), isEmpty);
      expect(reloaded.liveInChapter(3), isEmpty);
    });
  });

  group('DocumentNotes filtering', () {
    test('liveOfType and liveInChapter select the right records', () async {
      await repository.save(
        _record([
          _highlight(),
          _bookmark(),
          _highlight(id: 'deleted').copyWith(deletedAt: DateTime(2026, 3, 1)),
        ]),
      );

      final record = (await repository.getForDocument(
        '/books/a.epub',
      )).dataOrNull!;

      expect(
        record.liveOfType(ReaderNoteType.highlight).map((n) => n.id),
        ['note-1'],
      );
      expect(
        record.liveOfType(ReaderNoteType.bookmark).map((n) => n.id),
        ['note-2'],
      );
      expect(record.liveInChapter(3).map((n) => n.id), ['note-1']);
      expect(record.liveInChapter(7).map((n) => n.id), ['note-2']);
      expect(record.liveInChapter(9), isEmpty);
    });
  });

  group('purgeForDocument', () {
    test('removes the record', () async {
      await repository.save(_record([_highlight()]));

      final purged = await repository.purgeForDocument('/books/a.epub');
      expect(purged.isSuccess, isTrue);

      final reloaded = (await repository.getForDocument(
        '/books/a.epub',
      )).dataOrNull!;
      expect(reloaded.notes, isEmpty);
    });

    test('is a no-op for an unknown document', () async {
      final purged = await repository.purgeForDocument('/books/missing.epub');
      expect(purged.isSuccess, isTrue);
    });
  });
}
