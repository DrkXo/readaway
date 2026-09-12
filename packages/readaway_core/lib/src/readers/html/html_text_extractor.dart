import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../abstracts/reflowable_document_reader.dart';

/// Extracts plain text from document HTML for TTS playback and text analysis.
///
/// Traverses all semantic text-bearing block elements (headings, paragraphs,
/// blockquotes, lists, and leaf divs), joining them with newlines to preserve
/// natural speech phrasing.
class HtmlTextExtractor {
  const HtmlTextExtractor._();

  /// Extracts plain text from [html], returning an empty string when [html]
  /// is empty or has no body.
  static String extractPageText(String html) {
    if (html.isEmpty) return '';
    final doc = html_parser.parse(html);
    final body = doc.body;
    if (body == null) return '';

    final blocks = <String>[];
    final visited = <dom.Element>{};

    void processNode(dom.Node node) {
      if (node is dom.Element) {
        final tag = node.localName?.toLowerCase();
        if (tag == 'script' ||
            tag == 'style' ||
            tag == 'noscript' ||
            tag == 'head') {
          return;
        }

        const blockTags = {
          'h1',
          'h2',
          'h3',
          'h4',
          'h5',
          'h6',
          'p',
          'blockquote',
          'li',
          'dt',
          'dd',
          'pre',
        };

        if (blockTags.contains(tag)) {
          final text = node.text.trim();
          if (text.isNotEmpty && !visited.contains(node)) {
            blocks.add(text);
            visited.add(node);
          }
          return;
        }

        // Check if container element has block children
        bool hasBlockChildren = false;
        for (final child in node.children) {
          final childTag = child.localName?.toLowerCase();
          if (blockTags.contains(childTag) ||
              childTag == 'div' ||
              childTag == 'article' ||
              childTag == 'section') {
            hasBlockChildren = true;
            break;
          }
        }

        if (tag == 'div' && !hasBlockChildren) {
          final text = node.text.trim();
          if (text.isNotEmpty && !visited.contains(node)) {
            blocks.add(text);
            visited.add(node);
          }
          return;
        }

        for (final child in node.nodes) {
          processNode(child);
        }
      } else if (node is dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          blocks.add(text);
        }
      }
    }

    processNode(body);
    return blocks.join('\n');
  }
}

/// Convenience text-extraction API for reflowable documents.
///
/// Lets callers obtain a section's plain text without manually chaining
/// [ReflowableDocumentReader.loadSectionHtml] and
/// [HtmlTextExtractor.extractPageText].
extension ReflowableSectionText on ReflowableDocumentReader {
  /// Extracts plain text from the section at [index] (for TTS and analysis).
  String extractSectionText(int index) =>
      HtmlTextExtractor.extractPageText(loadSectionHtml(index));
}
