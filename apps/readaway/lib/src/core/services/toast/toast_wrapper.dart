import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'toast_service.dart';
import 'toast_types.dart';

/// An [InheritedWidget] providing descendant access to [ToastService].
class ToastScope extends InheritedWidget {
  final ToastService service;

  const ToastScope({
    super.key,
    required this.service,
    required super.child,
  });

  /// Retrieves the nearest [ToastService], or falls back to [GetIt.I].
  static ToastService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ToastScope>();
    return scope?.service ?? GetIt.I.get<ToastService>();
  }

  /// Retrieves the nearest [ToastService], or returns `null` if unmounted.
  static ToastService? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ToastScope>();
    return scope?.service;
  }

  @override
  bool updateShouldNotify(ToastScope oldWidget) => service != oldWidget.service;
}

/// A top-level wrapper widget that renders floating toasts on top of all
/// application routes, modal sheets, and dialogs.
class ToastWrapper extends StatefulWidget {
  final Widget child;
  final ToastService? service;

  const ToastWrapper({
    super.key,
    required this.child,
    this.service,
  });

  /// Factory helper for use directly inside [MaterialApp.builder].
  static Widget builder(BuildContext context, Widget? child) {
    return ToastWrapper(
      child: child ?? const SizedBox.shrink(),
    );
  }

  @override
  State<ToastWrapper> createState() => _ToastWrapperState();
}

class _ToastWrapperState extends State<ToastWrapper>
    with SingleTickerProviderStateMixin {
  ToastService? _service;
  ToastEntry? _activeEntry;
  Timer? _dismissTimer;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final effectiveService =
        widget.service ??
        (GetIt.I.isRegistered<ToastService>()
            ? GetIt.I.get<ToastService>()
            : null);

    if (_service != effectiveService) {
      _service?.currentToastNotifier.removeListener(_onToastChanged);
      _service = effectiveService;
      _service?.currentToastNotifier.addListener(_onToastChanged);
      _checkInitialToast();
    }
  }

  @override
  void didUpdateWidget(ToastWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.service != oldWidget.service) {
      _service?.currentToastNotifier.removeListener(_onToastChanged);
      _service =
          widget.service ??
          (GetIt.I.isRegistered<ToastService>()
              ? GetIt.I.get<ToastService>()
              : null);
      _service?.currentToastNotifier.addListener(_onToastChanged);
      _checkInitialToast();
    }
  }

  void _checkInitialToast() {
    final entry = _service?.currentToast;
    if (entry != null && _activeEntry?.id != entry.id) {
      _displayToast(entry);
    }
  }

  void _onToastChanged() {
    final entry = _service?.currentToast;
    if (entry == null) {
      _dismissActiveToast();
    } else {
      _displayToast(entry);
    }
  }

  void _displayToast(ToastEntry entry) {
    _dismissTimer?.cancel();
    setState(() {
      _activeEntry = entry;
    });

    _animController.forward(from: 0.0);

    if (entry.duration > Duration.zero) {
      _dismissTimer = Timer(entry.duration, () {
        if (mounted && _activeEntry?.id == entry.id) {
          _service?.hideCurrent();
        }
      });
    }
  }

  void _dismissActiveToast() {
    _dismissTimer?.cancel();
    if (_activeEntry == null) return;

    _animController.reverse().then((_) {
      if (mounted && _service?.currentToast == null) {
        final dismissed = _activeEntry;
        setState(() {
          _activeEntry = null;
        });
        dismissed?.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _service?.currentToastNotifier.removeListener(_onToastChanged);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveService =
        _service ??
        (GetIt.I.isRegistered<ToastService>()
            ? GetIt.I.get<ToastService>()
            : null);

    Widget content = widget.child;

    if (effectiveService != null) {
      content = ToastScope(
        service: effectiveService,
        child: content,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        if (_activeEntry != null)
          Positioned(
            top: _activeEntry!.position == ToastPosition.top ? 0 : null,
            bottom: _activeEntry!.position == ToastPosition.bottom ? 0 : null,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                alignment: _activeEntry!.position == ToastPosition.top
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: SlideTransition(
                    position: _activeEntry!.position == ToastPosition.top
                        ? Tween<Offset>(
                            begin: const Offset(0, -0.4),
                            end: Offset.zero,
                          ).animate(_fadeAnimation)
                        : _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _activeEntry!.dismissOnSwipe
                          ? Dismissible(
                              key: ValueKey(_activeEntry!.id),
                              direction:
                                  _activeEntry!.position == ToastPosition.top
                                  ? DismissDirection.up
                                  : DismissDirection.down,
                              onDismissed: (_) {
                                _service?.hideCurrent();
                              },
                              child: _activeEntry!.content,
                            )
                          : _activeEntry!.content,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
