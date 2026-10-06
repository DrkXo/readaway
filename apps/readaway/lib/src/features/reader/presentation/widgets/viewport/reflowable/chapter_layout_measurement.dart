import 'package:flutter/rendering.dart';
import 'package:hyper_render/hyper_render.dart' show RenderHyperBox;
import 'package:readaway_core/readaway_core.dart';

import 'chapter_text_layout_builder.dart';

/// Finds the [RenderHyperBox] that owns a chapter's laid-out geometry.
///
/// Returns null when the subtree has not produced one, which is the case while
/// the chapter's content is still loading or when it carries no text.
RenderHyperBox? findChapterHyperBox(RenderObject? root) {
  if (root == null) return null;
  if (root is RenderHyperBox) return root;

  RenderHyperBox? found;
  root.visitChildren((child) {
    found ??= findChapterHyperBox(child);
  });
  return found;
}

/// Registers the measured geometry of the chapter rendered under [root].
///
/// Shared by the visible page and the offscreen probe so a chapter's page count
/// cannot depend on which of the two measured it. [root] must be the render
/// object of the chapter's full, unsliced content: the slice transform on a
/// visible page does not change intrinsic height, but passing a clipped slice
/// would.
void registerChapterLayoutFromRenderObject({
  required PaginationCoordinator coordinator,
  required int chapterIndex,
  required RenderObject? root,
}) {
  if (root is! RenderBox || !root.hasSize) return;

  final contentHeight = root.size.height;
  if (contentHeight <= 0.0) return;

  final hyperBox = findChapterHyperBox(root);
  if (hyperBox == null) {
    coordinator.registerChapterHeight(
      chapterIndex: chapterIndex,
      contentHeight: contentHeight,
    );
    return;
  }

  final layout = const ChapterTextLayoutBuilder().build(
    hyperBox: hyperBox,
    contentHeight: contentHeight,
    viewportHeight: coordinator.currentState.viewportHeight,
  );
  coordinator.registerChapterLayout(chapterIndex: chapterIndex, layout: layout);
}
