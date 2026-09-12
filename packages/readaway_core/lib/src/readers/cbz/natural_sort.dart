/// Natural (human) ordering for strings.
///
/// Compares digit runs numerically so that `page2` sorts before `page10`,
/// mirroring MuPDF's `cbz_strnatcmp`. Non-digit characters compare
/// case-insensitively with a case-sensitive tiebreak.
library;

/// Compares [a] and [b] using natural ordering.
///
/// Returns a negative value when [a] sorts before [b], zero when they are
/// equal, and a positive value when [a] sorts after [b].
int naturalCompare(String a, String b) {
  var i = 0;
  var j = 0;
  while (i < a.length && j < b.length) {
    final ca = a.codeUnitAt(i);
    final cb = b.codeUnitAt(j);
    final da = _isDigit(ca);
    final db = _isDigit(cb);
    if (da && db) {
      // Compare digit runs numerically.
      var ia = i;
      var ib = j;
      while (ia < a.length && _isDigit(a.codeUnitAt(ia))) {
        ia++;
      }
      while (ib < b.length && _isDigit(b.codeUnitAt(ib))) {
        ib++;
      }
      // Strip leading zeros so "02" compares equal to "2".
      var za = i;
      var zb = j;
      while (za < ia - 1 && a.codeUnitAt(za) == 0x30) {
        za++;
      }
      while (zb < ib - 1 && b.codeUnitAt(zb) == 0x30) {
        zb++;
      }
      final lenA = ia - za;
      final lenB = ib - zb;
      if (lenA != lenB) {
        return lenA < lenB ? -1 : 1;
      }
      for (var k = 0; k < lenA; k++) {
        final ca2 = a.codeUnitAt(za + k);
        final cb2 = b.codeUnitAt(zb + k);
        if (ca2 != cb2) {
          return ca2 < cb2 ? -1 : 1;
        }
      }
      i = ia;
      j = ib;
    } else {
      if (ca != cb) {
        final la = _toLower(ca);
        final lb = _toLower(cb);
        if (la != lb) {
          return la < lb ? -1 : 1;
        }
        return ca < cb ? -1 : 1;
      }
      i++;
      j++;
    }
  }
  if (i < a.length) return 1;
  if (j < b.length) return -1;
  return 0;
}

bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

int _toLower(int codeUnit) {
  if (codeUnit >= 0x41 && codeUnit <= 0x5A) {
    return codeUnit + 0x20;
  }
  return codeUnit;
}
