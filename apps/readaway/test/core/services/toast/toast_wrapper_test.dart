import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/toast/toast_service.dart';
import 'package:readaway/src/core/services/toast/toast_types.dart';
import 'package:readaway/src/core/services/toast/toast_widget.dart';
import 'package:readaway/src/core/services/toast/toast_wrapper.dart';

void main() {
  group('ToastWrapper Widget Tests', () {
    late ToastService toastService;

    setUp(() {
      toastService = ToastService();
    });

    tearDown(() {
      toastService.dispose();
    });

    testWidgets('renders child widget when no toast is active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ToastWrapper(
            service: toastService,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(
            body: Text('Main Screen Content'),
          ),
        ),
      );

      expect(find.text('Main Screen Content'), findsOneWidget);
      expect(find.byType(ToastWidget), findsNothing);
    });

    testWidgets('shows toast over modal bottom sheet and dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ToastWrapper(
            service: toastService,
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('Modal Bottom Sheet')),
                    ),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open modal bottom sheet
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Modal Bottom Sheet'), findsOneWidget);

      // Trigger toast while modal is open
      toastService.show(
        message: 'Toast above modal',
        type: ToastType.success,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Toast is rendered
      expect(find.text('Toast above modal'), findsOneWidget);
      expect(find.byType(ToastWidget), findsOneWidget);

      // Dismiss toast
      toastService.hideCurrent();
      await tester.pumpAndSettle();

      expect(find.byType(ToastWidget), findsNothing);
      // Modal sheet remains open
      expect(find.text('Modal Bottom Sheet'), findsOneWidget);
    });

    testWidgets('allows interacting with toast action button', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ToastWrapper(
            service: toastService,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(
            body: Text('Screen'),
          ),
        ),
      );

      toastService.show(
        message: 'Action test',
        action: ToastAction(
          label: 'Undo',
          onPressed: () => actionTriggered = true,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('auto-dismisses after specified duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ToastWrapper(
            service: toastService,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(
            body: Text('Screen'),
          ),
        ),
      );

      toastService.show(
        message: 'Temporary Toast',
        duration: const Duration(seconds: 1),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Temporary Toast'), findsOneWidget);

      // Advance time past duration
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Temporary Toast'), findsNothing);
    });
  });
}
