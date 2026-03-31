import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  final String id;
  final double limit;
  final double spent;
  final int month;
  final int year;

  const BudgetEntity({
    required this.id,
    required this.limit,
    required this.spent,
    required this.month,
    required this.year,
  });

  double get remaining => limit - spent;
  double get percentage => limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => spent > limit;
  bool get isNearLimit => percentage >= 0.8 && !isOverBudget;

  @override
  List<Object?> get props => [id, limit, spent, month, year];
}