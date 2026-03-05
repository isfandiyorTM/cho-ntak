import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class GetTransactions {
  final TransactionRepository repository;
  GetTransactions(this.repository);

  Future<List<TransactionEntity>> call(int month, int year) =>
      repository.getTransactionsByMonth(month, year);
}