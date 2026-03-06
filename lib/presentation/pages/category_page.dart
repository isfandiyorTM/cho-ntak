import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/language_provider.dart';
import '../../domain/entities/category_entity.dart';
import '../blocs/category/category_bloc.dart';

const _kEmojis = [
  '🍕','🍔','🥗','☕','🍜','🛒','👗','👟','💄','🎮',
  '📱','💻','🚗','🚌','✈️','🏠','💡','💧','🎵','🎬',
  '📚','🎓','💊','🏋️','⚽','🐶','🌴','🎁','💍','💰',
  '🏦','💳','📦','🔧','🎨','🌟','🔑','🍷','🎂','🧸',
];

const _kColors = [
  Color(0xFFFFD700), Color(0xFF4CAF50), Color(0xFFF44336),
  Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFFFF9800),
  Color(0xFF00BCD4), Color(0xFFE91E63), Color(0xFF8BC34A),
  Color(0xFF607D8B), Color(0xFFFF5722), Color(0xFF3F51B5),
];

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t      = context.watch<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.categories,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading || state is CategoryInitial) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (state is! CategoryLoaded) {
            return const Center(child: Text('Kategoriyalar yuklanmadi'));
          }

          final defaults = state.categories.where((c) => c.isDefault).toList();
          final customs  = state.categories.where((c) => !c.isDefault).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // ── Custom categories first ──────────────────
              Row(
                children: [
                  Text(t.customCategories,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 0.5)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showCategorySheet(context),
                    icon: const Icon(Icons.add_rounded,
                        color: AppColors.gold, size: 18),
                    label: Text(t.addCategory,
                        style: const TextStyle(color: AppColors.gold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (customs.isEmpty)
                GestureDetector(
                  onTap: () => _showCategorySheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Text(t.addCategory,
                            style: const TextStyle(color: AppColors.gold,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              else
                ...customs.map((cat) => _CategoryTile(
                  category:  cat,
                  isDefault: false,
                  onEdit:    () => _showCategorySheet(context, existing: cat),
                  onDelete:  () => _confirmDelete(context, cat, t),
                )),

              const SizedBox(height: 24),

              // ── Default categories ───────────────────────
              Text(t.defaultCategories,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),

              ...defaults.map((cat) => _CategoryTile(
                category:  cat,
                isDefault: true,
                onEdit:    null,
                onDelete:  null,
              )),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.read<LanguageProvider>().t.addCategory),
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, CategoryEntity cat, t) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(t.deleteTitle),
        content: Text('"${cat.name}" ${t.deleteBody}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<CategoryBloc>().add(DeleteCategoryEvent(cat.id));
            },
            child: Text(t.delete,
                style: const TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

void _showCategorySheet(BuildContext context, {CategoryEntity? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<CategoryBloc>(),
      child: _CategorySheet(existing: existing),
    ),
  );
}

class _CategorySheet extends StatefulWidget {
  final CategoryEntity? existing;
  const _CategorySheet({this.existing});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _nameCtrl = TextEditingController();
  String _emoji = '📦';
  Color  _color = _kColors[0];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _emoji         = widget.existing!.emoji ?? '📦';
      _color         = widget.existing!.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final bloc = context.read<CategoryBloc>();
    if (widget.existing == null) {
      bloc.add(AddCategoryEvent(CategoryEntity(
        id:    const Uuid().v4(),
        name:  name,
        icon:  Icons.label_rounded,
        color: _color,
        emoji: _emoji,
      )));
    } else {
      bloc.add(UpdateCategoryEvent(widget.existing!.copyWith(
        name:  name,
        emoji: _emoji,
        color: _color,
      )));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t      = context.read<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(isEdit ? t.editCategory : t.addCategory,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // Live preview
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _color.withOpacity(0.5), width: 2),
                ),
                child: Center(
                    child: Text(_emoji,
                        style: const TextStyle(fontSize: 36))),
              ),
            ),
            const SizedBox(height: 20),

            // Name input
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: t.categoryName,
                prefixIcon:
                const Icon(Icons.edit_rounded, color: AppColors.gold),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: AppColors.gold, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Emoji grid
            Text(t.chooseEmoji,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 168,
              child: GridView.builder(
                physics: const ClampingScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: _kEmojis.length,
                itemBuilder: (_, i) {
                  final e        = _kEmojis[i];
                  final selected = e == _emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: selected
                            ? _color.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? _color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                          child: Text(e,
                              style: const TextStyle(fontSize: 20))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Color picker
            Text(t.chooseColor,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _kColors.map((c) {
                final selected = c.value == _color.value;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(
                          color: c.withOpacity(0.6),
                          blurRadius: 8, spreadRadius: 2)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(t.save,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryEntity category;
  final bool           isDefault;
  final VoidCallback?  onEdit;
  final VoidCallback?  onDelete;
  const _CategoryTile({
    required this.category,
    required this.isDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Icon / emoji
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: category.emoji != null
                  ? Text(category.emoji!,
                  style: const TextStyle(fontSize: 20))
                  : Icon(category.icon,
                  color: category.color, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(category.name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('default',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey[500])),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded,
                      color: AppColors.gold, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.expense, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
              ],
            ),
        ],
      ),
    );
  }
}