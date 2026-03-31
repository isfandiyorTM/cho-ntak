import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local_database.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final LocalDatabase _db;
  TransactionRepositoryImpl(this._db);

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    final db = await _db.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByMonth(
      int month, int year) async {
    final maps = await _db.getTransactionsByMonth(month, year);
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final db = await _db.database;
    final maps = await db.query('transactions',
        where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first);
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    await _db.insertTransaction(model.toMap());
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    await _db.updateTransaction(model.toMap());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
  }

  @override
  Future<double> getCarryover(int month, int year) async {
    return _db.getCarryover(month, year);
  }

  @override
  Future<double> getTotalByType(
      TransactionType type, int month, int year) async {
    final typeStr = type == TransactionType.income ? 'income' : 'expense';
    return _db.getTotalByType(typeStr, month, year);
  }
}