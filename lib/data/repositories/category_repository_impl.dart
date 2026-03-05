import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/translations.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {

  static List<CategoryEntity> getDefaults(Translations t) => [
    CategoryEntity(id: 'food',      name: t.catFood,      icon: Iconsax.cup,         color: AppColors.categoryColors[0],  isDefault: true),
    CategoryEntity(id: 'transport', name: t.catTransport, icon: Iconsax.car,          color: AppColors.categoryColors[1],  isDefault: true),
    CategoryEntity(id: 'shopping',  name: t.catShopping,  icon: Iconsax.bag,          color: AppColors.categoryColors[2],  isDefault: true),
    CategoryEntity(id: 'health',    name: t.catHealth,    icon: Iconsax.health,       color: AppColors.categoryColors[3],  isDefault: true),
    CategoryEntity(id: 'salary',    name: t.catSalary,    icon: Iconsax.money,        color: AppColors.categoryColors[4],  isDefault: true),
    CategoryEntity(id: 'freelance', name: t.catFreelance, icon: Iconsax.briefcase,    color: AppColors.categoryColors[5],  isDefault: true),
    CategoryEntity(id: 'education', name: t.catEducation, icon: Iconsax.book,         color: AppColors.categoryColors[6],  isDefault: true),
    CategoryEntity(id: 'bills',     name: t.catBills,     icon: Iconsax.receipt,      color: AppColors.categoryColors[7],  isDefault: true),
    CategoryEntity(id: 'sports',    name: t.catSports,    icon: Iconsax.activity,     color: AppColors.categoryColors[8],  isDefault: true),
    CategoryEntity(id: 'family',    name: t.catFamily,    icon: Iconsax.people,       color: AppColors.categoryColors[9],  isDefault: true),
    CategoryEntity(id: 'other',     name: t.catOther,     icon: Iconsax.more_circle,  color: const Color(0xFF9E9E9E),      isDefault: true),
  ];

  final List<CategoryEntity> _custom = [];
  Translations _t = Translations(AppLanguage.uz);

  void updateLanguage(Translations t) {
    _t = t;
  }

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    return [...getDefaults(_t), ..._custom];
  }

  @override
  Future<void> addCategory(CategoryEntity category) async {
    _custom.add(category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    _custom.removeWhere((c) => c.id == id);
  }
}