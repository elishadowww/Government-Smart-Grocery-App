import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/budget_provider.dart';

/// Dashboard budget summary (spec Fig 7.1.1). Per the §7.7 business rule
/// ("The Dashboard Budget Card appears only once a budget has been
/// created"), this renders nothing until the user has set a budget on the
/// Budget screen (Module 8).
class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider).value;
    if (budget == null) return const SizedBox.shrink();

    final used = ref.watch(budgetUsedProvider);
    final progress = ref.watch(budgetProgressProvider) ?? 0;
    final exceeded = progress > 1;
    final barColor = exceeded ? AppColors.error : AppColors.primary;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/budget'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: barColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Budget: RM${used.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: barColor),
                        ),
                        Text(
                          ' / RM${budget.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1).toDouble(),
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
