/// Audio-domain primitives: PCM conditioning and speech pacing maths.
///
/// These operate on raw sample buffers and clock values rather than documents,
/// and carry no native dependencies, so they are reusable by any consumer of
/// the reading engine.
library;

export 'pcm.dart';
export 'timing.dart';
