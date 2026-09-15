import 'package:html_unescape/html_unescape.dart';

/// Decodes HTML character references (named, decimal, and hexadecimal) in
/// [input] into their Unicode equivalents.
///
/// `package:xml` only decodes the five predefined XML entities (`&amp;`,
/// `&lt;`, `&gt;`, `&quot;`, `&apos;`), so EPUB metadata and TOC labels parsed
/// from OPF/NCX/Nav documents can still contain HTML entities such as
/// `&eacute;`, `&#8217;`, or `&nbsp;`. This helper closes that gap.
String decodeHtmlEntities(String input) {
  if (input.isEmpty) return input;
  return HtmlUnescape().convert(input);
}
