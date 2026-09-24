import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway_core/src/readers/comic/comic_archive_adapter.dart';

import '../../helpers/core_test_mocks.dart';

void main() {
  group('ComicArchiveAdapter with Mockito', () {
    late MockComicArchiveAdapter mockAdapter;

    setUp(() {
      mockAdapter = MockComicArchiveAdapter();
    });

    test(
      'mockAdapter lists image entries and fetches page bytes correctly',
      () {
        final dummyPages = ['page_001.jpg', 'page_002.jpg', 'page_003.jpg'];
        final dummyBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

        when(mockAdapter.listImageEntries()).thenReturn(dummyPages);
        when(mockAdapter.loadEntryBytes('page_001.jpg')).thenReturn(dummyBytes);

        expect(mockAdapter.listImageEntries(), equals(dummyPages));
        expect(mockAdapter.loadEntryBytes('page_001.jpg'), equals(dummyBytes));
        expect(mockAdapter.loadEntryBytes('page_unknown.jpg'), isNull);

        verify(mockAdapter.listImageEntries()).called(1);
        verify(mockAdapter.loadEntryBytes('page_001.jpg')).called(1);
      },
    );

    test('mockAdapter loads ComicInfo.xml metadata correctly', () {
      const xml = '<ComicInfo><Title>Test Comic</Title></ComicInfo>';
      when(mockAdapter.loadComicInfoXml()).thenReturn(xml);

      expect(mockAdapter.loadComicInfoXml(), equals(xml));
      verify(mockAdapter.loadComicInfoXml()).called(1);
    });

    test('mockAdapter tracks disposal', () {
      mockAdapter.dispose();
      verify(mockAdapter.dispose()).called(1);
    });

    test('ComicArchiveAdapter static utility helpers', () {
      expect(ComicArchiveAdapter.isImageFile('page_1.png'), isTrue);
      expect(ComicArchiveAdapter.isImageFile('page_1.JPG'), isTrue);
      expect(ComicArchiveAdapter.isImageFile('page_1.webp'), isTrue);
      expect(ComicArchiveAdapter.isImageFile('page_1.txt'), isFalse);
      expect(ComicArchiveAdapter.isImageFile('__MACOSX/._page_1.png'), isFalse);

      expect(
        ComicArchiveAdapter.normalizePath(r'folder\sub\page.jpg'),
        'folder/sub/page.jpg',
      );
      expect(
        ComicArchiveAdapter.compareAlphanumeric('page_2.jpg', 'page_10.jpg'),
        lessThan(0),
      );
    });
  });
}
