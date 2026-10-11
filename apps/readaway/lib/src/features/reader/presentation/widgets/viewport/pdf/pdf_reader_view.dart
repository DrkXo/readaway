import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/reader/domain/gestures/reader_gestures.dart';

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
    this.onTapAction,
    this.tapZonePolicy,
  });

  final ReaderState state;
  final ReaderPreferences prefs;
  final ReaderViewportController viewportController;
  final ValueChanged<int>? onPageChangeRequested;
  final ValueChanged<ReaderTapAction>? onTapAction;
  final TapZonePolicy? tapZonePolicy;

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  late final PdfViewerController _pdfController;
  PdfTextSelection? _selection;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _pdfController.addListener(_onPdfMatrixChanged);
    _attachControllerDelegates();
  }

  void _onPdfMatrixChanged() {
    if (!_pdfController.isReady) return;
    final zoom = _pdfController.currentZoom;
    final baseZoom = _pdfController.alternativeFitScale ?? 1.0;
    final isZoomed = (zoom - baseZoom).abs() > 0.05 && zoom > baseZoom;
    widget.viewportController.setPageZoom(widget.state.currentPage, isZoomed);
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
          anchor: PdfPageAnchor.center,
          duration: Duration.zero,
        );
      }
    }
  }

  void _attachControllerDelegates() {
    widget.viewportController.clearSelectionDelegate = () {
      final sel = _selection;
      if (sel is PdfTextSelectionDelegate) {
        sel.clearTextSelection();
      }
    };

    widget.viewportController.jumpToPageDelegate = (int targetIndex) {
      final pageNumber = targetIndex + 1;
      if (_pdfController.isReady &&
          pageNumber >= 1 &&
          pageNumber <= _pdfController.pageCount) {
        _pdfController.goToPage(
          pageNumber: pageNumber,
          anchor: PdfPageAnchor.center,
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
              anchor: PdfPageAnchor.center,
              duration: duration ?? const Duration(milliseconds: 250),
            );
          }
        };
  }

  @override
  void dispose() {
    _pdfController.removeListener(_onPdfMatrixChanged);
    widget.viewportController.jumpToPageDelegate = null;
    widget.viewportController.animateToPageDelegate = null;
    widget.viewportController.clearSelectionDelegate = null;
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
        widget.prefs.effectiveScrollDirection(
          isReflowable: false,
        ) ==
        ReaderScrollDirection.horizontal;

    return Container(
      color: appColors.readerBackground,
      child: PdfViewer.file(
        docPath,
        controller: _pdfController,
        initialPageNumber: widget.state.currentPage + 1,
        params: PdfViewerParams(
          backgroundColor: appColors.readerBackground,
          margin: 0.0,
          boundaryMargin: EdgeInsets.zero,
          pageDropShadow: null,
          pageAnchor: PdfPageAnchor.center,
          underflowAnchor: PdfPageAnchor.center,
          sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
            useAlternativeFitScaleAsMinScale: true,
            calculateInitialZoom: (document, controller, fitZoom, coverZoom) {
              return controller.alternativeFitScale ?? fitZoom;
            },
          ),
          textSelectionParams: PdfTextSelectionParams(
            onTextSelectionChange: (selection) {
              _selection = selection;
              widget.viewportController.setSelectionActive(
                selection.hasSelectedText,
              );
            },
          ),
          onGeneralTap: (tapContext, controller, details) {
            if (!mounted) return false;
            if (details.type != PdfViewerGeneralTapType.tap) {
              return false;
            }
            if (widget.viewportController.hasActiveSelection ||
                (_selection?.hasSelectedText ?? false)) {
              widget.viewportController.clearSelection();
              final sel = _selection;
              if (sel is PdfTextSelectionDelegate) {
                sel.clearTextSelection();
              }
              return true;
            }
            if (widget.viewportController.isPageZoomed) {
              return false;
            }
            final box = tapContext.findRenderObject() as RenderBox?;
            final globalPos = box != null && box.hasSize
                ? box.localToGlobal(details.localPosition)
                : details.localPosition;
            if (widget.viewportController.handleAnnotationTap(globalPos)) {
              return true;
            }
            final width = box?.hasSize == true
                ? box!.size.width
                : MediaQuery.sizeOf(context).width;
            final policy =
                widget.tapZonePolicy ??
                (GetIt.I.isRegistered<TapZonePolicy>()
                    ? GetIt.I<TapZonePolicy>()
                    : const TapZonePolicy());
            final action = policy.resolveTapAction(
              details.localPosition.dx,
              width,
              isRtl: widget.prefs.isRtl,
            );
            widget.onTapAction?.call(action);
            return true;
          },
          layoutPages: isHorizontal
              ? (pages, params) {
                  final height = pages.fold<double>(
                    0.0,
                    (prev, page) => math.max(prev, page.height),
                  );
                  final pageLayouts = <Rect>[];
                  double x = 0.0;
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
                    documentSize: Size(
                      x > 0 ? (params.margin > 0 ? x - params.margin : x) : 0,
                      height,
                    ),
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
