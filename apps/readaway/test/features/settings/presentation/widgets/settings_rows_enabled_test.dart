import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';
import 'package:readaway/src/features/settings/presentation/widgets/primitives/settings_slider_row.dart';
import 'package:readaway/src/features/settings/presentation/widgets/primitives/settings_switch_row.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('a disabled slider row is non-interactive', (tester) async {
    await tester.pumpWidget(
      host(
        SettingsSliderRow(
          label: 'Line height',
          value: 1.5,
          min: 0,
          max: 3,
          enabled: false,
          format: (v) => v.toStringAsFixed(2),
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });

  testWidgets('an enabled slider row stays interactive', (tester) async {
    await tester.pumpWidget(
      host(
        SettingsSliderRow(
          label: 'Line height',
          value: 1.5,
          min: 0,
          max: 3,
          format: (v) => v.toStringAsFixed(2),
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNotNull);
  });

  testWidgets('a disabled switch row is non-interactive', (tester) async {
    await tester.pumpWidget(
      host(
        SettingsSwitchRow(
          label: 'Show footer',
          value: true,
          enabled: false,
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('an enabled switch row stays interactive', (tester) async {
    await tester.pumpWidget(
      host(
        SettingsSwitchRow(
          label: 'Show footer',
          value: true,
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
  });

  testWidgets('a disabled select row cannot open its menu', (tester) async {
    await tester.pumpWidget(
      host(
        SettingsSelectRow<String>(
          label: 'Font family',
          value: 'a',
          entries: const [SettingsSelectEntry(value: 'a', label: 'A')],
          enabled: false,
          onChanged: (_) {},
        ),
      ),
    );

    final button = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    expect(button.enabled, isFalse);
  });
}
