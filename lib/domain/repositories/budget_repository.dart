import '../entities/budget_entity.dart';

abstract class BudgetRepository {
  Future<BudgetEntity?> getBudgetByMonth(int month, int year);
  Future<void> setBudget(BudgetEntity budget);
  Future<void> updateSpent(int month, int year, double spent);
  Future<void> deleteBudget(int month, int year);
}