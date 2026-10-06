import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/toc/reader_toc_content.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../helpers/test_mocks.dart';

class MockReaderBloc extends MockBloc<ReaderEvent, ReaderState>
    implements ReaderBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  const outline = <OutlineItem>[
    OutlineItem(
      title: 'Volume 1',
      level: 0,
      chapterIndex: 0,
      children: <OutlineItem>[
        OutlineItem(title: 'Chapter 1', chapterIndex: 0),
        OutlineItem(title: 'Chapter 2', chapterIndex: 10),
      ],
    ),
    OutlineItem(title: 'Epilogue', level: 0, chapterIndex: 20),
  ];

  Future<void> pumpToc(
    WidgetTester tester, {
    void Function(int page)? onJumpToPage,
  }) async {
    final bloc = MockReaderBloc();
    whenListen(
      bloc,
      const Stream<ReaderState>.empty(),
      initialState: const ReaderState(
        outline: outline,
        bookTitle: 'Test Book',
        currentPage: 0,
        pageCount: 30,
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
          value: bloc,
          child: Scaffold(
            body: ReaderTocContent(onJumpToPage: onJumpToPage ?? (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder searchField() => find.byKey(const ValueKey('toc-search-field'));

  testWidgets('renders a search field when the document has a TOC', (
    tester,
  ) async {
    await pumpToc(tester);
    expect(searchField(), findsOneWidget);
    // The current chapter's ancestor chain is force-expanded on open, while
    // the unrelated volume stays collapsed.
    expect(find.text('Volume 1'), findsOneWidget);
    expect(find.text('Chapter 1'), findsOneWidget);
    expect(find.text('Chapter 3'), findsNothing);
  });

  testWidgets('search field keeps a comfortable touch height', (tester) async {
    await pumpToc(tester);
    expect(
      tester.getSize(searchField()).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('typing filters the outline to matches and their ancestors', (
    tester,
  ) async {
    await pumpToc(tester);
    await tester.enterText(searchField(), 'chapter 2');
    await tester.pump();

    expect(find.text('Volume 1'), findsOneWidget);
    expect(find.text('Chapter 2'), findsOneWidget);
    expect(find.text('Chapter 1'), findsNothing);
    expect(find.text('Epilogue'), findsNothing);
  });

  testWidgets('a query with no match shows an empty state that clears', (
    tester,
  ) async {
    await pumpToc(tester);
    await tester.enterText(searchField(), 'zzz');
    await tester.pump();

    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pump();

    expect(find.text('No matches'), findsNothing);
    expect(find.text('Volume 1'), findsOneWidget);
    expect(find.text('Epilogue'), findsOneWidget);
  });

  testWidgets('tapping a matched leaf jumps to its chapter', (tester) async {
    int? jumped;
    await pumpToc(tester, onJumpToPage: (page) => jumped = page);
    await tester.enterText(searchField(), 'epilogue');
    await tester.pump();

    await tester.tap(find.text('Epilogue'));
    await tester.pump();

    expect(jumped, 20);
  });
}
