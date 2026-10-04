import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/settings/presentation/widgets/scoped_settings_section.dart';

void main() {
  Widget wrap({
    required String bookPath,
    required bool scoped,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SettingsScopeControl(
          bookPath: bookPath,
          scoped: scoped,
          onScopedChanged: onChanged,
          child: child,
        ),
      ),
    );
  }

  testWidgets('renders no scope affordances when opened globally', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScopedSettingsSection(
            title: 'Typeface',
            rows: [SizedBox()],
          ),
        ),
      ),
    );

    expect(find.byType(Switch), findsNothing);
    expect(find.text('All books'), findsNothing);
    expect(find.text('This book'), findsNothing);
  });

  testWidgets('global-only groups show an "All books" chip without a switch', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        bookPath: '/book.epub',
        scoped: false,
        onChanged: (_) {},
        child: const ScopedSettingsSection(
          scopable: false,
          title: 'TTS',
          rows: [SizedBox()],
        ),
      ),
    );

    expect(find.text('All books'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets(
    'scopable groups display dynamic scope chip without per-section switch',
    (tester) async {
      var scoped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SettingsScopeControl(
                  bookPath: '/book.epub',
                  scoped: scoped,
                  onScopedChanged: (value) => setState(() => scoped = value),
                  child: const ScopedSettingsSection(
                    title: 'Typeface',
                    rows: [SizedBox()],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // When global fallback is active:
      expect(find.text('All books'), findsOneWidget);
      expect(find.text('This book'), findsNothing);
      expect(find.byType(Switch), findsNothing);

      // When scoped to book:
      scoped = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SettingsScopeControl(
                  bookPath: '/book.epub',
                  scoped: scoped,
                  onScopedChanged: (value) => setState(() => scoped = value),
                  child: const ScopedSettingsSection(
                    title: 'Typeface',
                    rows: [SizedBox()],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('This book'), findsOneWidget);
      expect(find.text('All books'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    },
  );

  testWidgets(
    'long section title with chip does not overflow narrow viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrap(
          bookPath: '/book.epub',
          scoped: true,
          onChanged: (_) {},
          child: const ScopedSettingsSection(
            title: 'Fixed layout & documents (PDF, CBZ, CBR)',
            rows: [SizedBox()],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('This book'), findsOneWidget);
    },
  );
}
