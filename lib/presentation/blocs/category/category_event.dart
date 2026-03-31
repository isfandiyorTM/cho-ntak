part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override List<Object?> get props => [];
}

class LoadCategories                              extends CategoryEvent {}
class AddCategoryEvent    extends CategoryEvent {
  final CategoryEntity category;
  const AddCategoryEvent(this.category);
  @override List<Object?> get props => [category];
}
class UpdateCategoryEvent extends CategoryEvent {
  final CategoryEntity category;
  const UpdateCategoryEvent(this.category);
  @override List<Object?> get props => [category];
}
class DeleteCategoryEvent extends CategoryEvent {
  final String id;
  const DeleteCategoryEvent(this.id);
  @override List<Object?> get props => [id];
}