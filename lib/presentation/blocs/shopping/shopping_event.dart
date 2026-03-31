part of 'shopping_bloc.dart';

abstract class ShoppingEvent extends Equatable {
  const ShoppingEvent();
  @override List<Object?> get props => [];
}

class LoadShoppingLists  extends ShoppingEvent {}

class CreateShoppingList extends ShoppingEvent {
  final String title, emoji;
  const CreateShoppingList({required this.title, required this.emoji});
  @override List<Object?> get props => [title, emoji];
}

class UpdateShoppingList extends ShoppingEvent {
  final String id, title, emoji;
  const UpdateShoppingList({required this.id, required this.title,
    required this.emoji});
  @override List<Object?> get props => [id, title, emoji];
}

class DeleteShoppingList extends ShoppingEvent {
  final String id;
  const DeleteShoppingList(this.id);
  @override List<Object?> get props => [id];
}

class AddShoppingItem extends ShoppingEvent {
  final String  listId, name;
  final String? quantity;
  final int     sortOrder;
  const AddShoppingItem({required this.listId, required this.name,
    this.quantity, this.sortOrder = 0});
  @override List<Object?> get props => [listId, name, quantity];
}

class UpdateShoppingItem extends ShoppingEvent {
  final String  id, name;
  final String? quantity;
  const UpdateShoppingItem({required this.id, required this.name,
    this.quantity});
  @override List<Object?> get props => [id, name, quantity];
}

class ToggleShoppingItem extends ShoppingEvent {
  final String itemId, listId;
  const ToggleShoppingItem({required this.itemId, required this.listId});
  @override List<Object?> get props => [itemId, listId];
}

class DeleteShoppingItem extends ShoppingEvent {
  final String itemId;
  const DeleteShoppingItem(this.itemId);
  @override List<Object?> get props => [itemId];
}

class ClearCheckedItems extends ShoppingEvent {
  final String listId;
  const ClearCheckedItems(this.listId);
  @override List<Object?> get props => [listId];
}