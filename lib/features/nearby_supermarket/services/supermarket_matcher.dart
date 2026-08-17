import '../../../models/supermarket.dart';
import '../../../repositories/supermarket_repository.dart';
import '../models/supermarket_model.dart';

/// Best-effort link between a Google Places result (Nearby Supermarket
/// module) and its premise in the local PriceCatcher dataset ([Supermarket],
/// keyed by premise_code). Result of [SupermarketMatcher.match].
///
/// The two data sources don't share an ID and don't always agree on naming
/// (e.g. a chain rebrand, or Google's formatting vs. the government
/// dataset's), so [score] reflects how confident the text match is —
/// callers should treat [isApproximate] matches as "closest guess" rather
/// than exact in the UI.
class SupermarketMatch {
  const SupermarketMatch({required this.supermarket, required this.score});

  final Supermarket supermarket;
  final double score;

  bool get isApproximate => score < 0.34;
}

/// Matches a [SupermarketModel] (Places API) to a [Supermarket] (PriceCatcher)
/// by normalized name/address text similarity.
///
/// Always returns the closest candidate it can find rather than null, so the
/// Nearby Supermarket detail screen never shows a blank "no data" state
/// purely because Google's name formatting differs from the government
/// dataset's — it only returns null if the local dataset itself has no rows.
class SupermarketMatcher {
  SupermarketMatcher({SupermarketRepository? repository})
      : _repository = repository ?? SupermarketRepository();

  final SupermarketRepository _repository;

  static const _stopWords = {'SDN', 'BHD', 'THE', 'AND', 'DAN', 'NO'};

  Future<SupermarketMatch?> match(SupermarketModel place) async {
    final nameTokens = _tokens(place.name);
    final addressTokens = _tokens(place.address);

    final candidates = <String, Supermarket>{};

    // Search on the most distinctive tokens first (usually the brand name) —
    // a LIKE search on a generic word would return too much of the table.
    for (final token in nameTokens.take(3)) {
      for (final found in await _repository.searchByName(token, limit: 200)) {
        candidates[found.premiseCode] = found;
      }
    }

    if (candidates.isEmpty) {
      for (final token in addressTokens.take(3)) {
        for (final found in await _repository.searchByName(token, limit: 200)) {
          candidates[found.premiseCode] = found;
        }
      }
    }

    if (candidates.isEmpty) {
      // Last resort so the UI never has to show "no data" just because
      // nothing in the name/address matched textually.
      for (final found in await _repository.getAll(limit: 3000)) {
        candidates[found.premiseCode] = found;
      }
    }

    if (candidates.isEmpty) return null;

    Supermarket? best;
    var bestScore = -1.0;
    for (final candidate in candidates.values) {
      final score = _score(nameTokens, addressTokens, candidate);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best == null ? null : SupermarketMatch(supermarket: best, score: bestScore);
  }

  double _score(Set<String> nameTokens, Set<String> addressTokens, Supermarket candidate) {
    final nameSimilarity = _jaccard(nameTokens, _tokens(candidate.name));

    final candidateAddressTokens = {
      ..._tokens(candidate.address),
      ..._tokens(candidate.district),
    };
    final addressOverlap = addressTokens.intersection(candidateAddressTokens).isNotEmpty ? 0.15 : 0.0;

    return nameSimilarity * 0.85 + addressOverlap;
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0 : intersection / union;
  }

  Set<String> _tokens(String value) {
    final cleaned = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ');
    return cleaned
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !_stopWords.contains(t))
        .toSet();
  }
}
