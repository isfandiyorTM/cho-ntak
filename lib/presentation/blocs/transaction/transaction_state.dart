part of 'transaction_bloc.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();
  @override List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final double totalIncome;
  final double totalExpense;
  final double carryover;   // net balance carried from previous months
  final int month;
  final int year;

  const TransactionLoaded({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.carryover,
    required this.month,
    required this.year,
  });

  // Balance = carryover from previous months + this month's income - this month's expense
  double get balance => carryover + totalIncome - totalExpense;

  // Only this month's net (without carryover)
  double get monthlyNet => totalIncome - totalExpense;

  @override
  List<Object?> get props =>
      [transactions, totalIncome, totalExpense, carryover, month, year];
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
  @override List<Object?> get props => [message];
}