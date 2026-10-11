import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';

enum _TestOption { first, second, third }

void main() {
  Widget buildThemed(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          VsCodeThemeExtension(
            MetroColorScheme.kanagawaDragon.toVsCodeTheme(),
          ),
        ],
      ),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('MetroPivotControl', () {
    testWidgets(
      'renders all items and calls onChanged when tapping another item',
      (
        tester,
      ) async {
        _TestOption selected = _TestOption.first;

        await tester.pumpWidget(
          buildThemed(
            StatefulBuilder(
              builder: (context, setState) {
                return MetroPivotControl<_TestOption>(
                  value: selected,
                  onChanged: (newVal) => setState(() => selected = newVal),
                  items: const [
                    MetroPivotControlItem(
                      value: _TestOption.first,
                      label: 'first',
                    ),
                    MetroPivotControlItem(
                      value: _TestOption.second,
                      label: 'second',
                    ),
                    MetroPivotControlItem(
                      value: _TestOption.third,
                      label: 'third',
                    ),
                  ],
                );
              },
            ),
          ),
        );

        expect(find.text('first'), findsOneWidget);
        expect(find.text('second'), findsOneWidget);
        expect(find.text('third'), findsOneWidget);

        await tester.tap(find.text('second'));
        await tester.pumpAndSettle();

        expect(selected, _TestOption.second);
      },
    );

    testWidgets('does not call onChanged when tapping already selected item', (
      tester,
    ) async {
      var callCount = 0;

      await tester.pumpWidget(
        buildThemed(
          MetroPivotControl<_TestOption>(
            value: _TestOption.first,
            onChanged: (_) => callCount++,
            items: const [
              MetroPivotControlItem(
                value: _TestOption.first,
                label: 'first',
              ),
              MetroPivotControlItem(
                value: _TestOption.second,
                label: 'second',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('first'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets(
      'renders flatTiles style correctly and supports expanded layout',
      (
        tester,
      ) async {
        _TestOption selected = _TestOption.first;

        await tester.pumpWidget(
          buildThemed(
            StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 300,
                  child: MetroPivotControl<_TestOption>(
                    value: selected,
                    style: MetroPivotControlStyle.flatTiles,
                    size: MetroPivotControlSize.compact,
                    expanded: true,
                    onChanged: (newVal) => setState(() => selected = newVal),
                    items: const [
                      MetroPivotControlItem(
                        value: _TestOption.first,
                        label: 'first',
                        icon: LucideIcons.star,
                      ),
                      MetroPivotControlItem(
                        value: _TestOption.second,
                        label: 'second',
                        count: '42',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text('first'), findsOneWidget);
        expect(find.text('second'), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
        expect(find.byIcon(LucideIcons.star), findsOneWidget);

        await tester.tap(find.text('second'));
        await tester.pumpAndSettle();

        expect(selected, _TestOption.second);
      },
    );

    testWidgets('does not respond to taps when enabled is false', (
      tester,
    ) async {
      var changed = false;

      await tester.pumpWidget(
        buildThemed(
          MetroPivotControl<_TestOption>(
            value: _TestOption.first,
            enabled: false,
            onChanged: (_) => changed = true,
            items: const [
              MetroPivotControlItem(
                value: _TestOption.first,
                label: 'first',
              ),
              MetroPivotControlItem(
                value: _TestOption.second,
                label: 'second',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('second'));
      await tester.pumpAndSettle();

      expect(changed, isFalse);
    });
  });

  group('AppSegmentedControl backward compatibility', () {
    testWidgets('renders and handles selection via MetroPivotControl', (
      tester,
    ) async {
      String selected = 'a';

      await tester.pumpWidget(
        buildThemed(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSegmentedControl<String>(
                value: selected,
                onChanged: (val) => setState(() => selected = val),
                segments: const [
                  AppSegment(value: 'a', label: 'Option A'),
                  AppSegment(value: 'b', label: 'Option B'),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('option a'), findsOneWidget);
      expect(find.text('option b'), findsOneWidget);

      await tester.tap(find.text('option b'));
      await tester.pumpAndSettle();

      expect(selected, 'b');
    });
  });
}
