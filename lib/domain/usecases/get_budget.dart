import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class GetBudget {
  final BudgetRepository repository;
  GetBudget(this.repository);

  Future<BudgetEntity?> call(int month, int year) =>
      repository.getBudgetByMonth(month, year);
}