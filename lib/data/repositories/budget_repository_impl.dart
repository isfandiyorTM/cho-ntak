import 'package:uuid/uuid.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/local_database.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final LocalDatabase _db;
  BudgetRepositoryImpl(this._db);

  @override
  Future<BudgetEntity?> getBudgetByMonth(int month, int year) async {
    final map = await _db.getBudgetByMonth(month, year);
    if (map == null) return null;

    // Always calculate spent from REAL transactions — never trust stored value
    final realSpent = await _db.getTotalByType('expense', month, year);

    final model = BudgetModel.fromMap(map);
    return BudgetEntity(
      id:    model.id,
      limit: model.limit,
      spent: realSpent,   // ← live value from transactions
      month: model.month,
      year:  model.year,
    );
  }

  @override
  Future<void> setBudget(BudgetEntity budget) async {
    final model = BudgetModel.fromEntity(budget);
    await _db.upsertBudget(model.toMap());
  }

  @override
  Future<void> updateSpent(int month, int year, double spent) async {
    await _db.updateBudgetSpent(month, year, spent);
  }

  @override
  Future<void> deleteBudget(int month, int year) async {
    await _db.deleteBudget(month, year);
  }
}