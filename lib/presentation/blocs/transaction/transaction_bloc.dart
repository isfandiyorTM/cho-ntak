import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/get_transactions.dart';
import '../../../domain/usecases/add_transaction.dart';
import '../../../domain/usecases/update_transaction.dart';
import '../../../domain/usecases/delete_transaction.dart';
import '../../../domain/repositories/transaction_repository.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactions _getTransactions;
  final AddTransaction _addTransaction;
  final UpdateTransaction _updateTransaction;
  final DeleteTransaction _deleteTransaction;
  final TransactionRepository _repository;

  TransactionBloc({
    required GetTransactions getTransactions,
    required AddTransaction addTransaction,
    required UpdateTransaction updateTransaction,
    required DeleteTransaction deleteTransaction,
    required TransactionRepository repository,
  })  : _getTransactions = getTransactions,
        _addTransaction = addTransaction,
        _updateTransaction = updateTransaction,
        _deleteTransaction = deleteTransaction,
        _repository = repository,
        super(TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransactionEvent>(_onAdd);
    on<UpdateTransactionEvent>(_onUpdate);
    on<DeleteTransactionEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadTransactions event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      final transactions =
      await _getTransactions(event.month, event.year);
      final income = await _repository.getTotalByType(
          TransactionType.income, event.month, event.year);
      final expense = await _repository.getTotalByType(
          TransactionType.expense, event.month, event.year);
      // Fetch carryover: net balance from all months before this one
      final carryover =
      await _repository.getCarryover(event.month, event.year);
      emit(TransactionLoaded(
        transactions: transactions,
        totalIncome: income,
        totalExpense: expense,
        carryover: carryover,
        month: event.month,
        year: event.year,
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onAdd(
      AddTransactionEvent event, Emitter<TransactionState> emit) async {
    final current = state;
    try {
      await _addTransaction(event.transaction);
      if (current is TransactionLoaded) {
        add(LoadTransactions(month: current.month, year: current.year));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      UpdateTransactionEvent event, Emitter<TransactionState> emit) async {
    final current = state;
    try {
      await _updateTransaction(event.transaction);
      if (current is TransactionLoaded) {
        add(LoadTransactions(month: current.month, year: current.year));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDelete(
      DeleteTransactionEvent event, Emitter<TransactionState> emit) async {
    try {
      await _deleteTransaction(event.id);
      add(LoadTransactions(month: event.month, year: event.year));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}