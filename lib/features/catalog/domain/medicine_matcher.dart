import '../../../core/utils/fuzzy.dart';
import 'medicine.dart';

/// Result of matching one OCR line against the medicine database.
class MedicineMatch {
  const MedicineMatch({
    required this.rawLine,
    required this.query,
    required this.medicine,
    required this.score,
    required this.alternatives,
  });

  final String rawLine;

  /// The cleaned text that was compared (e.g. "azithrl 500").
  final String query;

  /// Best match, or null if nothing scored above the threshold.
  final Medicine? medicine;
  final double score;
  final List<Medicine> alternatives;

  bool get isMatched => medicine != null;
}

/// Restricts noisy OCR output to real medicine names via fuzzy matching.
///
/// Steps: strip dosage instructions (1-0-1, OD, BD, TDS, x 5 days ...),
/// drop form prefixes (Tab, Cap, Syp ...), then compare the first 1-4 tokens
/// against every medicine name with normalized Levenshtein similarity.
class MedicineMatcher {
  MedicineMatcher(this.medicines, {this.threshold = 0.7});

  final List<Medicine> medicines;
  final double threshold;

  static const _prefixes = {
    'tab', 'tabs', 'tablet', 'tablets', 'cap', 'caps', 'capsule', 'capsules',
    'syp', 'syr', 'syrup', 'inj', 'injection', 'rx', 't', 'c',
  };
  static const _stopWords = {
    'od', 'bd', 'bid', 'tds', 'tid', 'qid', 'hs', 'sos', 'stat', 'x', 'for',
    'days', 'day', 'weeks', 'week', 'before', 'after', 'food', 'meals',
    'morning', 'night', 'daily', 'once', 'twice', 'thrice', 'with', 'take',
  };
  static final _schedule = RegExp(r'\d+\s*-\s*\d+\s*-\s*\d+');
  static final _nonAlnum = RegExp(r'[^a-z0-9]+');
  static final _unit = RegExp(r'^(\d+(?:\.\d+)?)(mg|mcg|g|iu)$');
  static final _volume = RegExp(r'^\d+(?:\.\d+)?ml$');
  static final _duration = RegExp(r'^\d+(d|w|wk|days?)$'); // "3d", "2w"

  /// Turns "Tab. Dolo 650 mg 1-0-1 x 5 days" into ["dolo", "650"].
  List<String> tokens(String line) {
    var text = line.toLowerCase().replaceAll(_schedule, ' ');
    text = text.replaceAll(_nonAlnum, ' ').trim();
    final out = <String>[];
    for (final raw in text.split(' ')) {
      if (raw.isEmpty) continue;
      if (out.isEmpty && _prefixes.contains(raw)) continue;
      if (_stopWords.contains(raw) || _volume.hasMatch(raw) || _duration.hasMatch(raw)) break;
      if (raw == 'mg' || raw == 'mcg' || raw == 'iu') continue;
      final unit = _unit.firstMatch(raw);
      out.add(unit != null ? unit.group(1)! : raw);
      if (out.length == 4) break;
    }
    return out;
  }

  static String normalizeName(String name) => name
      .toLowerCase()
      .replaceAll('(generic)', ' ')
      .replaceAll(RegExp(r'\b(syrup|tablet|capsule)\b'), ' ')
      .replaceAll(_nonAlnum, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  double _score(List<String> toks, String target) {
    var best = 0.0;
    final compactTarget = target.replaceAll(' ', '');
    for (var k = 1; k <= toks.length; k++) {
      final q = toks.take(k).join(' ');
      final s1 = similarity(q, target);
      final s2 = similarity(q.replaceAll(' ', ''), compactTarget);
      final s = s1 > s2 ? s1 : s2;
      if (s > best) best = s;
    }
    return best;
  }

  MedicineMatch match(String line, {int alternatives = 3}) {
    final toks = tokens(line);
    final query = toks.join(' ');
    if (toks.isEmpty) {
      return MedicineMatch(
          rawLine: line, query: query, medicine: null, score: 0, alternatives: const []);
    }
    final scored = [
      for (final m in medicines) (m, _score(toks, normalizeName(m.name))),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    final best = scored.first;
    final matched = best.$2 >= threshold;
    return MedicineMatch(
      rawLine: line,
      query: query,
      medicine: matched ? best.$1 : null,
      score: best.$2,
      alternatives: [
        for (final s in scored.skip(matched ? 1 : 0).take(alternatives))
          if (s.$2 >= 0.4) s.$1,
      ],
    );
  }

  /// Simple search for the manual "add medicine" box: substring first, fuzzy after.
  List<Medicine> search(String text, {int limit = 20}) {
    final q = text.trim().toLowerCase();
    if (q.isEmpty) return medicines.take(limit).toList();
    final contains = medicines
        .where((m) =>
            m.name.toLowerCase().contains(q) || m.salt.toLowerCase().contains(q))
        .toList();
    if (contains.isNotEmpty) return contains.take(limit).toList();
    final toks = tokens(q);
    final scored = [
      for (final m in medicines) (m, _score(toks, normalizeName(m.name))),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(limit)) if (s.$2 >= 0.5) s.$1];
  }
}
