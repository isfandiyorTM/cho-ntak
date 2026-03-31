import 'package:equatable/equatable.dart';

class CategoryBudgetEntity extends Equatable {
  final String id;          // same as category id
  final double limit;
  final double spent;
  final int    month;
  final int    year;

  const CategoryBudgetEntity({
    required this.id,
    required this.limit,
    required this.spent,
    required this.month,
    required this.year,
  });

  double get remaining  => limit - spent;
  double get percentage => limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
  bool   get isOver     => spent > limit;
  bool   get isNear     => percentage >= 0.8 && !isOver;

  @override
  List<Object?> get props => [id, limit, spent, month, year];
}