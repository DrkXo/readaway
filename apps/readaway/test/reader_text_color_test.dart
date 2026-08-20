import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_page_content.dart';

void main() {
  Future<TextStyle> rootStyleOf(WidgetTester tester, String html) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        colorScheme: AppColors.dark.scheme,
        extensions: [AppColors.dark],
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => ReaderPageContent.htmlWidget(html, context),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(HtmlWidget),
        matching: find.byType(RichText).first,
      ),
    );
    return (richText.text as TextSpan).style!;
  }

  testWidgets('author colors are ignored, themed color wins', (tester) async {
    final cases = [
      '<p>plain</p>',
      '<p><font color="#000000">font</font></p>',
      '<p><span style="color:#000">inline</span></p>',
    ];
    for (final html in cases) {
      final style = await rootStyleOf(tester, html);
      expect(style.color, AppColors.dark.readerForeground, reason: html);
    }
  });

  testWidgets('links keep theme primary color', (tester) async {
    final style = await rootStyleOf(tester, '<p><a href="x">link</a></p>');
    expect(style.color, AppColors.dark.scheme.primary);
  });
}
