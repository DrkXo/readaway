import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/page_content/html/hyper_page_content.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/page_content/html/reflowable_image_cache.dart';

final Uint8List _png1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4'
  '2mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  final cache = ReflowableImageCache.instance;

  setUp(cache.clear);
  tearDown(cache.clear);

  test('resolveBytes dedupes concurrent loads and caches the result', () async {
    var loadCount = 0;
    Future<Uint8List?> load() async {
      loadCount++;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      return Uint8List.fromList([1, 2, 3]);
    }

    final first = cache.resolveBytes('doc', 0, 'img/a.jpg', load: load);
    final second = cache.resolveBytes('doc', 0, 'img/a.jpg', load: load);

    expect(await first, [1, 2, 3]);
    expect(await second, [1, 2, 3]);
    expect(loadCount, 1);

    // Already cached — a third resolve never touches the loader.
    expect(await cache.resolveBytes('doc', 0, 'img/a.jpg', load: load), [1, 2, 3]);
    expect(loadCount, 1);
  });

  test('namespace + chapterIndex isolate cached bytes between documents', () async {
    final called = <String>[];
    Future<Uint8List?> loadFor(String ns) async {
      called.add(ns);
      return Uint8List.fromList(ns.codeUnits);
    }

    await cache.resolveBytes(
      'bookA',
      1,
      'images/cover.jpg',
      load: () => loadFor('A'),
    );
    await cache.resolveBytes(
      'bookB',
      1,
      'images/cover.jpg',
      load: () => loadFor('B'),
    );
    await cache.resolveBytes(
      'bookA',
      2,
      'images/cover.jpg',
      load: () => loadFor('A2'),
    );

    expect(called, ['A', 'B', 'A2']);
    expect(cache.peekBytes('bookA', 1, 'images/cover.jpg'), isNotNull);
    expect(cache.peekBytes('bookB', 1, 'images/cover.jpg'), isNotNull);
  });

  test('decode decodes once and reuses the same ui.Image frame', () async {
    var loadCount = 0;
    Future<ui.Image?> decode() => cache.decode(
      'doc',
      0,
      'img/a.png',
      load: () async {
        loadCount++;
        return Uint8List.fromList(_png1x1);
      },
    );

    final first = await decode();
    final second = await decode();

    expect(loadCount, 1);
    expect(first, isNotNull);
    expect(identical(first, second), isTrue);
    expect(
      identical(cache.peekDecoded('doc', 0, 'img/a.png'), first),
      isTrue,
    );
  });

  test('seedImageDimensions stamps real dims on undecorated img nodes', () async {
    await cache.decode('doc', 0, 'img/a.png', load: () async => Uint8List.fromList(_png1x1));
    final document = DocumentNode(children: [
      AtomicNode.img(src: 'img/a.png'),
      AtomicNode.img(src: 'img/unknown.png'),
    ]);

    HyperPageContent.seedImageDimensions(
      document,
      cacheNamespace: 'doc',
      chapterIndex: 0,
    );

    final known = document.children[0] as AtomicNode;
    expect(known.style.width, 1.0);
    expect(known.style.height, 1.0);

    // Unknown image: cache miss — dims stay null so the engine uses its
    // placeholder until the async decode lands.
    final unknown = document.children[1] as AtomicNode;
    expect(unknown.style.width, isNull);
    expect(unknown.style.height, isNull);
  });

  test('seedImageDimensions leaves authored CSS dimensions untouched', () async {
    await cache.decode('doc', 0, 'img/a.png', load: () async => Uint8List.fromList(_png1x1));
    final styled = AtomicNode.img(src: 'img/a.png')
      ..style.width = 480.0
      ..style.height = 640.0;
    final document = DocumentNode(children: [styled]);

    HyperPageContent.seedImageDimensions(
      document,
      cacheNamespace: 'doc',
      chapterIndex: 0,
    );

    expect(styled.style.width, 480.0);
    expect(styled.style.height, 640.0);
  });

  test('seedImageDimensions fills the implicit auto dimension from aspect', () async {
    // 1×1 PNG is square; use a distinct payload via a non-square picture.
    await cache.decode('doc', 0, 'img/a.png', load: () async => Uint8List.fromList(_png1x1));
    final widthOnly = AtomicNode.img(src: 'img/a.png')..style.width = 100.0;
    final heightOnly = AtomicNode.img(src: 'img/a.png')..style.height = 50.0;
    final document = DocumentNode(children: [widthOnly, heightOnly]);

    HyperPageContent.seedImageDimensions(
      document,
      cacheNamespace: 'doc',
      chapterIndex: 0,
    );

    expect(widthOnly.style.width, 100.0);
    expect(widthOnly.style.height, 100.0);
    expect(heightOnly.style.width, 50.0);
    expect(heightOnly.style.height, 50.0);
  });
}