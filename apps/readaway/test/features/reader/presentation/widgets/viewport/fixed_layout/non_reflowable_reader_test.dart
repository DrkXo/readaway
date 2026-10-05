import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/dialogs/reader_password_dialog.dart';
import 'package:readaway/src/features/reader/presentation/widgets/navigation/reader_bottom_bar.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/fixed_layout/fixed_layout_image_cache.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../../helpers/test_mocks.dart';

class MockReaderBloc extends MockBloc<ReaderEvent, ReaderState>
    implements ReaderBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  group('FixedLayoutImageCache Tests', () {
    late MockReaderRepository repo;
    late FixedLayoutImageCache cache;

    setUp(() {
      repo = MockReaderRepository();
      // Page images are byte-budgeted, not count-bounded. The 4-byte pages
      // below fit the budget easily, so this instance's eviction is driven by
      // the 3-entry ceiling; the weight-bound behaviour gets its own test
      // further down.
      cache = FixedLayoutImageCache(
        budgetBytes: 1024,
        maxEntries: 3,
      );
    });

    test('caches and returns page image bytes and dimensions', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);
      when(repo.loadPageImage(0, scale: anyNamed('scale')))
          .thenAnswer((_) async => Success(dummyBytes));
      when(repo.getPageSize(0)).thenAnswer(
        (_) async => const Success(PageSize(width: 800.0, height: 1200.0)),
      );

      final bytes1 = await cache.getOrLoadImage(repo, '/test.pdf', 0);
      final size1 = await cache.getOrLoadSize(repo, '/test.pdf', 0);

      expect(bytes1, equals(dummyBytes));
      expect(size1, equals(const PageSize(width: 800.0, height: 1200.0)));

      // Second fetch should return cached data without repository invocation
      final bytes2 = await cache.getOrLoadImage(repo, '/test.pdf', 0);
      expect(bytes2, equals(dummyBytes));
      verify(repo.loadPageImage(0, scale: anyNamed('scale'))).called(1);
    });

    test('evicts oldest entry when exceeding maxEntries', () async {
      when(repo.loadPageImage(any, scale: anyNamed('scale'))).thenAnswer(
        (i) async =>
            Success(Uint8List.fromList([i.positionalArguments[0] as int])),
      );

      await cache.getOrLoadImage(repo, '/test.pdf', 0);
      await cache.getOrLoadImage(repo, '/test.pdf', 1);
      await cache.getOrLoadImage(repo, '/test.pdf', 2);
      await cache.getOrLoadImage(repo, '/test.pdf', 3); // Evicts page 0

      // Requesting page 0 again should hit repository a second time
      await cache.getOrLoadImage(repo, '/test.pdf', 0);
      verify(repo.loadPageImage(0, scale: anyNamed('scale'))).called(2);
    });

    test('clears document cache cleanly', () async {
      when(repo.loadPageImage(any, scale: anyNamed('scale')))
          .thenAnswer((_) async => Success(Uint8List.fromList([1, 2])));

      await cache.getOrLoadImage(repo, '/doc1.cbz', 0); // Call 1
      await cache.getOrLoadImage(repo, '/doc2.cbz', 0); // Call 2

      cache.clear('/doc1.cbz');

      await cache.getOrLoadImage(repo, '/doc1.cbz', 0); // Call 3 (re-fetched)
      await cache.getOrLoadImage(
        repo,
        '/doc2.cbz',
        0,
      ); // Reused from cache (no extra call)

      verify(repo.loadPageImage(any, scale: anyNamed('scale'))).called(3);
    });

    test('evicts by byte weight once the budget is exceeded', () async {
      // 4 x 8-byte pages = 32 bytes, so the fourth write overflows a 24-byte
      // budget and page 0 must be dropped even though it is only the 4th entry
      // — the count ceiling is far above.
      final weighted = FixedLayoutImageCache(
        budgetBytes: 24,
        maxEntries: 100,
      );
      when(repo.loadPageImage(any, scale: anyNamed('scale'))).thenAnswer(
        (_) async => Success(Uint8List(8)),
      );

      await weighted.getOrLoadImage(repo, '/test.pdf', 0);
      await weighted.getOrLoadImage(repo, '/test.pdf', 1);
      await weighted.getOrLoadImage(repo, '/test.pdf', 2);
      expect(weighted.getCachedImage('/test.pdf', 0), isNotNull);

      await weighted.getOrLoadImage(repo, '/test.pdf', 3); // evicts page 0

      expect(weighted.getCachedImage('/test.pdf', 0), isNull);
      expect(weighted.getCachedImage('/test.pdf', 1), isNotNull);
      expect(weighted.getCachedImage('/test.pdf', 2), isNotNull);
      expect(weighted.getCachedImage('/test.pdf', 3), isNotNull);
    });

    test('refuses to cache a page larger than the whole budget', () async {
      // cacherine silently declines to store an entry whose own weight exceeds
      // maxWeight. A single oversized page must therefore not be cached at
      // all — and must not wipe out the pages that already fit.
      final tiny = FixedLayoutImageCache(budgetBytes: 16, maxEntries: 100);
      when(repo.loadPageImage(0, scale: anyNamed('scale'))).thenAnswer(
        (_) async => Success(Uint8List(8)),
      );
      when(repo.loadPageImage(1, scale: anyNamed('scale'))).thenAnswer(
        (_) async => Success(Uint8List(64)),
      );

      await tiny.getOrLoadImage(repo, '/test.pdf', 0);
      await tiny.getOrLoadImage(repo, '/test.pdf', 1); // 64 > 16, rejected

      expect(tiny.getCachedImage('/test.pdf', 0), isNotNull);
      expect(tiny.getCachedImage('/test.pdf', 1), isNull);
    });

    test('configureBudget clamps to the fixed minimum', () {
      final cache = FixedLayoutImageCache();
      expect(
        cache.budgetBytes,
        kDefaultReaderCacheBytes,
        reason: 'constructor takes the budget verbatim',
      );

      cache.configureBudget(1);
      expect(
        cache.budgetBytes,
        kMinReaderCacheBytes,
        reason: 'a 1-byte pick must not be able to starve the reader',
      );

      cache.configureBudget(64 * 1024 * 1024);
      expect(
        cache.budgetBytes,
        64 * 1024 * 1024,
        reason: 'a pick above the floor is honoured as-is',
      );

      cache.configureBudget(2);
      expect(
        cache.budgetBytes,
        kMinReaderCacheBytes,
        reason: 'clamping back down to the floor is still a change',
      );
    });

    test(
      'configureBudget discards pages cached under the old budget',
      () async {
        when(repo.loadPageImage(any, scale: anyNamed('scale'))).thenAnswer(
          (_) async => Success(Uint8List(8)),
        );

        final reconfigurable = FixedLayoutImageCache(
          budgetBytes: 1024 * 1024,
          maxEntries: 100,
        );
        await reconfigurable.getOrLoadImage(repo, '/test.pdf', 0);
        expect(reconfigurable.getCachedImage('/test.pdf', 0), isNotNull);

        reconfigurable.configureBudget(32 * 1024 * 1024);
        expect(reconfigurable.getCachedImage('/test.pdf', 0), isNull);
      },
    );
  });

  group('ReaderPasswordDialog Widget Tests', () {
    testWidgets('renders dialog and submits entered password', (tester) async {
      String? submittedPassword;
      var cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              VsCodeThemeExtension(BuiltinVsCodeThemes.kanagawaDragon),
            ],
          ),
          home: Scaffold(
            body: ReaderPasswordDialog(
              fileName: 'secret.pdf',
              isInvalidPassword: false,
              onUnlock: (pwd) => submittedPassword = pwd,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Password Protected'), findsOneWidget);
      expect(find.text('secret.pdf'), findsOneWidget);
      expect(find.text('Incorrect password. Please try again.'), findsNothing);

      // Enter password and tap unlock
      await tester.enterText(find.byType(TextField), 'my_secret_123');
      await tester.tap(find.text('Unlock'));
      await tester.pump();

      expect(submittedPassword, equals('my_secret_123'));
      expect(cancelled, isFalse);
    });

    testWidgets('displays error message when isInvalidPassword is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              VsCodeThemeExtension(BuiltinVsCodeThemes.kanagawaDragon),
            ],
          ),
          home: Scaffold(
            body: ReaderPasswordDialog(
              fileName: 'secret.pdf',
              isInvalidPassword: true,
              onUnlock: (_) {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Incorrect password. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('ReaderBottomBar Format Adaptation Tests', () {
    testWidgets('shows all 5 action buttons for reflowable documents', (
      tester,
    ) async {
      final mockBloc = MockReaderBloc();
      whenListen(
        mockBloc,
        const Stream<ReaderState>.empty(),
        initialState: const ReaderState(
          documentPath: '/book.epub',
          isReflowable: true,
          pageCount: 10,
          currentPage: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              VsCodeThemeExtension(BuiltinVsCodeThemes.kanagawaDragon),
            ],
          ),
          home: BlocProvider<ReaderBloc>.value(
            value: mockBloc,
            child: Scaffold(
              bottomNavigationBar: ReaderBottomBar(
                onPreviousPage: () {},
                onNextPage: () {},
                onSeekToPage: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 5 icons: outline, brightness, pageNav, font size, TTS
      expect(find.byIcon(LucideIcons.panelLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.sunMedium), findsOneWidget);
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
      expect(find.byIcon(LucideIcons.type), findsOneWidget);
      expect(find.byIcon(LucideIcons.audioLines), findsOneWidget);
    });

    testWidgets(
      'hides font size and TTS buttons for non-reflowable documents',
      (tester) async {
        final mockBloc = MockReaderBloc();
        whenListen(
          mockBloc,
          const Stream<ReaderState>.empty(),
          initialState: const ReaderState(
            documentPath: '/comic.cbz',
            isReflowable: false,
            format: 'cbz',
            pageCount: 20,
            currentPage: 0,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: [
                VsCodeThemeExtension(BuiltinVsCodeThemes.kanagawaDragon),
              ],
            ),
            home: BlocProvider<ReaderBloc>.value(
              value: mockBloc,
              child: Scaffold(
                bottomNavigationBar: ReaderBottomBar(
                  onPreviousPage: () {},
                  onNextPage: () {},
                  onSeekToPage: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Only 3 icons: outline, brightness, pageNav
        expect(find.byIcon(LucideIcons.panelLeft), findsOneWidget);
        expect(find.byIcon(LucideIcons.sunMedium), findsOneWidget);
        expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
        expect(find.byIcon(LucideIcons.type), findsNothing);
        expect(find.byIcon(LucideIcons.audioLines), findsNothing);
      },
    );
  });
}
