part of 'category_budget_bloc.dart';

abstract class CategoryBudgetState extends Equatable {
  const CategoryBudgetState();
  @override List<Object?> get props => [];
}

class CategoryBudgetInitial extends CategoryBudgetState {}
class CategoryBudgetLoading extends CategoryBudgetState {}

class CategoryBudgetLoaded extends CategoryBudgetState {
  final List<CategoryBudgetEntity> budgets;
  final int month, year;
  const CategoryBudgetLoaded({
    required this.budgets, required this.month, required this.year});
  @override List<Object?> get props => [budgets, month, year];
}

class CategoryBudgetError extends CategoryBudgetState {
  final String message;
  const CategoryBudgetError(this.message);
  @override List<Object?> get props => [message];
}