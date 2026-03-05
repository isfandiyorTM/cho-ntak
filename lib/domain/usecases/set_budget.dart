import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class SetBudget {
  final BudgetRepository repository;
  SetBudget(this.repository);

  Future<void> call(BudgetEntity budget) => repository.setBudget(budget);
}