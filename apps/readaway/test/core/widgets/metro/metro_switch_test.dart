import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';

void main() {
  Widget buildThemed(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          VsCodeThemeExtension(BuiltinVsCodeThemes.kanagawaDragon),
        ],
      ),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('MetroSwitch', () {
    testWidgets('renders off state and toggles to on on tap', (tester) async {
      var switchValue = false;

      await tester.pumpWidget(
        buildThemed(
          StatefulBuilder(
            builder: (context, setState) {
              return MetroSwitch(
                value: switchValue,
                onChanged: (val) => setState(() => switchValue = val),
              );
            },
          ),
        ),
      );

      expect(find.byType(MetroSwitch), findsOneWidget);
      expect(switchValue, isFalse);

      await tester.tap(find.byType(MetroSwitch));
      await tester.pumpAndSettle();

      expect(switchValue, isTrue);

      await tester.tap(find.byType(MetroSwitch));
      await tester.pumpAndSettle();

      expect(switchValue, isFalse);
    });

    testWidgets('does not toggle when enabled is false or onChanged is null', (
      tester,
    ) async {
      var callCount = 0;

      await tester.pumpWidget(
        buildThemed(
          MetroSwitch(
            value: false,
            enabled: false,
            onChanged: (_) => callCount++,
          ),
        ),
      );

      await tester.tap(find.byType(MetroSwitch));
      await tester.pumpAndSettle();

      expect(callCount, 0);

      // Verify null onChanged
      await tester.pumpWidget(
        buildThemed(
          const MetroSwitch(
            value: true,
            onChanged: null,
          ),
        ),
      );

      await tester.tap(find.byType(MetroSwitch));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets('renders state label when showStateLabel is true', (
      tester,
    ) async {
      var switchValue = false;

      await tester.pumpWidget(
        buildThemed(
          StatefulBuilder(
            builder: (context, setState) {
              return MetroSwitch(
                value: switchValue,
                showStateLabel: true,
                onLabel: 'active',
                offLabel: 'inactive',
                onChanged: (val) => setState(() => switchValue = val),
              );
            },
          ),
        ),
      );

      expect(find.text('inactive'), findsOneWidget);
      expect(find.text('active'), findsNothing);

      await tester.tap(find.byType(MetroSwitch));
      await tester.pumpAndSettle();

      expect(find.text('active'), findsOneWidget);
      expect(find.text('inactive'), findsNothing);
    });

    testWidgets(
      'renders compact size and custom colors without layout errors',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          buildThemed(
            MetroSwitch(
              value: true,
              size: MetroSwitchSize.compact,
              activeColor: Colors.teal,
              inactiveColor: Colors.grey,
              onChanged: (_) {},
            ),
          ),
        );

        expect(find.byType(MetroSwitch), findsOneWidget);
      },
    );
  });
}
