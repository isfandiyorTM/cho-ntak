part of 'category_budget_bloc.dart';

abstract class CategoryBudgetEvent extends Equatable {
  const CategoryBudgetEvent();
  @override List<Object?> get props => [];
}

class LoadCategoryBudgets extends CategoryBudgetEvent {
  final int month, year;
  const LoadCategoryBudgets({required this.month, required this.year});
  @override List<Object?> get props => [month, year];
}

class SetCategoryBudget extends CategoryBudgetEvent {
  final String categoryId;
  final double limit, spent;
  final int    month, year;
  const SetCategoryBudget({
    required this.categoryId, required this.limit,
    required this.spent,      required this.month,
    required this.year,
  });
  @override List<Object?> get props => [categoryId, limit, month, year];
}

class DeleteCategoryBudget extends CategoryBudgetEvent {
  final String categoryId;
  final int    month, year;
  const DeleteCategoryBudget({
    required this.categoryId, required this.month, required this.year});
  @override List<Object?> get props => [categoryId, month, year];
}

class RefreshCategoryBudgetSpent extends CategoryBudgetEvent {
  final int                month, year;
  final Map<String,double> spentByCategory;
  const RefreshCategoryBudgetSpent({
    required this.month, required this.year, required this.spentByCategory});
  @override List<Object?> get props => [month, year, spentByCategory];
}