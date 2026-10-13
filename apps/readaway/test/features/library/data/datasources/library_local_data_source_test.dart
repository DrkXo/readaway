import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/storage/drift/app_database.dart';
import 'package:readaway/src/core/services/storage/drift/daos/documents_dao.dart';
import 'package:readaway/src/core/services/storage/drift/daos/reader_preferences_dao.dart';
import 'package:readaway/src/features/library/data/datasources/library_local_data_source.dart';
import 'package:readaway/src/features/library/domain/entity/reading_status.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late AppDatabase db;
  late LibraryLocalDataSource dataSource;
  late ReaderPreferencesDao readerPreferences;

  setUp(() {
    db = openTestDatabase();
    readerPreferences = ReaderPreferencesDao(db);
    dataSource = LibraryLocalDataSource(
      DocumentsDao(db),
      readerPreferences,
    );
  });

  tearDown(() => db.close());

  group('LibraryLocalDataSource (drift)', () {
    test('lists documents most recently opened first', () async {
      await dataSource.saveRecentDocument(
        fakeRecentDocument(
          path: '/books/older.epub',
          lastOpened: DateTime(2025, 1),
        ),
      );
      await dataSource.saveRecentDocument(
        fakeRecentDocument(
          path: '/books/newer.epub',
          lastOpened: DateTime(2025, 6),
        ),
      );
      await dataSource.saveRecentDocument(
        fakeRecentDocument(
          path: '/books/oldest.epub',
          lastOpened: DateTime(2024),
        ),
      );

      final docs = await dataSource.getRecentDocuments();

      expect(docs.map((d) => d.path), [
        '/books/newer.epub',
        '/books/older.epub',
        '/books/oldest.epub',
      ]);
    });

    test('round-trips tags, status, favorite and cover path', () async {
      final doc = fakeRecentDocument(
        tags: const ['fiction', 'scifi'],
        readingStatus: ReadingStatus.reading,
        isFavorite: true,
        coverPath: '/covers/test_book.jpg',
      );

      await dataSource.saveRecentDocument(doc);

      final saved = (await dataSource.getRecentDocuments()).single;
      expect(saved.path, doc.path);
      expect(saved.tags, containsAll(const ['fiction', 'scifi']));
      expect(saved.readingStatus, ReadingStatus.reading);
      expect(saved.isFavorite, isTrue);
      expect(saved.coverPath, '/covers/test_book.jpg');
    });

    test('save replaces a document, including its tags', () async {
      await dataSource.saveRecentDocument(
        fakeRecentDocument(tags: const ['first']),
      );
      await dataSource.saveRecentDocument(
        fakeRecentDocument(tags: const ['second', 'third']),
      );

      final docs = await dataSource.getRecentDocuments();
      expect(docs, hasLength(1));
      expect(docs.single.tags, containsAll(const ['second', 'third']));
    });

    test('documents without tags round-trip', () async {
      await dataSource.saveRecentDocument(fakeRecentDocument(tags: const []));

      final docs = await dataSource.getRecentDocuments();
      expect(docs.single.tags, isEmpty);
    });

    test('watch emits the current library then updates', () async {
      final expectation = expectLater(
        dataSource.watchRecentDocuments(),
        emitsInOrder(<dynamic>[
          isEmpty,
          isNotEmpty,
        ]),
      );

      // The initial emission lands asynchronously; wait for it before
      // writing so the ordering of events is deterministic.
      await pumpEventQueue();

      await dataSource.saveRecentDocument(
        fakeRecentDocument(path: '/books/new.epub'),
      );

      await expectation;
    });

    test('saveAllDocuments persists the whole batch', () async {
      await dataSource.saveAllDocuments([
        fakeRecentDocument(
          path: '/books/a.epub',
          lastOpened: DateTime(2025, 1),
        ),
        fakeRecentDocument(
          path: '/books/b.epub',
          lastOpened: DateTime(2025, 2),
        ),
      ]);

      final docs = await dataSource.getRecentDocuments();
      expect(docs, hasLength(2));
    });

    test(
      'removing a document clears its legacy path preferences only',
      () async {
        await dataSource.saveRecentDocument(
          fakeRecentDocument(path: '/books/gone.epub'),
        );

        await db
            .into(db.readerPreferenceEntries)
            .insert(
              ReaderPreferenceEntry(
                scope: ReaderPreferencesDao.readerScope,
                ownerKind: 'path',
                ownerKey: '/books/gone.epub',
                payload: const ReaderPreferences(fontSize: 24),
                updatedAt: DateTime(2025),
              ),
            );
        await db
            .into(db.readerPreferenceEntries)
            .insert(
              ReaderPreferenceEntry(
                scope: ReaderPreferencesDao.readerScope,
                ownerKind: 'content',
                ownerKey: 'sha256_deadbeef',
                payload: const ReaderPreferences(fontSize: 28),
                updatedAt: DateTime(2025),
              ),
            );

        await dataSource.removeRecentDocument('/books/gone.epub');

        expect(await dataSource.getRecentDocuments(), isEmpty);
        final remaining = await db.select(db.readerPreferenceEntries).get();
        expect(remaining, hasLength(1));
        expect(remaining.single.ownerKey, 'sha256_deadbeef');
      },
    );

    test(
      'removing multiple documents clears their rows and preferences',
      () async {
        await dataSource.saveAllDocuments([
          fakeRecentDocument(path: '/books/one.epub'),
          fakeRecentDocument(path: '/books/two.epub'),
          fakeRecentDocument(path: '/books/stay.epub'),
        ]);
        await db
            .into(db.readerPreferenceEntries)
            .insert(
              ReaderPreferenceEntry(
                scope: ReaderPreferencesDao.readerScope,
                ownerKind: 'path',
                ownerKey: '/books/two.epub',
                payload: const ReaderPreferences(fontSize: 20),
                updatedAt: DateTime(2025),
              ),
            );

        await dataSource.removeMultipleDocuments([
          '/books/one.epub',
          '/books/two.epub',
        ]);

        final docs = await dataSource.getRecentDocuments();
        expect(docs.map((d) => d.path), ['/books/stay.epub']);
        final prefs = await db.select(db.readerPreferenceEntries).get();
        expect(prefs, isEmpty);
      },
    );
  });
}
