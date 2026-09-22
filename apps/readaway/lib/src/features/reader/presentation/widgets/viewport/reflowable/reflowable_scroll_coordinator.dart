import 'package:flutter/material.dart';

import '../../../../../settings/domain/entity/reader_preferences.dart';

class ReflowableScrollCoordinator {
  ReflowableScrollCoordinator({
    required this._scrollController,
    required this._index,
    required this._pageCount,
    required this._direction,
    required this._onPageChangeRequested,
    required this._onScrollBoundaryChanged,
  });

  final ScrollController _scrollController;
  final ValueChanged<int> _onPageChangeRequested;
  final void Function({required bool atTop, required bool atBottom})?
  _onScrollBoundaryChanged;

  int _index;
  int _pageCount;
  ReaderScrollDirection _direction;
  double _accumulatedBottomOverscroll = 0.0;
  double _accumulatedTopOverscroll = 0.0;
  bool _navigating = false;
  bool _atTop = true;
  bool _atBottom = false;

  static const _overscrollTriggerDistance = 48.0;

  void update({
    required int index,
    required int pageCount,
    required ReaderScrollDirection direction,
  }) {
    _index = index;
    _pageCount = pageCount;
    _direction = direction;
  }

  void reportBoundary() {
    final bool atTop;
    final bool atBottom;
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      atTop = position.pixels <= position.minScrollExtent;
      atBottom = position.pixels >= position.maxScrollExtent;
    } else {
      atTop = true;
      atBottom = true;
    }

    if (atTop == _atTop && atBottom == _atBottom) return;
    _atTop = atTop;
    _atBottom = atBottom;
    _onScrollBoundaryChanged?.call(atTop: atTop, atBottom: atBottom);
  }

  bool handleNotification(ScrollNotification notification) {
    if (_navigating) return false;

    final isVerticalPaging = _direction == ReaderScrollDirection.vertical;
    if (notification is OverscrollNotification) {
      if (isVerticalPaging && notification.overscroll > 0) {
        _accumulatedBottomOverscroll += notification.overscroll;
        if (_accumulatedBottomOverscroll > _overscrollTriggerDistance &&
            _index < _pageCount - 1) {
          _navigate(_index + 1);
        }
      } else if (isVerticalPaging && notification.overscroll < 0) {
        _accumulatedTopOverscroll += notification.overscroll.abs();
        if (_accumulatedTopOverscroll > _overscrollTriggerDistance &&
            _index > 0) {
          _navigate(_index - 1);
        }
      }
    } else if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      final delta = notification.scrollDelta ?? 0.0;
      if (isVerticalPaging) {
        if (metrics.pixels >= metrics.maxScrollExtent && delta > 0) {
          _accumulatedBottomOverscroll += delta;
          if (_accumulatedBottomOverscroll > _overscrollTriggerDistance &&
              _index < _pageCount - 1) {
            _navigate(_index + 1);
          }
        } else if (metrics.pixels <= metrics.minScrollExtent && delta < 0) {
          _accumulatedTopOverscroll += delta.abs();
          if (_accumulatedTopOverscroll > _overscrollTriggerDistance &&
              _index > 0) {
            _navigate(_index - 1);
          }
        }
      }
      reportBoundary();
    } else if (notification is ScrollEndNotification) {
      _accumulatedBottomOverscroll = 0.0;
      _accumulatedTopOverscroll = 0.0;
      reportBoundary();
    }

    return false;
  }

  void _navigate(int page) {
    _navigating = true;
    _onPageChangeRequested(page);
  }
}
