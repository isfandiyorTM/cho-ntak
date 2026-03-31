import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/datasources/local_database.dart';
import '../../../domain/entities/category_budget_entity.dart';

part 'category_budget_event.dart';
part 'category_budget_state.dart';

class CategoryBudgetBloc
    extends Bloc<CategoryBudgetEvent, CategoryBudgetState> {
  final LocalDatabase _db;

  CategoryBudgetBloc(this._db) : super(CategoryBudgetInitial()) {
    on<LoadCategoryBudgets>(_onLoad);
    on<SetCategoryBudget>(_onSet);
    on<DeleteCategoryBudget>(_onDelete);
    on<RefreshCategoryBudgetSpent>(_onRefresh);
  }

  Future<void> _onLoad(
      LoadCategoryBudgets e, Emitter<CategoryBudgetState> emit) async {
    emit(CategoryBudgetLoading());
    try {
      final rows = await _db.getCategoryBudgetsByMonth(e.month, e.year);
      final budgets = rows.map((r) => CategoryBudgetEntity(
        id:    r['id'] as String,
        limit: (r['budget_limit'] as num).toDouble(),
        spent: (r['spent'] as num).toDouble(),
        month: r['month'] as int,
        year:  r['year']  as int,
      )).toList();
      emit(CategoryBudgetLoaded(budgets: budgets, month: e.month, year: e.year));
    } catch (err) {
      emit(CategoryBudgetError(err.toString()));
    }
  }

  Future<void> _onSet(
      SetCategoryBudget e, Emitter<CategoryBudgetState> emit) async {
    try {
      await _db.upsertCategoryBudget({
        'id':           e.categoryId,
        'budget_limit': e.limit,
        'spent':        e.spent,
        'month':        e.month,
        'year':         e.year,
      });
      add(LoadCategoryBudgets(month: e.month, year: e.year));
    } catch (err) {
      emit(CategoryBudgetError(err.toString()));
    }
  }

  Future<void> _onDelete(
      DeleteCategoryBudget e, Emitter<CategoryBudgetState> emit) async {
    try {
      await _db.deleteCategoryBudget(e.categoryId, e.month, e.year);
      add(LoadCategoryBudgets(month: e.month, year: e.year));
    } catch (err) {
      emit(CategoryBudgetError(err.toString()));
    }
  }

  Future<void> _onRefresh(
      RefreshCategoryBudgetSpent e,
      Emitter<CategoryBudgetState> emit) async {
    // Recalculate spent for all category budgets this month
    try {
      final rows = await _db.getCategoryBudgetsByMonth(e.month, e.year);
      for (final row in rows) {
        final catId = row['id'] as String;
        final spent = e.spentByCategory[catId] ?? 0.0;
        await _db.updateCategoryBudgetSpent(catId, e.month, e.year, spent);
      }
      add(LoadCategoryBudgets(month: e.month, year: e.year));
    } catch (err) {
      emit(CategoryBudgetError(err.toString()));
    }
  }
}