import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

import '../../../bloc/reader_bloc.dart';
import '../../../controllers/reader_viewport_controller.dart';
import '../../common/reader_error_view.dart';

/// Specialized high-performance PDF viewport backed by `pdfrx` (PDFium / CoreGraphics).
///
/// Features:
/// - Vector-sharp Level-Of-Detail (LOD) tile re-rendering on zoom (1.0x to 4.0x).
/// - Full selectable text layers and search highlights.
/// - Synchronization with [ReaderViewportController] and [ReaderBloc].
/// - Native hyperlink navigation (internal page jumps and external URLs).
class PdfReaderView extends StatefulWidget {
  const PdfReaderView({
    super.key,
    required this.state,
    required this.prefs,
    required this.viewportController,
    this.onPageChangeRequested,
  });

  final ReaderState state;
  final ReaderPreferences prefs;
  final ReaderViewportController viewportController;
  final ValueChanged<int>? onPageChangeRequested;

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  late final PdfViewerController _pdfController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _attachControllerDelegates();
  }

  @override
  void didUpdateWidget(PdfReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportController != widget.viewportController) {
      _attachControllerDelegates();
    }

    if (oldWidget.state.currentPage != widget.state.currentPage &&
        !_isSyncing) {
      final targetPageNumber = widget.state.currentPage + 1;
      if (_pdfController.isReady &&
          _pdfController.pageNumber != targetPageNumber &&
          targetPageNumber >= 1 &&
          targetPageNumber <= _pdfController.pageCount) {
        _pdfController.goToPage(
          pageNumber: targetPageNumber,
          duration: Duration.zero,
        );
      }
    }
  }

  void _attachControllerDelegates() {
    widget.viewportController.jumpToPageDelegate = (int targetIndex) {
      final pageNumber = targetIndex + 1;
      if (_pdfController.isReady &&
          pageNumber >= 1 &&
          pageNumber <= _pdfController.pageCount) {
        _pdfController.goToPage(
          pageNumber: pageNumber,
          duration: Duration.zero,
        );
      }
    };

    widget.viewportController.animateToPageDelegate =
        (
          int targetIndex, {
          Duration? duration,
          Curve? curve,
        }) async {
          final pageNumber = targetIndex + 1;
          if (_pdfController.isReady &&
              pageNumber >= 1 &&
              pageNumber <= _pdfController.pageCount) {
            await _pdfController.goToPage(
              pageNumber: pageNumber,
              duration: duration ?? const Duration(milliseconds: 250),
            );
          }
        };
  }

  @override
  void dispose() {
    widget.viewportController.jumpToPageDelegate = null;
    widget.viewportController.animateToPageDelegate = null;
    super.dispose();
  }

  void _onPdfPageChanged(int? pageNumber) {
    if (pageNumber == null) return;
    final pageIndex = pageNumber - 1;
    if (pageIndex == widget.state.currentPage) return;

    _isSyncing = true;
    try {
      widget.viewportController.setCurrentPage(pageIndex);
      widget.onPageChangeRequested?.call(pageIndex);
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final docPath = widget.state.documentPath;
    if (docPath == null || !File(docPath).existsSync()) {
      return const ReaderErrorView();
    }

    final appColors = context.appColors;
    final isHorizontal =
        widget.prefs.scrollDirection == ReaderScrollDirection.horizontal;

    return Container(
      color: appColors.readerBackground,
      child: PdfViewer.file(
        docPath,
        controller: _pdfController,
        initialPageNumber: widget.state.currentPage + 1,
        params: PdfViewerParams(
          backgroundColor: appColors.readerBackground,
          margin: 8.0,
          layoutPages: isHorizontal
              ? (pages, params) {
                  final height =
                      pages.fold<double>(
                        0.0,
                        (prev, page) => math.max(prev, page.height),
                      ) +
                      params.margin * 2;
                  final pageLayouts = <Rect>[];
                  double x = params.margin;
                  for (final page in pages) {
                    pageLayouts.add(
                      Rect.fromLTWH(
                        x,
                        (height - page.height) / 2,
                        page.width,
                        page.height,
                      ),
                    );
                    x += page.width + params.margin;
                  }
                  return PdfPageLayout(
                    pageLayouts: pageLayouts,
                    documentSize: Size(x, height),
                  );
                }
              : null,
          onPageChanged: _onPdfPageChanged,
          onViewerReady: (document, controller) {
            widget.viewportController.updatePageCount(document.pages.length);
          },
        ),
      ),
    );
  }
}
