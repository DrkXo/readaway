import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart' show OutlineItem;

import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';
import 'tts_bottom_player_controls.dart';
import 'tts_sentence_queue_list.dart';

/// Full Player View with scrollable auto-centering sentence queue,
/// intra-sentence position scrubber, speed controls, and bottom-anchored controls.
class ReaderTtsFullPlayerView extends StatelessWidget {
  const ReaderTtsFullPlayerView({
    required this.onClose,
    required this.onClosePlayer,
    this.onDragUpdate,
    this.onDragEnd,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onClosePlayer;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  String? _resolveChapterTitle(List<OutlineItem>? outline, int? targetPage) {
    if (outline == null || outline.isEmpty || targetPage == null) return null;
    OutlineItem? match;
    for (final root in outline) {
      for (final item in root.flatten()) {
        final idx = item.chapterIndex;
        if (idx != null && idx >= 0 && idx <= targetPage) {
          match = item;
        }
      }
    }
    return match?.title.trim();
  }

  @override
  Widget build(BuildContext context) {
    final tts = context.read<ReaderBloc>().ttsRepository;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // 1. Top Drag Handle & Title Bar
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onDragUpdate,
            onVerticalDragEnd: onDragEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: LucideIcons.chevronDown,
                        tooltip: 'Minimize',
                        onPressed: onClose,
                        size: AppIconButtonSize.medium,
                      ),
                      Expanded(
                        child: BlocBuilder<ReaderBloc, ReaderState>(
                          buildWhen: (prev, curr) =>
                              prev.ttsCurrentPage != curr.ttsCurrentPage ||
                              prev.pageCount != curr.pageCount ||
                              prev.currentPage != curr.currentPage ||
                              prev.outline != curr.outline ||
                              prev.bookTitle != curr.bookTitle,
                          builder: (context, state) {
                            final ttsPage = state.ttsCurrentPage;
                            final canJump = state.canJumpToTtsPage;
                            final effectivePage = ttsPage ?? state.currentPage;
                            final chapterTitle = _resolveChapterTitle(
                              state.outline,
                              effectivePage,
                            );
                            final pageLabel = ttsPage != null
                                ? 'Page ${ttsPage + 1} of ${state.pageCount}'
                                : (state.pageCount > 0
                                    ? '${state.pageCount} pages'
                                    : 'Sentences');

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (chapterTitle != null &&
                                    chapterTitle.isNotEmpty) ...[
                                  AppText(
                                    chapterTitle,
                                    variant: AppTextVariant.title,
                                    textAlign: TextAlign.center,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        pageLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                      ),
                                      if (canJump) ...[
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            context.read<ReaderBloc>().add(
                                              const ReaderEvent.jumpToTtsPage(),
                                            );
                                          },
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.arrowRight,
                                                  size: 11,
                                                  color: scheme.primary,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Jump to page',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: scheme.primary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 11,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ] else ...[
                                  AppText(
                                    state.bookTitle ?? pageLabel,
                                    variant: AppTextVariant.title,
                                    textAlign: TextAlign.center,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (state.bookTitle != null) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      pageLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                  if (canJump) ...[
                                    const SizedBox(height: 2),
                                    InkWell(
                                      onTap: () {
                                        context.read<ReaderBloc>().add(
                                          const ReaderEvent.jumpToTtsPage(),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              LucideIcons.arrowRight,
                                              size: 12,
                                              color: scheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Jump to this page',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: scheme.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      AppIconButton(
                        icon: LucideIcons.x,
                        tooltip: 'Close Player',
                        onPressed: onClosePlayer,
                        size: AppIconButtonSize.medium,
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // 2. Scrollable Auto-Tracking Sentence Queue
          Expanded(
            child: TtsSentenceQueueList(tts: tts),
          ),

          // 3. Anchored Bottom Media Controls Section
          TtsBottomPlayerControls(
            tts: tts,
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
          ),
        ],
      ),
    );
  }
}
