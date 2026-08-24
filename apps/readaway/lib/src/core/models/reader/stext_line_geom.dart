import 'package:html/dom.dart' as dom;

import '../../utils/reader/reader_html_utils.dart';

/// Geometry of one stext line, parsed from its `<p style>` attribute.
class StextLineGeom {
  const StextLineGeom(this.top, this.left, this.lineH);

  final double top;
  final double left;
  final double lineH;

  static StextLineGeom? from(dom.Element p) {
    final styles = parseStyles(p);
    final top = parseCssPt(styles['top']);
    final left = parseCssPt(styles['left']);
    final lineH = parseCssPt(styles['line-height']);
    if (top == null || left == null || lineH == null || lineH <= 0) return null;
    return StextLineGeom(top, left, lineH);
  }
}
