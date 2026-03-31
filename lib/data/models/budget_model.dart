import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.limit,
    required super.spent,
    required super.month,
    required super.year,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id:    map['id'] as String,
      limit: (map['budget_limit'] as num).toDouble(),
      spent: (map['spent'] as num).toDouble(),
      month: map['month'] as int,
      year:  map['year'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':           id,
    'budget_limit': limit,
    'spent':        spent,
    'month':        month,
    'year':         year,
  };

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id:    entity.id,
      limit: entity.limit,
      spent: entity.spent,
      month: entity.month,
      year:  entity.year,
    );
  }
}