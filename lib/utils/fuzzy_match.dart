double fuzzyMatchScore(String query, String target) {
  if (query.trim().isEmpty) return 1.0;

  final q = query.toLowerCase().trim();
  final t = target.toLowerCase().trim();

  if (t.isEmpty) return 0.0;

  if (t == q) return 1.0;

  final words = t.split(RegExp(r'\s+'));

  final wordIndex = words.indexOf(q);
  if (wordIndex != -1) {
    return wordIndex == 0 ? 0.97 : 0.95;
  }

  if (t.contains(q)) {
    if (t.startsWith(q)) return 0.75;
    if (t.endsWith(q)) return 0.70;
    return 0.65;
  }

  if (_isSubsequence(q, t)) {
    final coverage = q.length / t.length;
    return 0.35 + coverage * 0.25;
  }

  final dist = _levenshtein(q, t);
  final maxLen = q.length > t.length ? q.length : t.length;

  if (maxLen == 0) return 0.0;

  final similarity = 1.0 - dist / maxLen;

  if (similarity >= 0.5) {
    return 0.2 + similarity * 0.2;
  }

  return 0.0;
}

bool _isSubsequence(String query, String target) {
  var qi = 0;

  for (var ti = 0; ti < target.length && qi < query.length; ti++) {
    if (query[qi] == target[ti]) {
      qi++;
    }
  }

  return qi == query.length;
}

int _levenshtein(String a, String b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final prev = List<int>.generate(b.length + 1, (i) => i);
  final curr = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;

    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;

      curr[j] = [
        prev[j] + 1,
        curr[j - 1] + 1,
        prev[j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }

    for (var j = 0; j <= b.length; j++) {
      prev[j] = curr[j];
    }
  }

  return prev[b.length];
}

List<T> fuzzyFilter<T>(
  String query,
  List<T> items,
  String Function(T) getText, {
  double threshold = 0.35,
}) {
  if (query.trim().isEmpty) return items;

  final q = query.toLowerCase().trim();

  final scored = <MapEntry<T, double>>[];

  for (final item in items) {
    final score = fuzzyMatchScore(q, getText(item));

    if (score >= threshold) {
      scored.add(MapEntry(item, score));
    }
  }

  scored.sort((a, b) {
    final scoreCmp = b.value.compareTo(a.value);
    if (scoreCmp != 0) return scoreCmp;

    final aText = getText(a.key).toLowerCase();
    final bText = getText(b.key).toLowerCase();

    final aPos = aText.indexOf(q);
    final bPos = bText.indexOf(q);

    if (aPos != bPos) {
      return aPos.compareTo(bPos);
    }

    if (aText.length != bText.length) {
      return aText.length.compareTo(bText.length);
    }

    return aText.compareTo(bText);
  });

  return scored.map((e) => e.key).toList();
}