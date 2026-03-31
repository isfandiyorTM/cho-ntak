import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/translations.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local_database.dart';

class CategoryRepositoryImpl implements CategoryRepository {

  // ── Hard-coded default definitions (fallback / structure) ────────────────
  static List<CategoryEntity> getDefaults(Translations t) => [
    CategoryEntity(id: 'food',      name: t.catFood,      icon: Iconsax.cup,        color: AppColors.categoryColors[0],  isDefault: true),
    CategoryEntity(id: 'transport', name: t.catTransport, icon: Iconsax.car,         color: AppColors.categoryColors[1],  isDefault: true),
    CategoryEntity(id: 'shopping',  name: t.catShopping,  icon: Iconsax.bag,         color: AppColors.categoryColors[2],  isDefault: true),
    CategoryEntity(id: 'health',    name: t.catHealth,    icon: Iconsax.health,      color: AppColors.categoryColors[3],  isDefault: true),
    CategoryEntity(id: 'salary',    name: t.catSalary,    icon: Iconsax.money,       color: AppColors.categoryColors[4],  isDefault: true),
    CategoryEntity(id: 'freelance', name: t.catFreelance, icon: Iconsax.briefcase,   color: AppColors.categoryColors[5],  isDefault: true),
    CategoryEntity(id: 'education', name: t.catEducation, icon: Iconsax.book,        color: AppColors.categoryColors[6],  isDefault: true),
    CategoryEntity(id: 'bills',     name: t.catBills,     icon: Iconsax.receipt,     color: AppColors.categoryColors[7],  isDefault: true),
    CategoryEntity(id: 'sports',    name: t.catSports,    icon: Iconsax.activity,    color: AppColors.categoryColors[8],  isDefault: true),
    CategoryEntity(id: 'family',    name: t.catFamily,    icon: Iconsax.people,      color: AppColors.categoryColors[9],  isDefault: true),
    CategoryEntity(id: 'other',     name: t.catOther,     icon: Iconsax.more_circle, color: const Color(0xFF9E9E9E),      isDefault: true),
  ];

  Translations _t = Translations(AppLanguage.uz);
  void updateLanguage(Translations t) => _t = t;

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    final rows   = await LocalDatabase.instance.getCustomCategories();
    final hidden = await LocalDatabase.instance.getHiddenCategoryIds();

    final Map<String, Map<String, dynamic>> rowById = {
      for (final r in rows) r['id'] as String: r,
    };

    final defaultIds = {'food','transport','shopping','health','salary',
      'freelance','education','bills','sports','family','other'};

    // Defaults — skip hidden, apply overrides
    final defaults = getDefaults(_t)
        .where((def) => !hidden.contains(def.id))
        .map((def) {
      final override = rowById[def.id];
      if (override != null) {
        return CategoryEntity(
          id:        def.id,
          name:      override['name'] as String,
          icon:      def.icon,
          color:     Color(override['color'] as int),
          isDefault: true,
          emoji:     override['emoji'] as String?,
        );
      }
      return def;
    }).toList();

    // Custom categories (non-default ids only)
    final customs = rows
        .where((r) => !defaultIds.contains(r['id'] as String))
        .map((row) => CategoryEntity(
      id:        row['id'] as String,
      name:      row['name'] as String,
      icon:      Icons.label_rounded,
      color:     Color(row['color'] as int),
      isDefault: false,
      emoji:     row['emoji'] as String?,
    ))
        .toList();

    return [...defaults, ...customs];
  }

  @override
  Future<void> addCategory(CategoryEntity category) async {
    await LocalDatabase.instance.insertCustomCategory({
      'id':    category.id,
      'name':  category.name,
      'emoji': category.emoji ?? '📦',
      'color': category.color.toARGB32(),
      'type':  'both',
    });
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    // Works for both custom and default overrides — upsert by id
    await LocalDatabase.instance.upsertCustomCategory({
      'id':    category.id,
      'name':  category.name,
      'emoji': category.emoji ?? '📦',
      'color': category.color.toARGB32(),
      'type':  'both',
    });
  }

  @override
  Future<void> deleteCategory(String id) async {
    final defaultIds = {'food','transport','shopping','health','salary',
      'freelance','education','bills','sports','family','other'};
    if (defaultIds.contains(id)) {
      // Hide the default — also remove any custom override for it
      await LocalDatabase.instance.hideCategory(id);
      await LocalDatabase.instance.deleteCustomCategory(id);
    } else {
      await LocalDatabase.instance.deleteCustomCategory(id);
    }
  }

  Future<void> resetAllToDefaults() async {
    await LocalDatabase.instance.unhideAllCategories();
  }
}