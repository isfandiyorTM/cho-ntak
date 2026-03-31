import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/usecases/get_budget.dart';
import '../../../domain/usecases/set_budget.dart';
import '../../../domain/repositories/budget_repository.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final GetBudget _getBudget;
  final SetBudget _setBudget;
  final BudgetRepository _repository;

  BudgetBloc({
    required GetBudget getBudget,
    required SetBudget setBudget,
    required BudgetRepository repository,
  })  : _getBudget = getBudget,
        _setBudget = setBudget,
        _repository = repository,
        super(BudgetInitial()) {
    on<LoadBudget>(_onLoad);
    on<SetBudgetEvent>(_onSet);
    on<UpdateBudgetSpent>(_onUpdateSpent);
    on<DeleteBudgetEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadBudget event, Emitter<BudgetState> emit) async {
    emit(BudgetLoading());
    try {
      final budget = await _getBudget(event.month, event.year);
      if (budget == null) {
        emit(BudgetNotSet());
      } else {
        emit(BudgetLoaded(budget));
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onSet(
      SetBudgetEvent event, Emitter<BudgetState> emit) async {
    try {
      final budget = BudgetEntity(
        id:    const Uuid().v4(),
        limit: event.limit,
        spent: 0,
        month: event.month,
        year:  event.year,
      );
      await _setBudget(budget);
      add(LoadBudget(month: event.month, year: event.year));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onUpdateSpent(
      UpdateBudgetSpent event, Emitter<BudgetState> emit) async {
    try {
      await _repository.updateSpent(event.month, event.year, event.spent);
      add(LoadBudget(month: event.month, year: event.year));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onDelete(
      DeleteBudgetEvent event, Emitter<BudgetState> emit) async {
    try {
      await _repository.deleteBudget(event.month, event.year);
      emit(BudgetNotSet());
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }
}