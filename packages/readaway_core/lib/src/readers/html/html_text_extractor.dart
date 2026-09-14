import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../abstracts/reflowable_document_reader.dart';

/// Extracts plain text from document HTML for reading display, analysis, and natural TTS playback.
class HtmlTextExtractor {
  const HtmlTextExtractor._();

  static const Set<String> _ignoredTags = {
    'script',
    'style',
    'noscript',
    'head',
    'svg',
    'canvas',
  };

  static const Set<String> _blockTags = {
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

  static final RegExp _citationAnchorPattern = RegExp(
    r'^[\[\(]?[\*\d]+[\)\]]?$',
  );

  static final RegExp _kanaPattern = RegExp(
    r'[\u3040-\u309f\u30a0-\u30ff]',
  );

  /// Extracts plain text from [html], returning an empty string when [html]
  /// is empty or has no body.
  ///
  /// Set [forSpeech] or [filterFootnotes] to true to strip footnote bodies and
  /// citation numbers (`[1]`, `*`, `(2)`) from the output.
  /// Set [swapRubyForSpeech] to true to pronounce Japanese `<rt>` kana readings
  /// in place of kanji ideographs while muting glosses.
  static String extractPageText(
    String html, {
    bool forSpeech = false,
    bool filterFootnotes = false,
    bool swapRubyForSpeech = false,
  }) {
    if (html.isEmpty) return '';
    final doc = html_parser.parse(html);
    final body = doc.body;
    if (body == null) return '';

    final shouldFilterFootnotes = forSpeech || filterFootnotes;
    final shouldSwapRuby = forSpeech || swapRubyForSpeech;

    final blocks = <String>[];
    final visited = <dom.Element>{};

    void processNode(dom.Node node) {
      if (node is dom.Element) {
        final tag = node.localName?.toLowerCase() ?? '';
        if (_ignoredTags.contains(tag)) return;

        // Skip footnote blocks when filtering for speech or natural reading
        if (shouldFilterFootnotes && _isFootnoteElement(node)) {
          return;
        }

        // Skip footnote citation anchor links (e.g. [1], *, (2))
        if (shouldFilterFootnotes && tag == 'a') {
          final linkText = node.text.trim();
          if (_citationAnchorPattern.hasMatch(linkText)) {
            return;
          }
        }

        if (_blockTags.contains(tag)) {
          final text = _extractElementText(
            node,
            shouldSwapRuby: shouldSwapRuby,
            shouldFilterFootnotes: shouldFilterFootnotes,
          ).trim();

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
          if (_blockTags.contains(childTag) ||
              childTag == 'div' ||
              childTag == 'article' ||
              childTag == 'section') {
            hasBlockChildren = true;
            break;
          }
        }

        if (tag == 'div' && !hasBlockChildren) {
          final text = _extractElementText(
            node,
            shouldSwapRuby: shouldSwapRuby,
            shouldFilterFootnotes: shouldFilterFootnotes,
          ).trim();

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

  /// Extracts text specifically conditioned for TTS narration:
  /// mutes base kanji in favor of kana `<rt>` readings, strips citation numbers
  /// (`[1]`, `*`), and isolates footnote content.
  static String extractSpeechText(String html) => extractPageText(
        html,
        forSpeech: true,
        filterFootnotes: true,
        swapRubyForSpeech: true,
      );

  static bool _isFootnoteElement(dom.Element el) {
    if (el.classes.contains('epubtype-footnote') ||
        el.classes.contains('duokan-footnote-content') ||
        el.classes.contains('duokan-footnote-item') ||
        el.attributes.containsKey('data-wr-footernote') ||
        el.attributes.containsKey('zy-footnote')) {
      return true;
    }

    final epubType = el.attributes['epub:type']?.toLowerCase() ?? '';
    if (epubType.contains('footnote') ||
        epubType.contains('endnote') ||
        epubType.contains('note') ||
        epubType.contains('rearnote')) {
      return true;
    }

    return false;
  }

  static String _extractElementText(
    dom.Element element, {
    required bool shouldSwapRuby,
    required bool shouldFilterFootnotes,
  }) {
    final buffer = StringBuffer();

    void walk(dom.Node n) {
      if (n is dom.Element) {
        final tag = n.localName?.toLowerCase() ?? '';
        if (_ignoredTags.contains(tag)) return;

        if (shouldFilterFootnotes && _isFootnoteElement(n)) return;
        if (shouldFilterFootnotes && tag == 'a') {
          if (_citationAnchorPattern.hasMatch(n.text.trim())) return;
        }

        // Handle Ruby typesetting for speech
        if (tag == 'ruby') {
          if (shouldSwapRuby) {
            final rt = n.querySelector('rt');
            final rtText = rt?.text.trim() ?? '';
            // If <rt> contains Kana letters, it is a Japanese pronunciation reading:
            // voice the <rt> reading and mute the base ideograph.
            if (_kanaPattern.hasMatch(rtText)) {
              buffer.write(rtText);
              return;
            }
          }

          // Default ruby behavior: speak base text, skip <rt> and <rp>
          for (final child in n.nodes) {
            final childTag = (child is dom.Element) ? child.localName?.toLowerCase() : null;
            if (childTag == 'rt' || childTag == 'rp' || childTag == 'rtc') {
              continue;
            }
            walk(child);
          }
          return;
        }

        for (final child in n.nodes) {
          walk(child);
        }
      } else if (n is dom.Text) {
        buffer.write(n.text);
      }
    }

    walk(element);
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }
}

/// Convenience text-extraction API for reflowable documents.
extension ReflowableSectionText on ReflowableDocumentReader {
  /// Extracts plain text from the section at [index] (for display and analysis).
  String extractSectionText(int index) =>
      HtmlTextExtractor.extractPageText(loadSectionHtml(index));

  /// Extracts speech-conditioned plain text from the section at [index] (for TTS playback).
  String extractSectionSpeechText(int index) =>
      HtmlTextExtractor.extractSpeechText(loadSectionHtml(index));
}
