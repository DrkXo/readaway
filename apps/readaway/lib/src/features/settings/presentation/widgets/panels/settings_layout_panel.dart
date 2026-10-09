import 'package:flutter/material.dart';

import 'layout/settings_layout_header_footer_section.dart';
import 'layout/settings_layout_margins_section.dart';
import 'layout/settings_layout_paragraph_section.dart';
import 'layout/settings_layout_text_section.dart';

export 'layout/settings_layout_header_footer_section.dart'
    show SettingsLayoutHeaderFooterSection;
export 'layout/settings_layout_margins_section.dart'
    show SettingsLayoutMarginsSection;
export 'layout/settings_layout_paragraph_section.dart'
    show SettingsLayoutParagraphSection;
export 'layout/settings_layout_text_section.dart'
    show SettingsLayoutTextSection;

/// Reader page margins, paragraph, text spacing, header, and footer settings.
class SettingsLayoutPanel extends StatelessWidget {
  const SettingsLayoutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        SettingsLayoutMarginsSection(),
        SizedBox(height: 24),
        SettingsLayoutParagraphSection(),
        SizedBox(height: 24),
        SettingsLayoutTextSection(),
        SizedBox(height: 24),
        SettingsLayoutHeaderFooterSection(),
      ],
    );
  }
}
