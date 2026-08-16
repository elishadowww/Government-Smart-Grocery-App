import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/product.dart';
import '../repositories/budget_repository.dart';
import 'current_user_provider.dart';
import 'price_provider.dart';
import 'product_provider.dart';
import 'shopping_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

/// The current user's saved budget, or null if none has been set yet.
/// Backs the Budget screen (§7.7) and gates the Dashboard budget card,
/// which only appears once a budget has been created.
final budgetProvider = FutureProvider<Budget?>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return ref.watch(budgetRepositoryProvider).getBudget(uid);
});

/// Money spent so far against the budget — the shopping cart's current
/// total (spec §7.7 business rule: "Budget decreases automatically as
/// items are added to the shopping list").
final budgetUsedProvider = Provider<double>((ref) {
  return ref.watch(shoppingListTotalProvider);
});

/// Fraction of the budget spent so far; null when no budget is set. Not
/// clamped to 1.0 so callers can detect "exceeded" (> 1) and colour the
/// progress bar accordingly (spec §7.7: green within budget, red when
/// exceeded).
final budgetProgressProvider = Provider<double?>((ref) {
  final budget = ref.watch(budgetProvider).value;
  if (budget == null || budget.amount <= 0) return null;
  final used = ref.watch(budgetUsedProvider);
  return used / budget.amount;
});

class BudgetController {
  BudgetController(this._ref);

  final Ref _ref;

  Future<bool> setBudget(double amount) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return false;
    await _ref.read(budgetRepositoryProvider).setBudget(uid, amount);
    _ref.invalidate(budgetProvider);
    return true;
  }
}

final budgetControllerProvider = Provider<BudgetController>((ref) {
  return BudgetController(ref);
});

/// A cheaper same-category product than one currently in the cart — backs
/// the "Cheaper Alternatives" card (spec §7.7 business rule: "the system
/// surfaces cheaper alternative products").
class CheaperAlternative {
  const CheaperAlternative({
    required this.original,
    required this.alternative,
    required this.savings,
  });

  final Product original;
  final Product alternative;
  final double savings;
}

/// Scans the current cart for cheaper same-category substitutes, scoped to
/// products already in the cart (not a nationwide scan). For each cart
/// item with a resolved price, finds the cheapest other product in the
/// same category and surfaces it if it beats the item's own price.
final cheaperAlternativesProvider = FutureProvider<List<CheaperAlternative>>((ref) async {
  final entries = await ref.watch(shoppingListEntriesProvider.future);
  if (entries.isEmpty) return const [];

  final productRepo = ref.watch(productRepositoryProvider);
  final priceRepo = ref.watch(priceRepositoryProvider);

  final results = <CheaperAlternative>[];
  for (final entry in entries) {
    final currentPrice = entry.price?.price;
    if (currentPrice == null) continue;

    final category = entry.product.itemCategory;
    if (category.isEmpty) continue;

    final candidates = await productRepo.getByCategory(category);
    final candidateIds = candidates
        .where((p) => p.itemCode != entry.product.itemCode)
        .map((p) => p.itemCode)
        .toList();
    if (candidateIds.isEmpty) continue;

    final cheapestByCandidate = await priceRepo.getCheapestPrices(candidateIds);
    if (cheapestByCandidate.isEmpty) continue;

    final cheapest = cheapestByCandidate.values.reduce((a, b) => a.price < b.price ? a : b);
    if (cheapest.price >= currentPrice) continue;

    final altProduct = candidates.firstWhere((p) => p.itemCode == cheapest.itemCode);
    results.add(CheaperAlternative(
      original: entry.product,
      alternative: altProduct,
      savings: (currentPrice - cheapest.price) * entry.quantity,
    ));
  }

  results.sort((a, b) => b.savings.compareTo(a.savings));
  return results;
});
