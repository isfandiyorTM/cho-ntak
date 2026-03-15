import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/language_provider.dart';
import '../../domain/entities/category_entity.dart';
import '../blocs/category/category_bloc.dart';

// ── 10 categories × 32 emojis = 320 total ───────────────────────────────────
// Tab: [emoji, short label]
const _kCategoryTabs = [
  ['🍕', 'Food'],
  ['🛒', 'Shop'],
  ['🚗', 'Move'],
  ['🏠', 'Home'],
  ['🎮', 'Fun'],
  ['💊', 'Health'],
  ['📚', 'Work'],
  ['💰', 'Money'],
  ['😀', 'Feels'],
  ['🐾', 'Nature'],
];
const _kCategoryEmojis = [
  // 0 Food & drink (32)
  ['🍕','🍔','🌮','🍜','🍣','🥗','🍱','☕','🧃','🍺',
    '🥐','🍰','🍦','🫕','🥩','🍷','🧁','🫔','🥙','🍳',
    '🥞','🧇','🥓','🍖','🌭','🍟','🧆','🥨','🧀','🍿',
    '🍫','🍭'],
  // 1 Shopping & fashion (32)
  ['🛒','👗','👟','💄','👒','🧴','🛍️','💍','👜','🕶️',
    '🧣','⌚','👠','🧤','🪞','🧳','👔','👖','🧥','👒',
    '🎒','💅','🪮','🧢','👒','🪭','💇','🛺','🛼','🎀',
    '🎫','🎟️'],
  // 2 Transport (32)
  ['🚗','🚌','✈️','🚂','🛵','🚢','🚁','🚲','🛺','🏎️',
    '🚕','⛵','🛻','🚐','🛞','⛽','🚑','🚒','🛳️','🚀',
    '🛸','🚤','🛥️','⛴️','🚠','🚟','🚃','🚋','🚝','🚄',
    '🛺','🏍️'],
  // 3 Home & utilities (32)
  ['🏠','💡','💧','🔥','🪴','🛋️','🔧','🪣','📦','🧹',
    '🛁','🪟','🚿','🧺','🪑','🛏️','🚪','🪤','🪜','🔑',
    '🧲','🔌','💡','🕯️','🏮','🧯','🛒','🗑️','🚽','🚰',
    '🪥','🧼'],
  // 4 Entertainment & hobbies (32)
  ['🎮','🎬','🎵','🎤','🎸','🎭','🎨','🎯','🎲','🎻',
    '🎧','📺','🎪','🎠','🎡','🃏','🎹','🥁','🎺','🪘',
    '🎷','🪗','🎙️','🎞️','📽️','🎦','🎰','🎳','🎾','⚽',
    '🏀','🏈'],
  // 5 Health & fitness (32)
  ['💊','🏋️','🧘','🩺','🏃','🚴','🥊','🩹','🫀','🧬',
    '🦷','👓','🩻','🧪','🫁','🩴','🏊','⛹️','🤸','🤼',
    '🤺','🏇','🧗','🤾','🏌️','🧖','💆','💅','🛀','🚵',
    '🤽','🏄'],
  // 6 Work & Education (32)
  ['📚','🎓','💼','🖥️','📝','🔬','📐','🗂️','🏆','🔑',
    '📊','🖊️','📎','🖨️','📡','🔭','🖱️','⌨️','🖲️','💾',
    '💿','📀','📱','☎️','📞','📟','📠','🔋','🔦','🔎',
    '🧮','📋'],
  // 7 Finance & money (32)
  ['💰','💳','🏦','📈','💸','🎁','💎','📉','🤑','🏧',
    '💵','💴','💶','💷','🪙','🏷️','🧾','📑','📃','📄',
    '💹','🔐','🔒','🗝️','💱','💲','💡','📌','📍','🗺️',
    '🗓️','📆'],
  // 8 Faces & emotions (32)
  ['😀','😂','🥰','😎','🤔','😴','🥳','😤','🤩','🫡',
    '😍','🤣','😭','😱','🤯','🥺','😏','🙄','😬','🤫',
    '🤭','🫢','😇','🥹','😈','👻','💀','🤖','👽','🎭',
    '🫠','😵'],
  // 9 Nature & animals (32)
  ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🌴','🌸','⭐',
    '🌊','🌙','☀️','🌈','🍀','🌺','🦁','🐯','🐸','🦋',
    '🌻','🌹','🌷','🌵','🎋','🎍','🍁','🍂','🍃','🌾',
    '🌏','🏔️'],
];

const _kColors = [
  Color(0xFFF0B429), Color(0xFF22C55E), Color(0xFFF87171),
  Color(0xFF60A5FA), Color(0xFFA78BFA), Color(0xFFFB923C),
  Color(0xFF34D399), Color(0xFFF472B6), Color(0xFF4ADE80),
  Color(0xFFFF6B6B), Color(0xFF38BDF8), Color(0xFFFBBF24),
  Color(0xFF818CF8), Color(0xFF6EE7B7), Color(0xFFF9A8D4),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [

              // ── My categories ────────────────────────────
              Row(children: [
                Text(t.customCategories,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.gold, letterSpacing: 0.5)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showCategorySheet(context),
                  icon: const Icon(Icons.add_rounded, color: AppColors.gold, size: 18),
                  label: Text(t.addCategory,
                      style: const TextStyle(color: AppColors.gold)),
                ),
              ]),
              const SizedBox(height: 8),

              if (customs.isEmpty)
                _EmptyCard(isDark: isDark, label: t.addCategory,
                    onTap: () => _showCategorySheet(context))
              else
                ...customs.map((cat) => _CategoryTile(
                  category: cat,
                  isDefault: false,
                  onEdit:   () => _showCategorySheet(context, existing: cat),
                  onDelete: () => _confirmDelete(context, cat, t),
                )),

              const SizedBox(height: 24),

              // ── Default categories ───────────────────────
              Row(children: [
                Text(t.defaultCategories,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.gold, letterSpacing: 0.5)),
              ]),
              const SizedBox(height: 8),

              ...defaults.map((cat) => _CategoryTile(
                category: cat,
                isDefault: true,
                onEdit:   () => _showCategorySheet(context, existing: cat),
                onDelete: () => _confirmDelete(context, cat, t),
              )),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_categories",
        onPressed: () => _showCategorySheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.read<LanguageProvider>().t.addCategory),
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, CategoryEntity cat, t) {
    final isDefault = cat.isDefault;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(isDefault ? t.deleteDefaultTitle : t.deleteCategoryTitle),
        content: Text(isDefault ? t.deleteDefaultBody : t.deleteCategoryBody),
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

class _EmptyCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final VoidCallback onTap;
  const _EmptyCard({required this.isDark, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_rounded, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(
              color: AppColors.gold, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Open the add/edit sheet ───────────────────────────────────────────────────
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

// ── Bottom sheet ─────────────────────────────────────────────────────────────
class _CategorySheet extends StatefulWidget {
  final CategoryEntity? existing;
  const _CategorySheet({this.existing});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _nameCtrl = TextEditingController();
  String _emoji   = '📦';
  Color  _color   = _kColors[0];
  int    _catTab  = 0;  // selected emoji category tab

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
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

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
    final isDefault = widget.existing?.isDefault ?? false;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    // Use DraggableScrollableSheet so the whole thing is scrollable
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand:           false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.mutedDark.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [

                  // Title
                  Row(children: [
                    Text(
                      isEdit
                          ? (isDefault ? t.customiseDefault : t.editCategory)
                          : t.addCategory,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    if (isDefault) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('default',
                            style: TextStyle(fontSize: 11,
                                color: AppColors.amber,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  // Preview
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: _color.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Center(
                          child: Text(_emoji,
                              style: const TextStyle(fontSize: 36))),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: t.categoryName,
                      prefixIcon: const Icon(Icons.edit_rounded,
                          color: AppColors.gold),
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

                  // ── Emoji picker ─────────────────────────────────
                  Text(t.chooseEmoji,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),

                  // Category tab row — pill chips, clearly different from emoji cells
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _kCategoryTabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final active = i == _catTab;
                        final tabEmoji = _kCategoryTabs[i][0];
                        final tabLabel = _kCategoryTabs[i][1];
                        return GestureDetector(
                          onTap: () => setState(() => _catTab = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            // Pill shape with emoji + text label — unmistakably a tab
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              // Active: solid filled pill with accent color
                              // Inactive: dim surface, no border
                              color: active
                                  ? _color
                                  : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(tabEmoji,
                                    style: TextStyle(
                                        fontSize: active ? 18 : 16)),
                                const SizedBox(width: 5),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: active
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: active
                                        ? Colors.black
                                        : (isDark
                                        ? AppColors.mutedDark
                                        : AppColors.mutedLight),
                                  ),
                                  child: Text(tabLabel),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Fixed-height emoji grid for current tab — scrollable
                  SizedBox(
                    // 4 rows × 44px + 3 gaps × 6px = 194px — exactly fills with no empty space
                    height: 194,
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount: _kCategoryEmojis[_catTab].length,
                      itemBuilder: (_, i) {
                        final e        = _kCategoryEmojis[_catTab][i];
                        final selected = e == _emoji;
                        return GestureDetector(
                          onTap: () => setState(() => _emoji = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _color.withValues(alpha: 0.2)
                                  : (isDark
                                  ? AppColors.cardDark
                                  : AppColors.bgLight),
                              borderRadius: BorderRadius.circular(10),
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
                    children: _kColors.map((col) {
                      final selected = col.value == _color.value;
                      return GestureDetector(
                        onTap: () => setState(() => _color = col),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(
                                color: col.withValues(alpha: 0.6),
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

                  // Save
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
          ],
        ),
      ),
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────
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
        color:  isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: category.emoji != null
                ? Text(category.emoji!, style: const TextStyle(fontSize: 22))
                : Icon(category.icon, color: category.color, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(category.name,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        // Edit
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded,
              color: AppColors.gold, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        // Delete
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.expense, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ]),
    );
  }
}