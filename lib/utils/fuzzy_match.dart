/// Returns a match score between [query] and [target] (0.0 = no match, 1.0 = exact).
///
/// Scoring tiers:
///   1.0  – exact substring
///   0.35–0.6 – subsequence match (all chars appear in order)
///   0.2–0.4  – Levenshtein-based typo tolerance
double fuzzyMatchScore(String query, String target) {
  if (query.isEmpty) return 1.0;

  final q = query.toLowerCase().trim();
  final t = target.toLowerCase().trim();

  if (t.isEmpty) return 0.0;

  // Exact substring match
  if (t.contains(q)) return 1.0;

  // Subsequence match — every char of q appears in t in order
  if (_isSubsequence(q, t)) {
    final coverage = q.length / t.length;
    return 0.35 + (coverage * 0.25); // 0.35 – 0.6
  }

  // Levenshtein-based match for typo tolerance
  final dist = _levenshtein(q, t);
  final maxLen = q.length > t.length ? q.length : t.length;
  if (maxLen == 0) return 0.0;

  final similarity = 1.0 - (dist / maxLen);
  if (similarity >= 0.5) {
    return 0.2 + (similarity * 0.2); // 0.3 – 0.4
  }

  return 0.0;
}

/// Returns true if [query] is a subsequence of [target] (all chars in order).
bool _isSubsequence(String query, String target) {
  var qi = 0;
  for (var ti = 0; ti < target.length && qi < query.length; ti++) {
    if (query[qi] == target[ti]) qi++;
  }
  return qi == query.length;
}

/// Standard Levenshtein edit distance.
int _levenshtein(String a, String b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Optimise: only keep two rows at a time
  final prev = List<int>.generate(b.length + 1, (i) => i);
  final curr = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = [
        prev[j] + 1,       // deletion
        curr[j - 1] + 1,   // insertion
        prev[j - 1] + cost, // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
    // Swap rows
    for (var j = 0; j <= b.length; j++) {
      prev[j] = curr[j];
    }
  }

  return prev[b.length];
}

/// Filters and sorts [items] by fuzzy-matching [query] against [getText].
/// Only items with a score >= [threshold] are returned.
List<T> fuzzyFilter<T>(
  String query,
  List<T> items,
  String Function(T) getText, {
  double threshold = 0.35,
}) {
  if (query.trim().isEmpty) return items;

  final scored = <MapEntry<T, double>>[];
  for (final item in items) {
    final score = fuzzyMatchScore(query, getText(item));
    if (score >= threshold) {
      scored.add(MapEntry(item, score));
    }
  }

  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.map((e) => e.key).toList();
}
