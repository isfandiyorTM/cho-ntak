part of 'budget_bloc.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();
  @override List<Object?> get props => [];
}

class LoadBudget extends BudgetEvent {
  final int month;
  final int year;
  const LoadBudget({required this.month, required this.year});
  @override List<Object?> get props => [month, year];
}

class SetBudgetEvent extends BudgetEvent {
  final double limit;
  final int month;
  final int year;
  const SetBudgetEvent({required this.limit, required this.month, required this.year});
  @override List<Object?> get props => [limit, month, year];
}

class UpdateBudgetSpent extends BudgetEvent {
  final double spent;
  final int month;
  final int year;
  const UpdateBudgetSpent({required this.spent, required this.month, required this.year});
  @override List<Object?> get props => [spent, month, year];
}

class DeleteBudgetEvent extends BudgetEvent {
  final int month;
  final int year;
  const DeleteBudgetEvent({required this.month, required this.year});
  @override List<Object?> get props => [month, year];
}