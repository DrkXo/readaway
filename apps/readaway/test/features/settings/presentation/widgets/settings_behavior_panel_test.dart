import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway/src/features/settings/presentation/bloc/settings/settings_bloc.dart';
import 'package:readaway/src/features/settings/presentation/widgets/panels/settings_behavior_panel.dart';
import 'package:readaway/src/features/settings/presentation/widgets/reader_prefs_scope.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = MockSettingsBloc();
    whenListen(
      settingsBloc,
      const Stream<SettingsState>.empty(),
      initialState: const SettingsState(
        appSettings: Settings(),
        globalReaderPrefs: ReaderPreferences(),
      ),
    );
  });

  Widget host() => MaterialApp(
    theme: ThemeData(
      extensions: [
        VsCodeThemeExtension(MetroColorScheme.kanagawaDragon.toVsCodeTheme()),
      ],
    ),
    home: BlocProvider<SettingsBloc>.value(
      value: settingsBloc,
      child: const ReaderPrefsScope(
        documentPath: null,
        child: Scaffold(body: SettingsBehaviorPanel()),
      ),
    ),
  );

  testWidgets('no longer offers hardware-button page turning', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Sanity: the panel rendered its sections.
    expect(find.text('REFLOWABLE BOOKS (EPUB, TXT)'), findsOneWidget);

    // The hardware-button (volume key) navigation setting and its section are
    // gone.
    expect(find.text('Volume keys to flip pages'), findsNothing);
    expect(find.text('NAVIGATION'), findsNothing);
  });
}
