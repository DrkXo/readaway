import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway/src/core/services/services.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';

import '../../bloc/reader_bloc.dart';
import '../../../domain/repositories/reader_repository.dart';
import '../viewport/fixed_layout/fixed_layout_image_cache.dart';

/// Modal bottom sheet / popover for sharing entire documents or individual rasterized pages.
class ReaderShareSheet extends StatefulWidget {
  const ReaderShareSheet({
    super.key,
    required this.state,
    this.shareService,
    this.readerRepository,
  });

  final ReaderState state;
  final ShareService? shareService;
  final ReaderRepository? readerRepository;

  /// Shows the share sheet within [context].
  static Future<void> show({
    required BuildContext context,
    required ReaderState state,
    ShareService? shareService,
    ReaderRepository? readerRepository,
  }) {
    return showAppSheet<void>(
      context: context,
      title: 'Share',
      maxWidth: 480,
      builder: (ctx) => ReaderShareSheet(
        state: state,
        shareService: shareService,
        readerRepository: readerRepository,
      ),
    );
  }

  @override
  State<ReaderShareSheet> createState() => _ReaderShareSheetState();
}

class _ReaderShareSheetState extends State<ReaderShareSheet> {
  late int _selectedPageIndex;
  bool _isSharing = false;
  String? _sharingStatusMessage;

  ShareService get _shareService =>
      widget.shareService ??
      (GetIt.I.isRegistered<ShareService>()
          ? GetIt.I<ShareService>()
          : ShareService());

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.state.displayCurrentPage.clamp(
      0,
      (widget.state.displayPageCount > 0
          ? widget.state.displayPageCount - 1
          : 0),
    );
  }

  Future<void> _handleShareEntireDocument() async {
    final docPath = widget.state.documentPath;
    if (docPath == null) return;

    setState(() {
      _isSharing = true;
      _sharingStatusMessage = 'Preparing document file...';
    });

    try {
      final success = await _shareService.shareDocumentFile(
        filePath: docPath,
        title: widget.state.bookTitle ?? widget.state.fileName,
      );

      if (!mounted) return;
      if (!success) {
        context.toasts.show(
          message: 'Unable to share document file.',
          type: ToastType.error,
        );
      } else {
        Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
          _sharingStatusMessage = null;
        });
      }
    }
  }

  Future<void> _handleSharePage(int pageIndex) async {
    final docPath = widget.state.documentPath;
    if (docPath == null) return;

    final cachedBytes =
        FixedLayoutImageCache.instance.getCachedImage(docPath, pageIndex);

    setState(() {
      _isSharing = true;
      _sharingStatusMessage = cachedBytes != null
          ? 'Preparing page ${pageIndex + 1} image...'
          : 'Rendering page ${pageIndex + 1} as image...';
    });

    try {
      Uint8List? bytes = cachedBytes;
      if (bytes == null || bytes.isEmpty) {
        final repo = widget.readerRepository ??
            (GetIt.I.isRegistered<ReaderRepository>()
                ? GetIt.I<ReaderRepository>()
                : null);
        if (repo != null) {
          final res = await repo.loadPageImage(pageIndex, scale: 1.0);
          bytes = res.dataOrNull;
        }
      }

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        context.toasts.show(
          message: 'Failed to load page ${pageIndex + 1} image.',
          type: ToastType.error,
        );
        return;
      }

      final success = await _shareService.sharePageImage(
        filePath: docPath,
        pageIndex: pageIndex,
        totalPages: widget.state.displayPageCount,
        imageBytes: bytes,
        title: widget.state.bookTitle ?? widget.state.fileName,
      );

      if (!mounted) return;
      if (!success) {
        context.toasts.show(
          message: 'Failed to render and share page ${pageIndex + 1}.',
          type: ToastType.error,
        );
      } else {
        Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
          _sharingStatusMessage = null;
        });
      }
    }
  }

  String _formatFileSize(String? path) {
    if (path == null) return '';
    try {
      final file = File(path);
      if (!file.existsSync()) return '';
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final title = widget.state.bookTitle ?? widget.state.fileName ?? 'Document';
    final format = widget.state.format.toUpperCase();
    final pageCount = widget.state.displayPageCount;
    final currentPage = widget.state.displayCurrentPage;
    final isNonReflowable = !widget.state.isReflowable;
    final fileSize = _formatFileSize(widget.state.documentPath);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Document Info Header Card
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: colors.readerBackground,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: colors.editorWidgetBorder,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Center(
                        child: Icon(
                          isNonReflowable
                              ? LucideIcons.fileText
                              : LucideIcons.bookOpen,
                          size: 22.0,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: colors.sidebarForeground,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  format,
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (pageCount > 0) ...[
                                const SizedBox(width: 8.0),
                                Text(
                                  '$pageCount pages',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: colors.sidebarForeground
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                              if (fileSize.isNotEmpty) ...[
                                const SizedBox(width: 8.0),
                                Text(
                                  '• $fileSize',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: colors.sidebarForeground
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Option 1: Share Entire Document File
              _ShareActionTile(
                icon: LucideIcons.fileUp,
                title: 'Share Document File',
                subtitle: 'Send the entire $format file',
                onTap: _isSharing ? null : _handleShareEntireDocument,
              ),

              // Option 2: Share Current Page (for non-reflowable formats)
              if (isNonReflowable && pageCount > 0) ...[
                const SizedBox(height: 8.0),
                _ShareActionTile(
                  icon: LucideIcons.image,
                  title: 'Share Current Page (${currentPage + 1})',
                  subtitle: 'Export current visible page as a PNG image',
                  onTap: _isSharing
                      ? null
                      : () => _handleSharePage(currentPage),
                ),

                const SizedBox(height: 14.0),
                Divider(color: colors.editorWidgetBorder, height: 1.0),
                const SizedBox(height: 14.0),

                // Option 3: Share Custom Page
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Share Selected Page',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: colors.sidebarForeground,
                      ),
                    ),
                    Text(
                      'Page ${_selectedPageIndex + 1} of $pageCount',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                if (pageCount > 1)
                  Slider(
                    value: _selectedPageIndex.toDouble(),
                    min: 0,
                    max: (pageCount - 1).toDouble(),
                    divisions: pageCount - 1,
                    onChanged: _isSharing
                        ? null
                        : (v) => setState(() => _selectedPageIndex = v.round()),
                  ),
                const SizedBox(height: 6.0),
                FilledButton.tonalIcon(
                  onPressed: _isSharing
                      ? null
                      : () => _handleSharePage(_selectedPageIndex),
                  icon: const Icon(LucideIcons.share2, size: 16.0),
                  label: Text('Share Page ${_selectedPageIndex + 1} as Image'),
                ),
              ],
            ],
          ),
        ),

        // Loading Overlay
        if (_isSharing)
          Positioned.fill(
            child: Container(
              color: colors.editorWidgetBackground.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2.5),
                    const SizedBox(height: 16.0),
                    Text(
                      _sharingStatusMessage ?? 'Sharing...',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: colors.sidebarForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShareActionTile extends StatelessWidget {
  const _ShareActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: colors.readerBackground,
      borderRadius: BorderRadius.circular(8.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: colors.editorWidgetBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20.0,
                color: scheme.primary,
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colors.sidebarForeground,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.sidebarForeground.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.share2,
                size: 16.0,
                color: colors.sidebarForeground.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
