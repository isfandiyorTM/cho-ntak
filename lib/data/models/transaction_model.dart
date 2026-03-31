import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.type,
    required super.categoryId,
    required super.date,
    super.note,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id:         map['id'] as String,
      title:      map['title'] as String,
      amount:     (map['amount'] as num).toDouble(),
      type:       map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: map['category_id'] as String,
      date:       DateTime.parse(map['date'] as String),
      note:       map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':          id,
    'title':       title,
    'amount':      amount,
    'type':        type == TransactionType.income ? 'income' : 'expense',
    'category_id': categoryId,
    'date':        date.toIso8601String(),
    'note':        note,
  };

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id:         entity.id,
      title:      entity.title,
      amount:     entity.amount,
      type:       entity.type,
      categoryId: entity.categoryId,
      date:       entity.date,
      note:       entity.note,
    );
  }
}