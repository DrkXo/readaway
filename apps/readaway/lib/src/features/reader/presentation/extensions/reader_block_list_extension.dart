import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/models/reader/reader_block.dart';
import '../widgets/widgets.dart';

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
        ...spans,
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
      return Padding(
        padding: EdgeInsets.only(top: level == 1 ? 24 : 16, bottom: 8),
        child: RepaintBoundary(
          child: Text.rich(TextSpan(children: spans, style: style)),
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
