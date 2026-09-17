/// Indices surrounding [currentIndex] (current, next, previous) that fall
/// within `[0, pageCount)`, in that order. The caller skips any that are
/// already loaded or queued.
List<int> precacheCandidates(int currentIndex, int pageCount) {
  return [
    currentIndex,
    currentIndex + 1,
    currentIndex - 1,
  ].where((idx) => idx >= 0 && idx < pageCount).toList();
}
