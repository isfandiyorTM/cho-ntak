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
  }

  Future<void> _onLoad(
      LoadCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    try {
      final categories = await _repository.getAllCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}