import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart' as css;
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// Shared CSS parsing service.
CssService get cssService => GetIt.I.get<CssService>();

/// Parses CSS declaration blocks (the content of a `style` attribute) into a
/// property → value map.
///
/// This is the single shared entry point for all CSS parsing in the app. It
/// delegates to `package:csslib`'s real tokenizer/parser instead of the
/// fragile `split(';')`/`split(':')` string splitting that used to live in
/// [parseStyles] and `_stripHeight`. Because it returns the same
/// `Map<String, String>` contract, existing consumers are unaffected.
///
/// csslib parses full stylesheets, so a bare declaration block is wrapped in
/// a dummy selector (`x { ... }`) before parsing, then the first ruleset's
/// declarations are extracted. Errors are collected and ignored (best-effort),
/// so malformed CSS degrades to an empty/partial map rather than throwing.
@Singleton()
class CssService {
  /// Parses [style] (a CSS declaration block, e.g. `color: red; font-size: 12pt`)
  /// into a map of lowercased property → trimmed value.
  ///
  /// Returns an empty map for null/empty input or when nothing parses.
  Map<String, String> parseDeclarations(String style) {
    final trimmed = style.trim();
    if (trimmed.isEmpty) return const {};

    final errors = <css.Message>[];
    // Wrap the declaration block in a dummy selector so csslib parses it as a
    // ruleset's declaration group.
    final sheet = css.parse('x { $trimmed }', errors: errors);

    final result = <String, String>{};
    for (final top in sheet.topLevels) {
      if (top is! css.RuleSet) continue;
      for (final node in top.declarationGroup.declarations) {
        if (node is! css.Declaration) continue;
        final value = _serializeValue(node);
        if (value.isEmpty) continue;
        result[node.property.toLowerCase()] = value;
      }
    }
    return result;
  }

  /// Serializes a declaration's expression back to its CSS value string.
  String _serializeValue(css.Declaration declaration) {
    final expression = declaration.expression;
    if (expression == null) return '';
    final printer = css.CssPrinter();
    expression.visit(printer);
    return printer.toString().trim();
  }
}
