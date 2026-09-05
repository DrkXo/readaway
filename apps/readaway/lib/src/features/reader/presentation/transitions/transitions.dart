import 'package:readaway/src/features/settings/domain/models/reader_preferences.dart';
import 'cover_page_transition.dart';
import 'curl_page_transition.dart';
import 'fade_page_transition.dart';
import 'none_page_transition.dart';
import 'reader_page_transition_strategy.dart';
import 'shared_axis_page_transition.dart';
import 'slide_page_transition.dart';

export 'cover_page_transition.dart';
export 'curl_page_transition.dart';
export 'fade_page_transition.dart';
export 'none_page_transition.dart';
export 'reader_page_transition_strategy.dart';
export 'shared_axis_page_transition.dart';
export 'slide_page_transition.dart';

/// Registry and factory for reader page transitions.
///
/// Easily allows registering new custom transitions at runtime or mocking for tests.
class ReaderPageTransitionFactory {
  ReaderPageTransitionFactory._();

  static final Map<ReaderPageTransition, ReaderPageTransitionStrategy>
      _registry = {
    ReaderPageTransition.none: const NonePageTransitionStrategy(),
    ReaderPageTransition.fade: const FadePageTransitionStrategy(),
    ReaderPageTransition.slide: const SlidePageTransitionStrategy(),
    ReaderPageTransition.sharedAxis: const SharedAxisPageTransitionStrategy(),
    ReaderPageTransition.cover: const CoverPageTransitionStrategy(),
    ReaderPageTransition.curl: const CurlPageTransitionStrategy(),
  };

  /// Retrieves the registered strategy for [transition].
  ///
  /// Defaults to [SlidePageTransitionStrategy] if unspecified.
  static ReaderPageTransitionStrategy get(ReaderPageTransition transition) {
    return _registry[transition] ?? const SlidePageTransitionStrategy();
  }

  /// Registers or overrides a [strategy] for a given [transition] type.
  static void register(
    ReaderPageTransition transition,
    ReaderPageTransitionStrategy strategy,
  ) {
    _registry[transition] = strategy;
  }
}
