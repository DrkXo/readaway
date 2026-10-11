import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway/src/features/settings/presentation/bloc/settings/settings_bloc.dart';
import 'package:readaway/src/features/settings/presentation/bloc/tts_library/tts_library_bloc.dart';
import 'package:readaway/src/features/settings/presentation/pages/settings_page.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockTtsLibraryBloc extends MockBloc<TtsLibraryEvent, TtsLibraryState>
    implements TtsLibraryBloc {}

void main() {
  late MockSettingsBloc settingsBloc;
  late MockTtsLibraryBloc ttsLibraryBloc;

  setUp(() {
    settingsBloc = MockSettingsBloc();
    ttsLibraryBloc = MockTtsLibraryBloc();

    whenListen(
      settingsBloc,
      const Stream<SettingsState>.empty(),
      initialState: const SettingsState(
        appSettings: Settings(),
        globalReaderPrefs: ReaderPreferences(),
      ),
    );

    whenListen(
      ttsLibraryBloc,
      const Stream<TtsLibraryState>.empty(),
      initialState: const TtsLibraryState(),
    );
  });

  Widget buildThemed({required Widget child}) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          VsCodeThemeExtension(
            MetroColorScheme.kanagawaDragon.toVsCodeTheme(),
          ),
        ],
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<TtsLibraryBloc>.value(value: ttsLibraryBloc),
        ],
        child: child,
      ),
    );
  }

  group('SettingsPage with MetroPivot', () {
    testWidgets('renders MetroPivot with settings title and 5 category tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          child: const SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MetroPivot), findsOneWidget);
      expect(find.text('settings'), findsOneWidget);
      expect(find.text('font'), findsOneWidget);
      expect(find.text('layout'), findsOneWidget);
      expect(find.text('behavior'), findsOneWidget);
      expect(find.text('appearance'), findsOneWidget);
      expect(find.text('tts'), findsOneWidget);
      expect(find.text('close'), findsOneWidget);
    });

    testWidgets('starts with initialTab when specified', (tester) async {
      await tester.pumpWidget(
        buildThemed(
          child: const SettingsPage(initialTab: SettingsTab.layout),
        ),
      );
      await tester.pumpAndSettle();

      final pivot = tester.widget<MetroPivot>(find.byType(MetroPivot));
      expect(pivot.controller?.index, SettingsTab.layout.index);
    });

    testWidgets('tapping a pivot tab updates active section', (tester) async {
      await tester.pumpWidget(
        buildThemed(
          child: const SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      final pivot = tester.widget<MetroPivot>(find.byType(MetroPivot));
      expect(pivot.controller?.index, SettingsTab.font.index);

      await tester.tap(find.text('layout'));
      await tester.pumpAndSettle();

      expect(pivot.controller?.index, SettingsTab.layout.index);
    });

    testWidgets('renders per-book banner when documentPath is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          child: const SettingsPage(documentPath: '/books/sample.epub'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('customize this book'), findsOneWidget);
    });
  });
}
