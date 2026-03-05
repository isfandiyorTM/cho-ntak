import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getAllTransactions();
  Future<List<TransactionEntity>> getTransactionsByMonth(int month, int year);
  Future<TransactionEntity?> getTransactionById(String id);
  Future<void> addTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
  Future<double> getCarryover(int month, int year);
  Future<double> getTotalByType(TransactionType type, int month, int year);
}