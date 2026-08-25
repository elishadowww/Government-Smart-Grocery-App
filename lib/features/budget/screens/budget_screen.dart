import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_strings.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../providers/budget_provider.dart';

/// Budget screen (spec Fig 7.7.1, Module 8 FR7). Lets the user set a
/// spending limit, tracks it live against the current cart total (spec
/// business rule: "Budget decreases automatically as items are added to
/// the shopping list"), and surfaces cheaper same-category substitutes
/// once any are found for items already in the cart.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_controller.text.trim());
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, ref.tr('enter_valid_budget_amount'), isError: true);
      return;
    }

    setState(() => _saving = true);
    final ok = await ref.read(budgetControllerProvider).setBudget(amount);
    if (!mounted) return;
    setState(() => _saving = false);

    showAppSnackBar(
      context,
      ok ? ref.tr('budget_saved') : ref.tr('could_not_save_budget'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetProvider);
    final budget = budgetAsync.value;

    // Prefill the field with the saved amount once, so the user sees their
    // current budget instead of a blank field, but can still freely edit it.
    if (!_prefilled && budget != null) {
      _controller.text = budget.amount.toStringAsFixed(2);
      _prefilled = true;
    }

    final used = ref.watch(budgetUsedProvider);
    final progress = ref.watch(budgetProgressProvider) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(ref.tr('my_budget'))),
      body: budgetAsync.hasError
          ? InlineError(
              message: ref.tr('could_not_load_budget'),
              onRetry: () => ref.invalidate(budgetProvider),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SetBudgetCard(controller: _controller, saving: _saving, onSave: _save),
                if (budget != null) ...[
                  const SizedBox(height: 12),
                  _BudgetUsedCard(used: used, total: budget.amount, progress: progress),
                  const SizedBox(height: 12),
                  const _CheaperAlternativesCard(),
                ],
              ],
            ),
    );
  }
}

/// Shared card chrome (spec §2.6: rounded 12dp corners, soft elevation)
/// reused across the three sections on this screen.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _SetBudgetCard extends ConsumerWidget {
  const _SetBudgetCard({required this.controller, required this.saving, required this.onSave});

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(ref.tr('set_budget'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15),
                  decoration: InputDecoration(
                    prefixText: 'RM ',
                    hintText: '0.00',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: ref.tr('save_budget'),
                icon: Icons.save_outlined,
                dense: true,
                expand: false,
                loading: saving,
                onPressed: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetUsedCard extends ConsumerWidget {
  const _BudgetUsedCard({required this.used, required this.total, required this.progress});

  final double used;
  final double total;
  final double progress;

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final exceeded = progress > 1;
    final barColor = exceeded ? AppColors.error : AppColors.primary;
    final percentLabel = '${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.tr('budget_used'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'RM${used.toStringAsFixed(2)}',
                style: TextStyle(color: barColor, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(' / RM${total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.grey, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1).toDouble(),
                    minHeight: 10,
                    backgroundColor: AppColors.surface,
                    color: barColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(percentLabel, style: TextStyle(fontWeight: FontWeight.bold, color: barColor, fontSize: 13)),
            ],
          ),
          if (exceeded) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ref.tr('exceeded_budget_message'),
                    style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Cheaper Alternatives" card (spec §7.7 business rule: "the system
/// surfaces cheaper alternative products"). Hides itself entirely when the
/// cart has no cheaper same-category substitute on record.
class _CheaperAlternativesCard extends ConsumerWidget {
  const _CheaperAlternativesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alternatives = ref.watch(cheaperAlternativesProvider).value ?? const [];
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ref.tr('cheaper_alternatives'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            for (final alt in alternatives.take(5)) ...[
              _AlternativeTile(alternative: alt),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlternativeTile extends ConsumerWidget {
  const _AlternativeTile({required this.alternative});

  final CheaperAlternative alternative;

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/product/${alternative.alternative.itemCode}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.tr('try_alternative').replaceAll('{name}', alternative.alternative.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ref.tr('save_amount').replaceAll('{amount}', alternative.savings.toStringAsFixed(2)),
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
