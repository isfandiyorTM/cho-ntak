import 'package:equatable/equatable.dart';

class ShoppingListEntity extends Equatable {
  final String  id;
  final String  title;
  final String  emoji;
  final DateTime createdAt;
  final List<ShoppingItemEntity> items;

  const ShoppingListEntity({
    required this.id,
    required this.title,
    required this.emoji,
    required this.createdAt,
    this.items = const [],
  });

  int get totalItems    => items.length;
  int get checkedItems  => items.where((i) => i.isChecked).length;
  bool get isAllChecked => items.isNotEmpty && checkedItems == totalItems;
  double get progress   => items.isEmpty ? 0 : checkedItems / totalItems;

  ShoppingListEntity copyWith({
    String? title, String? emoji,
    List<ShoppingItemEntity>? items,
  }) => ShoppingListEntity(
    id: id, createdAt: createdAt,
    title:  title  ?? this.title,
    emoji:  emoji  ?? this.emoji,
    items:  items  ?? this.items,
  );

  @override
  List<Object?> get props => [id, title, emoji, createdAt, items];
}

class ShoppingItemEntity extends Equatable {
  final String  id;
  final String  listId;
  final String  name;
  final String? quantity;
  final bool    isChecked;
  final int     sortOrder;

  const ShoppingItemEntity({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity,
    this.isChecked = false,
    this.sortOrder = 0,
  });

  ShoppingItemEntity copyWith({
    String? name, String? quantity, bool? isChecked}) =>
      ShoppingItemEntity(
        id: id, listId: listId, sortOrder: sortOrder,
        name:      name      ?? this.name,
        quantity:  quantity  ?? this.quantity,
        isChecked: isChecked ?? this.isChecked,
      );

  @override
  List<Object?> get props => [id, listId, name, quantity, isChecked, sortOrder];
}