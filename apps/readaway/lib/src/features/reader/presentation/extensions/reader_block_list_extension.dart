import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/reader/reader_block.dart';
import '../widgets/page/reader_html_widget.dart';

extension ReaderBlockListX on List<ReaderBlock> {
  List<Widget> mapBlocks(PaintContext ctx) {
    final widgets = <Widget>[];
    for (final block in this) {
      final widget = _mapBlock(block, ctx);
      if (widget != null) widgets.add(widget);
    }
    return widgets;
  }
}

extension ReaderBlockX on ReaderBlock {
  Widget? toWidget(PaintContext ctx) => _mapBlock(this, ctx);
}

Widget? _mapBlock(ReaderBlock block, PaintContext ctx) {
  switch (block) {
    case ParagraphBlock(:final spans, :final padded):
      final textAlign = ctx.fullJustification ? TextAlign.justify : null;
      final effectiveSpans = <InlineSpan>[
        if (ctx.textIndent > 0)
          TextSpan(
            text: '\u200B${' ' * ctx.textIndent.round()}',
            style: ctx.baseStyle,
          ),
        for (final s in spans) _mapSpan(s, ctx, ctx.baseStyle),
      ];
      final rich = Text.rich(
        TextSpan(children: effectiveSpans, style: ctx.baseStyle),
        textAlign: textAlign,
      );
      if (!padded) return RepaintBoundary(child: rich);
      return Padding(
        padding: EdgeInsets.symmetric(vertical: ctx.paragraphMargin),
        child: RepaintBoundary(child: rich),
      );
    case LooseTextBlock(:final text):
      return Text(text, style: ctx.baseStyle);
    case HeadingBlock(:final level, :final spans):
      final style = switch (level) {
        1 => ctx.baseStyle.copyWith(
          fontSize: ctx.baseStyle.fontSize! * 1.5,
          fontWeight: FontWeight.bold,
        ),
        2 => ctx.baseStyle.copyWith(
          fontSize: ctx.baseStyle.fontSize! * 1.3,
          fontWeight: FontWeight.bold,
        ),
        3 => ctx.baseStyle.copyWith(
          fontSize: ctx.baseStyle.fontSize! * 1.1,
          fontWeight: FontWeight.bold,
        ),
        _ => ctx.baseStyle.copyWith(fontWeight: FontWeight.bold),
      };
      final mappedSpans = spans.map((s) => _mapSpan(s, ctx, style)).toList();
      return Padding(
        padding: EdgeInsets.only(top: level == 1 ? 24 : 16, bottom: 8),
        child: RepaintBoundary(
          child: Text.rich(TextSpan(children: mappedSpans, style: style)),
        ),
      );
    case SpacerBlock():
      return const SizedBox(height: 16);
    case RuleBlock():
      return const Divider();
    case ImageBlock():
      Widget image;
      if (block.bytes != null) {
        image = Image.memory(block.bytes!, fit: BoxFit.contain);
      } else if (block.file != null) {
        image = Image.file(File(block.file!), fit: BoxFit.contain);
      } else if (block.url != null) {
        image = Image.network(block.url!, fit: BoxFit.contain);
      } else {
        return null;
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RepaintBoundary(child: image),
      );
    case ContainerBlock(:final children):
      final mapped = children.mapBlocks(ctx);
      if (mapped.isEmpty) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: mapped,
      );
    case QuoteBlock(:final children):
      final mapped = children.mapBlocks(ctx);
      if (mapped.isEmpty) return null;
      return Padding(
        padding: const EdgeInsets.only(left: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: ctx.foregroundColor.withValues(alpha: 0.3),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: mapped,
            ),
          ),
        ),
      );
    case ListBlock(:final ordered, :final items):
      final children = <Widget>[];
      var index = 1;
      for (final item in items) {
        final prefix = ordered ? '$index. ' : '\u2022 ';
        index++;
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prefix, style: ctx.baseStyle),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: item.mapBlocks(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (children.isEmpty) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    case TableBlock(:final rows):
      final tableRows = <TableRow>[];
      for (final row in rows) {
        final cells = <Widget>[];
        for (final cell in row.cells) {
          cells.add(
            Padding(
              padding: const EdgeInsets.all(8),
              child: DefaultTextStyle(
                style: ctx.baseStyle.copyWith(
                  fontWeight: cell.isHeader ? FontWeight.bold : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cell.children.mapBlocks(ctx),
                ),
              ),
            ),
          );
        }
        if (cells.isNotEmpty) tableRows.add(TableRow(children: cells));
      }
      if (tableRows.isEmpty) return null;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(
            color: ctx.foregroundColor.withValues(alpha: 0.2),
          ),
          children: tableRows,
        ),
      );
  }
}

InlineSpan _mapSpan(
  ReaderSpan span,
  PaintContext ctx,
  TextStyle parentStyle, {
  GestureRecognizer? inheritedRecognizer,
}) {
  if (span is ReaderInlineImageSpan) {
    Widget? widget;
    if (span.bytes != null) {
      widget = Image.memory(span.bytes!, fit: BoxFit.contain);
    } else if (span.file != null) {
      widget = Image.file(File(span.file!), fit: BoxFit.contain);
    } else if (span.url != null) {
      widget = Image.network(span.url!, fit: BoxFit.contain);
    }
    if (widget == null) return const TextSpan(text: '');
    if (inheritedRecognizer is TapGestureRecognizer &&
        inheritedRecognizer.onTap != null) {
      widget = GestureDetector(
        onTap: inheritedRecognizer.onTap,
        child: widget,
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RepaintBoundary(child: widget),
      ),
    );
  }

  if (span is ReaderTextSpan) {
    var style = parentStyle;

    if (!ctx.overrideFont && span.fontFamily != null) {
      final family = _resolveFontFamily(span.fontFamily!, ctx);
      if (family != null) {
        style = style.copyWith(fontFamily: family);
      }
    }

    if (span.monospace) {
      style = style.copyWith(fontFamily: ctx.monospaceFont);
    }

    if (span.bold) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }

    if (span.italic) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }

    final decorations = <TextDecoration>[];
    if (span.underline || span.linkHref != null) {
      decorations.add(TextDecoration.underline);
    }
    if (span.strikethrough) {
      decorations.add(TextDecoration.lineThrough);
    }
    if (decorations.isNotEmpty) {
      style = style.copyWith(decoration: TextDecoration.combine(decorations));
    }

    if (span.fontSizeRatio != null && span.fontSizeRatio! > 0) {
      final baseSize = ctx.baseStyle.fontSize ?? 18.0;
      final clampedRatio = span.fontSizeRatio!.clamp(0.5, 4.0);
      style = style.copyWith(fontSize: baseSize * clampedRatio);
    }

    if (span.subscript || span.superscript) {
      style = style.copyWith(
        fontSize: (style.fontSize ?? 18.0) * 0.7,
        height: 1,
      );
    }

    GestureRecognizer? recognizer;
    if (span.linkHref != null && ctx.recognizerFor != null) {
      recognizer = ctx.recognizerFor!(span.linkHref!);
    }

    final effectiveRecognizer = recognizer ?? inheritedRecognizer;

    final children = span.children
        .map((c) => _mapSpan(
              c,
              ctx,
              style,
              inheritedRecognizer: effectiveRecognizer,
            ))
        .toList();

    return TextSpan(
      text: span.text.isNotEmpty ? span.text : null,
      style: style,
      recognizer: effectiveRecognizer,
      children: children.isNotEmpty ? children : null,
    );
  }

  return const TextSpan(text: '');
}

String? _resolveFontFamily(String raw, PaintContext ctx) {
  for (final part in raw.split(',')) {
    final name = part.trim().replaceAll(RegExp('^["\']+|["\']+\$'), '');
    if (name.isEmpty) continue;
    switch (name.toLowerCase()) {
      case 'serif':
        return ctx.serifFont;
      case 'sans-serif':
        return ctx.sansSerifFont;
      case 'monospace':
        return ctx.monospaceFont;
      case 'cursive':
      case 'fantasy':
      case 'system-ui':
        continue;
      default:
        return name;
    }
  }
  return null;
}
