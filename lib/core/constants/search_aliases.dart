/// English → Bahasa Melayu grocery term aliases.
///
/// The PriceCatcher dataset only has Malay product names ("MINYAK MASAK",
/// not "cooking oil"), so a plain substring search for an English word like
/// "oil" returns nothing even though the product is right there. This is a
/// small, deliberately non-exhaustive dictionary of common everyday grocery
/// terms to bridge that gap — not a translator, just enough for a shopper
/// typing in English to land on the right Malay product names.
///
/// Keys are lowercase English terms (single words or short common phrases);
/// values are the Malay terms to also search for.
const Map<String, List<String>> kGroceryAliasesEnToMy = {
  'oil': ['minyak'],
  'cooking oil': ['minyak masak'],
  'rice': ['beras', 'nasi'],
  'sugar': ['gula'],
  'salt': ['garam'],
  'flour': ['tepung'],
  'milk': ['susu'],
  'egg': ['telur'],
  'eggs': ['telur'],
  'chicken': ['ayam'],
  'meat': ['daging'],
  'beef': ['daging lembu'],
  'mutton': ['daging kambing'],
  'fish': ['ikan'],
  'prawn': ['udang'],
  'shrimp': ['udang'],
  'seafood': ['bahan laut', 'hasil laut'],
  'vegetable': ['sayur'],
  'vegetables': ['sayur-sayuran'],
  'fruit': ['buah'],
  'fruits': ['buah-buahan'],
  'bread': ['roti'],
  'butter': ['mentega'],
  'noodle': ['mee', 'bihun'],
  'noodles': ['mee', 'bihun'],
  'biscuit': ['biskut'],
  'biscuits': ['biskut'],
  'cookie': ['biskut'],
  'cookies': ['biskut'],
  'chocolate': ['coklat'],
  'coffee': ['kopi'],
  'tea': ['teh'],
  'drink': ['minuman'],
  'drinks': ['minuman'],
  'beverage': ['minuman'],
  'water': ['air'],
  'juice': ['jus'],
  'coconut': ['kelapa'],
  'coconut milk': ['santan'],
  'onion': ['bawang'],
  'garlic': ['bawang putih'],
  'ginger': ['halia'],
  'chili': ['cili'],
  'chilli': ['cili'],
  'pepper': ['lada'],
  'spice': ['rempah'],
  'spices': ['rempah ratus'],
  'potato': ['ubi kentang'],
  'bean': ['kacang'],
  'beans': ['kacang'],
  'peanut': ['kacang tanah'],
  'tofu': ['tauhu'],
  'soap': ['sabun'],
  'shampoo': ['syampu'],
  'toothpaste': ['ubat gigi'],
  'toothbrush': ['berus gigi'],
  'tissue': ['tisu'],
  'diaper': ['lampin'],
  'diapers': ['lampin'],
  'medicine': ['ubat'],
  'baby food': ['makanan bayi'],
  'snack': ['makanan ringan'],
  'snacks': ['makanan ringan'],
  'sauce': ['sos'],
  'soy sauce': ['kicap'],
};

/// Expands [query] into the set of lowercase terms to search for: the
/// original query, plus any Malay aliases for the whole query or for any
/// individual word in it. Always includes the original so a query that's
/// already in Malay (or matches nothing in the dictionary) still works
/// exactly as a plain substring search would.
List<String> expandSearchTerms(String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return const [];

  final terms = <String>{trimmed};

  final wholeMatch = kGroceryAliasesEnToMy[trimmed];
  if (wholeMatch != null) terms.addAll(wholeMatch);

  for (final word in trimmed.split(RegExp(r'\s+'))) {
    final match = kGroceryAliasesEnToMy[word];
    if (match != null) terms.addAll(match);
  }

  return terms.toList();
}
