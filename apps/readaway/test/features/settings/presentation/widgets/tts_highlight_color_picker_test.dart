import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/settings/presentation/widgets/tts_highlight_color_picker.dart';

void main() {
  Widget host({
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) => MaterialApp(
    home: Scaffold(
      body: TtsHighlightColorPicker(
        selectedValue: selectedValue,
        onSelected: onSelected,
      ),
    ),
  );

  testWidgets('reports the tapped preset key', (tester) async {
    String? selected;
    await tester.pumpWidget(
      host(selectedValue: 'primary', onSelected: (v) => selected = v),
    );

    await tester.tap(find.text('Amber'));
    await tester.pumpAndSettle();

    expect(selected, 'amber');
  });

  testWidgets('a custom hex is normalised before being reported', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(selectedValue: 'primary', onSelected: (v) => selected = v),
    );

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Custom highlight color'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '#0ea5e9');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(selected, '#0EA5E9');
    expect(find.text('Custom highlight color'), findsNothing);
  });

  testWidgets('an invalid hex blocks Apply and keeps the dialog open', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(selectedValue: 'primary', onSelected: (v) => selected = v),
    );

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nope');
    await tester.pump();

    final apply = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Apply'),
    );
    expect(apply.onPressed, isNull);
    expect(find.text('Custom highlight color'), findsOneWidget);
    expect(selected, isNull);
  });

  testWidgets('the custom chip is selected for a stored hex value', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(selectedValue: '#123456', onSelected: (_) => taps++),
    );

    // The chip reads "Custom" and shows the stored swatch color.
    expect(find.text('Custom'), findsOneWidget);
    expect(find.byIcon(Icons.colorize), findsNothing);
  });
}
