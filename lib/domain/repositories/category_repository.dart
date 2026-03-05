import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getAllCategories();
  Future<void> addCategory(CategoryEntity category);
  Future<void> deleteCategory(String id);
}