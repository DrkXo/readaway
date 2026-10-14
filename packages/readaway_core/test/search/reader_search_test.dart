import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  test('finds every occurrence across sections in reading order', () async {
    final reader = await PlainTextDocumentReader.fromBytes(
      Uint8List.fromList(
        utf8.encode('First apple appears here.\nSecond apple appears later.\n'),
      ),
      filePath: 'search.txt',
    );
    final search = const ReaderSearchService();

    final results = search.search(reader, 'apple');

    expect(results, isNotEmpty);
    expect(
      results.every((r) => r.snippet.toLowerCase().contains('apple')),
      isTrue,
    );
  });

  test(
    'is case-insensitive and returns an empty list for blank queries',
    () async {
      final reader = await PlainTextDocumentReader.fromBytes(
        Uint8List.fromList(utf8.encode('Nothing interesting here.')),
        filePath: 'search.txt',
      );
      final search = const ReaderSearchService();

      expect(search.search(reader, ''), isEmpty);
      expect(search.search(reader, '   '), isEmpty);
      expect(search.search(reader, 'NOTHING').length, 1);
    },
  );

  test('respects maxResults', () async {
    final reader = await PlainTextDocumentReader.fromBytes(
      Uint8List.fromList(utf8.encode('apple apple apple apple apple')),
      filePath: 'search.txt',
    );
    final search = const ReaderSearchService();

    final results = search.search(reader, 'apple', maxResults: 2);
    expect(results.length, 2);
  });
}
