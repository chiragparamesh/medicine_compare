import 'dart:math' as math;

/// Levenshtein edit distance (insert, delete, substitute = 1).
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  var curr = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      curr[j] = math.min(
        math.min(curr[j - 1] + 1, prev[j] + 1),
        prev[j - 1] + cost,
      );
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[b.length];
}

/// Normalized similarity in [0, 1]; 1 means identical.
double similarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1;
  final maxLen = math.max(a.length, b.length);
  return 1 - levenshtein(a, b) / maxLen;
}
