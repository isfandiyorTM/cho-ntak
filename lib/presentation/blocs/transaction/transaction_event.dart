part of 'transaction_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final int month;
  final int year;
  const LoadTransactions({required this.month, required this.year});
  @override List<Object?> get props => [month, year];
}

class AddTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;
  const AddTransactionEvent(this.transaction);
  @override List<Object?> get props => [transaction];
}

class UpdateTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;
  const UpdateTransactionEvent(this.transaction);
  @override List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String id;
  final int month;
  final int year;
  const DeleteTransactionEvent(this.id, {required this.month, required this.year});
  @override List<Object?> get props => [id];
}