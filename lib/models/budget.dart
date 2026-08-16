import 'package:equatable/equatable.dart';

import '../core/constants/user_data_constants.dart';

/// A user's shopping budget (spec §7.7 FR7). One row per uid — setting a
/// new budget overwrites the previous one rather than keeping history.
class Budget extends Equatable {
  const Budget({
    required this.uid,
    required this.amount,
    required this.updatedAt,
  });

  final String uid;
  final double amount;
  final DateTime updatedAt;

  factory Budget.fromMap(Map<String, Object?> row) {
    return Budget(
      uid: row[BudgetColumns.uid] as String? ?? '',
      amount: (row[BudgetColumns.amount] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(row[BudgetColumns.updatedAt] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toMap() {
    return {
      BudgetColumns.uid: uid,
      BudgetColumns.amount: amount,
      BudgetColumns.updatedAt: updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [uid, amount, updatedAt];
}
