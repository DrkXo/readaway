import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/storage/drift/app_database.dart';
import 'package:readaway/src/core/services/storage/drift/daos/reader_preferences_dao.dart';
import 'package:readaway/src/features/reader/data/repositories/reader_preferences_repository_impl.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_preferences.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late AppDatabase db;
  late ReaderPreferencesDao dao;
  late ReaderPreferencesRepositoryImpl repository;
  late Directory tempDir;

  setUp(() async {
    db = openTestDatabase();
    dao = ReaderPreferencesDao(db);
    repository = ReaderPreferencesRepositoryImpl(dao);
    tempDir = await Directory.systemTemp.createTemp('reader_prefs_test_');
  });

  tearDown(() async {
    db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ReaderPreferencesRepositoryImpl (drift)', () {
    test('persists global and per-book preferences', () async {
      const prefs = ReaderPreferences(fontSize: 22.0);
      final saveResult = await repository.saveGlobalPreferences(prefs);
      expect(saveResult.isSuccess, isTrue);

      final readResult = await repository.getGlobalPreferences();
      expect(readResult.dataOrNull?.fontSize, 22.0);

      const docPrefs = ReaderPreferences(fontSize: 28.0);
      await repository.saveDocumentPreferences('/path/to/book.epub', docPrefs);

      final docResult = await repository.getDocumentPreferences(
        '/path/to/book.epub',
      );
      expect(docResult.dataOrNull?.fontSize, 28.0);

      // Global row plus the legacy path-keyed fallback row (the file does not
      // exist, so content hashing is skipped).
      final rows = await db.select(db.readerPreferenceEntries).get();
      expect(
        rows.where((r) => r.scope == ReaderPreferencesDao.globalScope),
        hasLength(1),
      );
      final bookRows = rows.where((r) => r.ownerKey == '/path/to/book.epub');
      expect(bookRows, hasLength(1));
      expect(bookRows.single.payload.fontSize, 28.0);
    });

    test('stays isolated per book and clears to fallback', () async {
      const globalPrefs = ReaderPreferences(fontSize: 18);
      const firstBookPrefs = ReaderPreferences(fontSize: 24);
      const secondBookPrefs = ReaderPreferences(fontSize: 30);

      await repository.saveGlobalPreferences(globalPrefs);
      await repository.saveDocumentPreferences(
        '/books/first.epub',
        firstBookPrefs,
      );
      await repository.saveDocumentPreferences(
        '/books/second.epub',
        secondBookPrefs,
      );

      expect(
        (await repository.getDocumentPreferences('/books/first.epub'))
            .dataOrNull,
        firstBookPrefs,
      );
      expect(
        (await repository.getDocumentPreferences('/books/second.epub'))
            .dataOrNull,
        secondBookPrefs,
      );
      expect(
        (await repository.getDocumentPreferences('/books/missing.epub'))
            .dataOrNull,
        isNull,
      );

      await repository.clearDocumentPreferences('/books/first.epub');

      expect(
        (await repository.getDocumentPreferences('/books/first.epub'))
            .dataOrNull,
        isNull,
      );
      expect(
        (await repository.getDocumentPreferences('/books/second.epub'))
            .dataOrNull,
        secondBookPrefs,
      );
      expect((await repository.getGlobalPreferences()).dataOrNull, globalPrefs);
    });

    test('follows identical content at a new path', () async {
      final first = File('${tempDir.path}/first.epub');
      final renamed = File('${tempDir.path}/renamed.epub');
      await first.writeAsString('same book bytes');
      await renamed.writeAsString('same book bytes');
      const prefs = ReaderPreferences(fontSize: 25);

      await repository.saveDocumentPreferences(first.path, prefs);

      expect(
        (await repository.getDocumentPreferences(renamed.path)).dataOrNull,
        prefs,
      );
      final rows = await db.select(db.readerPreferenceEntries).get();
      expect(
        rows.any(
          (r) =>
              r.ownerKind == 'content' &&
              r.ownerKey == '${sha256.convert(utf8.encode('same book bytes'))}',
        ),
        isTrue,
      );
    });

    test('changed document content does not reuse the old override', () async {
      final file = File('${tempDir.path}/changed.epub');
      await file.writeAsString('original content');
      await repository.saveDocumentPreferences(
        file.path,
        const ReaderPreferences(fontSize: 25),
      );

      await file.writeAsString('changed content with a different size');

      expect(
        (await repository.getDocumentPreferences(file.path)).dataOrNull,
        isNull,
      );
    });
  });
}
