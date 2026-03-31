part of 'shopping_bloc.dart';

abstract class ShoppingState extends Equatable {
  const ShoppingState();
  @override List<Object?> get props => [];
}

class ShoppingInitial extends ShoppingState {}
class ShoppingLoading extends ShoppingState {}

class ShoppingLoaded extends ShoppingState {
  final List<ShoppingListEntity> lists;
  const ShoppingLoaded(this.lists);
  @override List<Object?> get props => [lists];
}

class ShoppingError extends ShoppingState {
  final String message;
  const ShoppingError(this.message);
  @override List<Object?> get props => [message];
}