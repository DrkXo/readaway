import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/error/failures.dart';
import 'package:readaway/src/core/services/toast/toast_service.dart';
import 'package:readaway/src/core/services/toast/toast_types.dart';

void main() {
  group('ToastService Tests', () {
    late ToastService toastService;

    setUp(() {
      toastService = ToastService();
    });

    tearDown(() {
      toastService.dispose();
    });

    test('initial state has no active toast', () {
      expect(toastService.currentToast, isNull);
      expect(toastService.currentToastNotifier.value, isNull);
    });

    test('show creates and sets active ToastEntry', () {
      toastService.show(
        message: 'Test message',
        title: 'Test title',
        type: ToastType.success,
      );

      final current = toastService.currentToast;
      expect(current, isNotNull);
      expect(current!.id.startsWith('toast_'), isTrue);
      expect(current.position, ToastPosition.bottom);
      expect(current.duration, const Duration(milliseconds: 3500));
    });

    test('hideCurrent dismisses the active toast', () {
      toastService.show(message: 'Dismiss me');
      expect(toastService.currentToast, isNotNull);

      toastService.hideCurrent();
      expect(toastService.currentToast, isNull);
    });

    test('clear removes active toast', () {
      toastService.show(message: 'Clear me');
      expect(toastService.currentToast, isNotNull);

      toastService.clear();
      expect(toastService.currentToast, isNull);
    });

    test('showSuccess sets success toast', () {
      toastService.showSuccess('Operation succeeded');
      expect(toastService.currentToast, isNotNull);
    });

    test('showError sets error toast with action', () {
      var retried = false;
      toastService.showError(
        'Network failure',
        onRetry: () => retried = true,
      );

      expect(toastService.currentToast, isNotNull);
      expect(retried, isFalse);
    });

    test('showFailure sets error toast from Failure', () {
      const failure = ServerFailure(500, 'Server unavailable');
      toastService.showFailure(failure);

      expect(toastService.currentToast, isNotNull);
    });

    test('showCustom creates custom toast entry', () {
      toastService.showCustom(
        content: const Text('Custom UI'),
        position: ToastPosition.top,
      );

      final current = toastService.currentToast;
      expect(current, isNotNull);
      expect(current!.position, ToastPosition.top);
    });
  });
}
