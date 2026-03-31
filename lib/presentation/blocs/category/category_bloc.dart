import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/repositories/category_repository.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _repository;

  CategoryBloc({required CategoryRepository repository})
      : _repository = repository,
        super(CategoryInitial()) {
    on<LoadCategories>(_onLoad);
    on<AddCategoryEvent>(_onAdd);
    on<UpdateCategoryEvent>(_onUpdate);
    on<DeleteCategoryEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadCategories e, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    try {
      emit(CategoryLoaded(await _repository.getAllCategories()));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onAdd(AddCategoryEvent e, Emitter<CategoryState> emit) async {
    await _repository.addCategory(e.category);
    add(LoadCategories());
  }

  Future<void> _onUpdate(UpdateCategoryEvent e, Emitter<CategoryState> emit) async {
    await _repository.updateCategory(e.category);
    add(LoadCategories());
  }

  Future<void> _onDelete(DeleteCategoryEvent e, Emitter<CategoryState> emit) async {
    await _repository.deleteCategory(e.id);
    add(LoadCategories());
  }
}