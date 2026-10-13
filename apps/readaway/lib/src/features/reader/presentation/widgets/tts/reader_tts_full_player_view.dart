import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart' show OutlineItem;

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../bloc/reader_bloc.dart';
import '../../bloc/tts/reader_tts_bloc.dart';
import 'tts_bottom_player_controls.dart';
import 'tts_lyric_view.dart';

/// Full Player View with a page-timed lyric view, intra-sentence position
/// scrubber, speed controls, and bottom-anchored controls.
///
/// Stateful only to hold the lyric view's own shape — see [_singleLine]. The
/// overlay builds this widget once and keeps it mounted behind the expand and
/// collapse animations, so the choice a reader makes survives folding the player
/// away and opening it again, rather than resetting on the next gesture.
class ReaderTtsFullPlayerView extends StatefulWidget {
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

  @override
  State<ReaderTtsFullPlayerView> createState() =>
      _ReaderTtsFullPlayerViewState();
}

class _ReaderTtsFullPlayerViewState extends State<ReaderTtsFullPlayerView> {
  /// Whether the lyric view shows the whole page or only the current sentence.
  ///
  /// Deliberately not a saved preference. Which of the two a reader wants
  /// depends on what they are doing with the player — following along with the
  /// text in front of them, or listening with the book set down — and a
  /// preference would make them choose once and then live with it. It also
  /// belongs to this player rather than to the book or the app: nothing outside
  /// this screen shows a sentence list, so there is nothing for a saved value to
  /// be right about anywhere else.
  bool _singleLine = false;

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
    final tts = context.read<ReaderTtsBloc>().ttsRepository;
    final appColors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // 1. Top Drag Handle & Title Bar
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: widget.onDragUpdate,
            onVerticalDragEnd: widget.onDragEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: appColors.panelBorder,
                      borderRadius: BorderRadius.zero,
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
                      Tooltip(
                        message: 'Minimize',
                        child: Semantics(
                          label: 'Minimize',
                          button: true,
                          child: MetroPressable(
                            onTap: widget.onClose,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                LucideIcons.chevronDown,
                                size: 20,
                                color: appColors.topbarForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<ReaderBloc, ReaderState>(
                          buildWhen: (prev, curr) =>
                              prev.pageCount != curr.pageCount ||
                              prev.currentPage != curr.currentPage ||
                              prev.currentVirtualPage !=
                                  curr.currentVirtualPage ||
                              prev.outline != curr.outline ||
                              prev.bookTitle != curr.bookTitle,
                          builder: (context, readerState) {
                            return BlocBuilder<ReaderTtsBloc, ReaderTtsState>(
                              buildWhen: (prev, curr) =>
                                  prev.ttsActive != curr.ttsActive ||
                                  prev.ttsCurrentPage != curr.ttsCurrentPage ||
                                  prev.ttsTargetVirtualPage !=
                                      curr.ttsTargetVirtualPage,
                              builder: (context, ttsState) {
                                final ttsPage = ttsState.ttsCurrentPage;
                                final canJump = ttsState.canJumpToTtsPage(
                                  currentPage: readerState.currentPage,
                                  currentVirtualPage:
                                      readerState.currentVirtualPage,
                                );
                                final effectivePage =
                                    ttsPage ?? readerState.currentPage;
                                final chapterTitle = _resolveChapterTitle(
                                  readerState.outline,
                                  effectivePage,
                                );
                                final pageLabel = ttsPage != null
                                    ? 'page ${ttsPage + 1} of ${readerState.pageCount}'
                                    : (readerState.pageCount > 0
                                          ? '${readerState.pageCount} pages'
                                          : 'sentences');

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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            pageLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                  fontSize: 11,
                                                ),
                                          ),
                                          if (canJump) ...[
                                            const SizedBox(width: 8),
                                            MetroPressable(
                                              onTap: () {
                                                final chapter =
                                                    ttsState.ttsCurrentPage;
                                                if (chapter != null) {
                                                  context.read<ReaderBloc>().add(
                                                    ReaderEvent.jumpToChapter(
                                                      chapterIndex: chapter,
                                                      virtualPage: ttsState
                                                          .ttsTargetVirtualPage,
                                                    ),
                                                  );
                                                  context.read<ReaderTtsBloc>().add(
                                                    const ReaderTtsEvent.clearFollowTarget(),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: appColors
                                                        .buttonBackground,
                                                    width: 1.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      LucideIcons.arrowRight,
                                                      size: 11,
                                                      color: appColors
                                                          .buttonBackground,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'jump to page',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: appColors
                                                                .buttonBackground,
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
                                        readerState.bookTitle ?? pageLabel,
                                        variant: AppTextVariant.title,
                                        textAlign: TextAlign.center,
                                        fontWeight: FontWeight.bold,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (readerState.bookTitle != null) ...[
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
                                        MetroPressable(
                                          onTap: () {
                                            final chapter =
                                                ttsState.ttsCurrentPage;
                                            if (chapter != null) {
                                              context.read<ReaderBloc>().add(
                                                ReaderEvent.jumpToChapter(
                                                  chapterIndex: chapter,
                                                  virtualPage: ttsState
                                                      .ttsTargetVirtualPage,
                                                ),
                                              );
                                              context.read<ReaderTtsBloc>().add(
                                                const ReaderTtsEvent.clearFollowTarget(),
                                              );
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color:
                                                    appColors.buttonBackground,
                                                width: 1.0,
                                              ),
                                              borderRadius: BorderRadius.zero,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.arrowRight,
                                                  size: 11,
                                                  color: appColors
                                                      .buttonBackground,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'jump to this page',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: appColors
                                                            .buttonBackground,
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
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Sits with the view it changes rather than in the
                      // control shelf below, which is entirely about the voice
                      // and the playback position.
                      Tooltip(
                        message: _singleLine
                            ? 'Show the whole page'
                            : 'Show only the current sentence',
                        child: Semantics(
                          label: _singleLine
                              ? 'Show the whole page'
                              : 'Show only the current sentence',
                          button: true,
                          child: MetroPressable(
                            onTap: () =>
                                setState(() => _singleLine = !_singleLine),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                _singleLine
                                    ? LucideIcons.list
                                    : LucideIcons.alignCenterVertical,
                                size: 20,
                                color: appColors.topbarForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Close Player',
                        child: Semantics(
                          label: 'Close Player',
                          button: true,
                          child: MetroPressable(
                            onTap: widget.onClosePlayer,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                LucideIcons.x,
                                size: 20,
                                color: appColors.topbarForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: appColors.panelBorder,
                ),
              ],
            ),
          ),

          // 2. Page-timed lyric view
          Expanded(
            child: BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (prev, curr) =>
                  prev.appSettings.globalViewSettings.ttsLyricStyle !=
                  curr.appSettings.globalViewSettings.ttsLyricStyle,
              builder: (context, state) => TtsLyricView(
                tts: tts,
                style: state.appSettings.globalViewSettings.ttsLyricStyle,
                singleLine: _singleLine,
              ),
            ),
          ),

          // 3. Anchored Bottom Media Controls Section
          TtsBottomPlayerControls(
            tts: tts,
            onDragUpdate: widget.onDragUpdate,
            onDragEnd: widget.onDragEnd,
          ),
        ],
      ),
    );
  }
}
