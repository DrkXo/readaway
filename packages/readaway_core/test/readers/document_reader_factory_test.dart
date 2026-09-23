import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway_core/src/errors/document_exception.dart';
import 'package:readaway_core/src/readers/document_reader_factory.dart';

import '../helpers/core_test_mocks.dart';

void main() {
  group('DocumentReaderFactory with Mockito', () {
    late DocumentReaderFactory factory;
    late MockDocumentFormatHandler mockHandler;
    late MockDocumentReader mockReader;

    setUp(() {
      factory = DocumentReaderFactory();
      mockHandler = MockDocumentFormatHandler();
      mockReader = MockDocumentReader();

      when(mockHandler.format).thenReturn('custom_doc');
    });

    test('registers custom handler and delegates open when supports returns true', () async {
      when(mockHandler.supports('sample.custom_doc', null)).thenReturn(true);
      when(mockHandler.open('sample.custom_doc', password: anyNamed('password')))
          .thenAnswer((_) async => mockReader);

      factory.register(mockHandler);

      expect(factory.handlers.contains(mockHandler), isTrue);

      final reader = await factory.open('sample.custom_doc');

      expect(reader, equals(mockReader));
      verify(mockHandler.supports('sample.custom_doc', null)).called(1);
      verify(mockHandler.open('sample.custom_doc', password: null)).called(1);
    });

    test('passes password correctly to custom handler', () async {
      when(mockHandler.supports('secure.custom_doc', null)).thenReturn(true);
      when(mockHandler.open('secure.custom_doc', password: 'secret_password'))
          .thenAnswer((_) async => mockReader);

      factory.register(mockHandler);

      final reader = await factory.open('secure.custom_doc', password: 'secret_password');

      expect(reader, equals(mockReader));
      verify(mockHandler.open('secure.custom_doc', password: 'secret_password')).called(1);
    });

    test('unregisters handler correctly', () async {
      factory.register(mockHandler);
      expect(factory.handlers.contains(mockHandler), isTrue);

      factory.unregister('custom_doc');
      expect(factory.handlers.contains(mockHandler), isFalse);

      expect(
        () => factory.open('sample.custom_doc'),
        throwsA(isA<UnsupportedFormatException>()),
      );
    });

    test('sniffs magic bytes when bytes parameter is passed', () async {
      final magicBytes = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
      when(mockHandler.supports('unknown_extension', magicBytes)).thenReturn(true);
      when(mockHandler.open('unknown_extension', password: null))
          .thenAnswer((_) async => mockReader);

      factory.register(mockHandler);

      final reader = await factory.open('unknown_extension', bytes: magicBytes);

      expect(reader, equals(mockReader));
      verify(mockHandler.supports('unknown_extension', magicBytes)).called(1);
    });
  });
}
