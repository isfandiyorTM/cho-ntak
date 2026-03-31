import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/shopping_entity.dart';
import '../blocs/shopping/shopping_bloc.dart';

const _listEmojis = [
  '🛒','🛍️','🥦','🥩','🧴','💊','🔧','📚','🎁','👗',
  '🍎','🧹','🐾','🖥️','🧸','⚽','🎮','🌸','🍕','☕',
];

// ══════════════════════════════════════════════════════════════════════════════
//  LISTS PAGE  (tab — no back arrow)
// ══════════════════════════════════════════════════════════════════════════════
class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});
  @override State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {

  @override
  void initState() {
    super.initState();
    context.read<ShoppingBloc>().add(LoadShoppingLists());
  }

  @override
  Widget build(BuildContext context) {
    final t      = context.watch<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor:
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(t.shoppingLists,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_shopping',
        onPressed: () => _showCreateListSheet(context, isDark, t),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.newList,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<ShoppingBloc, ShoppingState>(
        builder: (ctx, state) {
          if (state is ShoppingLoading || state is ShoppingInitial) {
            return const Center(child: CircularProgressIndicator(
                color: AppColors.gold));
          }
          if (state is ShoppingError) {
            return Center(child: Text(state.message,
                style: TextStyle(color: isDark
                    ? AppColors.subTextDark : AppColors.subTextLight)));
          }
          if (state is! ShoppingLoaded || state.lists.isEmpty) {
            return _EmptyState(isDark: isDark, t: t,
                onTap: () => _showCreateListSheet(context, isDark, t));
          }

          final totalItems   = state.lists.fold(0, (s, l) => s + l.totalItems);
          final checkedItems = state.lists.fold(0, (s, l) => s + l.checkedItems);

          return Column(children: [
            // ── Summary strip ──────────────────────────────────────────
            if (totalItems > 0)
              Container(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(children: [
                  _SummaryPill(
                    label: '${state.lists.length} ${t.shoppingLists.toLowerCase()}',
                    icon:  Iconsax.shopping_cart,
                    color: AppColors.accent,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _SummaryPill(
                    label: '$checkedItems / $totalItems ${t.itemsDone}',
                    icon:  Iconsax.tick_circle,
                    color: AppColors.income,
                    isDark: isDark,
                  ),
                ]),
              ),

            Expanded(child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: state.lists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx2, i) {
                final list = state.lists[i];
                return _ShoppingListCard(
                  list:     list,
                  isDark:   isDark,
                  t:        t,
                  onTap:    () => _openList(context, list),
                  onEdit:   () => _showCreateListSheet(
                      context, isDark, t, existing: list),
                  onDelete: () => _confirmDelete(context, list, isDark, t),
                );
              },
            )),
          ]);
        },
      ),
    );
  }

  void _openList(BuildContext ctx, ShoppingListEntity list) {
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: ctx.read<ShoppingBloc>(),
        child: _ShoppingDetailPage(listId: list.id),
      ),
    ));
  }

  void _confirmDelete(BuildContext ctx, ShoppingListEntity list,
      bool isDark, dynamic t) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Iconsax.trash, color: AppColors.expense, size: 20),
          const SizedBox(width: 10),
          Text(t.deleteList,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        content: Text('${list.emoji} ${list.title}\n\n${t.deleteListConfirm}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel)),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                  foregroundColor: Colors.white, elevation: 0),
              onPressed: () {
                Navigator.pop(ctx);
                ctx.read<ShoppingBloc>().add(DeleteShoppingList(list.id));
              },
              child: Text(t.delete)),
        ],
      ),
    );
  }

  void _showCreateListSheet(BuildContext ctx, bool isDark, dynamic t,
      {ShoppingListEntity? existing}) {
    final titleCtrl      = TextEditingController(text: existing?.title ?? '');
    String selectedEmoji = existing?.emoji ?? '🛒';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx2, setSheet) =>
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2))),
                Row(children: [
                  Text(existing != null ? t.editList : t.newList,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textDark : AppColors.textLight)),
                  const Spacer(),
                  if (existing != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx2);
                        _confirmDelete(ctx, existing, isDark, t);
                      },
                      child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: AppColors.expense.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Iconsax.trash,
                              color: AppColors.expense, size: 16)),
                    ),
                ]),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8,
                    children: _listEmojis.map((e) => GestureDetector(
                      onTap: () => setSheet(() => selectedEmoji = e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                            color: selectedEmoji == e
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : isDark ? AppColors.cardDark : AppColors.bgLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selectedEmoji == e
                                    ? AppColors.accent : Colors.transparent,
                                width: 2)),
                        child: Center(child: Text(e,
                            style: const TextStyle(fontSize: 22))),
                      ),
                    )).toList()),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  autofocus: existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 16,
                      color: isDark ? AppColors.textDark : AppColors.textLight),
                  decoration: InputDecoration(
                    hintText: t.listNameHint,
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : AppColors.bgLight,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 1.5)),
                    prefixText: '$selectedEmoji  ',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0),
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) return;
                        if (existing != null) {
                          ctx.read<ShoppingBloc>().add(UpdateShoppingList(
                              id: existing.id, title: title,
                              emoji: selectedEmoji));
                        } else {
                          ctx.read<ShoppingBloc>().add(CreateShoppingList(
                              title: title, emoji: selectedEmoji));
                        }
                        Navigator.pop(ctx2);
                      },
                      child: Text(t.save,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    )),
              ]),
            )),
      ),
    );
  }
}

// ── Summary pill ──────────────────────────────────────────────────────────────
class _SummaryPill extends StatelessWidget {
  final String label; final IconData icon;
  final Color color; final bool isDark;
  const _SummaryPill({required this.label, required this.icon,
    required this.color, required this.isDark});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

// ── List card with visible edit + delete ──────────────────────────────────────
class _ShoppingListCard extends StatelessWidget {
  final ShoppingListEntity list;
  final bool isDark; final dynamic t;
  final VoidCallback onTap, onEdit, onDelete;
  const _ShoppingListCard({required this.list, required this.isDark,
    required this.t, required this.onTap,
    required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final done  = list.checkedItems;
    final total = list.totalItems;
    final pct   = list.progress;
    final color = list.isAllChecked ? AppColors.income : AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: list.isAllChecked
                  ? AppColors.income.withValues(alpha: 0.4)
                  : isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(list.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(list.title, style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDark : AppColors.textLight)),
                    const SizedBox(height: 2),
                    Text(total == 0
                        ? t.noItems
                        : '$done / $total ${t.itemsDone}',
                        style: TextStyle(fontSize: 12,
                            color: isDark
                                ? AppColors.subTextDark : AppColors.subTextLight)),
                  ],
                )),
                // Always-visible action buttons
                if (list.isAllChecked)
                  const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text('✅', style: TextStyle(fontSize: 20))),
                // Edit
                _CardBtn(icon: Iconsax.edit,
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    onTap: onEdit),
                const SizedBox(width: 4),
                // Delete — red, always visible
                _CardBtn(
                    icon: Iconsax.trash,
                    color: AppColors.expense,
                    bg: AppColors.expense.withValues(alpha: 0.08),
                    onTap: onDelete),
              ]),
              if (total > 0) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 5,
                      backgroundColor: isDark
                          ? AppColors.borderDark : AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Text('${(pct * 100).toInt()}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: color)),
                ]),
              ],
            ]),
      ),
    );
  }
}

class _CardBtn extends StatelessWidget {
  final IconData icon; final Color color; final Color? bg;
  final VoidCallback onTap;
  const _CardBtn({required this.icon, required this.color,
    required this.onTap, this.bg});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
          color: bg ?? Colors.transparent,
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color),
    ),
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark; final dynamic t; final VoidCallback onTap;
  const _EmptyState({required this.isDark, required this.t, required this.onTap});
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🛒', style: TextStyle(fontSize: 72)),
      const SizedBox(height: 16),
      Text(t.noShoppingLists, style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDark : AppColors.textLight)),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(t.createFirstList, style: TextStyle(fontSize: 14,
            color: isDark ? AppColors.subTextDark : AppColors.subTextLight),
            textAlign: TextAlign.center),
      ),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  DETAIL PAGE
// ══════════════════════════════════════════════════════════════════════════════
class _ShoppingDetailPage extends StatefulWidget {
  final String listId;
  const _ShoppingDetailPage({required this.listId});
  @override State<_ShoppingDetailPage> createState() =>
      _ShoppingDetailPageState();
}

class _ShoppingDetailPageState extends State<_ShoppingDetailPage>
    with TickerProviderStateMixin {

  final _addCtrl     = TextEditingController();
  final _addFocus    = FocusNode();
  late AnimationController _confettiCtrl;
  bool _showConfetti = false;
  bool _addFocused   = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000));
    _confettiCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _showConfetti = false);
        _confettiCtrl.reset();
      }
    });
    _addFocus.addListener(
            () => setState(() => _addFocused = _addFocus.hasFocus));
  }

  @override
  void dispose() {
    _addCtrl.dispose(); _addFocus.dispose();
    _confettiCtrl.dispose(); super.dispose();
  }

  void _triggerConfetti() {
    setState(() => _showConfetti = true);
    _confettiCtrl.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final t      = context.watch<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ShoppingBloc, ShoppingState>(
      listener: (ctx, state) {
        if (state is! ShoppingLoaded) return;
        final list = state.lists.cast<ShoppingListEntity?>()
            .firstWhere((l) => l?.id == widget.listId, orElse: () => null);
        if (list != null && list.isAllChecked && !_showConfetti) {
          _triggerConfetti();
        }
      },
      builder: (ctx, state) {
        final list = state is ShoppingLoaded
            ? state.lists.cast<ShoppingListEntity?>()
            .firstWhere((l) => l?.id == widget.listId,
            orElse: () => null)
            : null;

        if (list == null) {
          return Scaffold(
              appBar: AppBar(title: Text(t.shoppingList)),
              body: const SizedBox.shrink());
        }

        final unchecked = list.items.where((i) => !i.isChecked).toList();
        final checked   = list.items.where((i) =>  i.isChecked).toList();
        final pct       = list.progress;

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          appBar: AppBar(
            backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left,
                  color: isDark ? AppColors.textDark : AppColors.textLight),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(list.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Flexible(child: Text(list.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 17))),
            ]),
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: isDark
                    ? AppColors.borderDark : AppColors.borderLight)),
            actions: [
              if (checked.isNotEmpty)
                TextButton.icon(
                  onPressed: () => ctx.read<ShoppingBloc>()
                      .add(ClearCheckedItems(list.id)),
                  icon: const Icon(Iconsax.trash,
                      size: 14, color: AppColors.expense),
                  label: Text(t.clearChecked,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.expense)),
                ),
            ],
          ),
          body: Stack(children: [
            Column(children: [

              // ── Progress header ────────────────────────────────────
              if (list.totalItems > 0)
                Container(
                  color: isDark
                      ? AppColors.surfaceDark : AppColors.surfaceLight,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(children: [
                    Row(children: [
                      Text(
                        list.isAllChecked
                            ? '${t.allDone} 🎉'
                            : '${list.checkedItems} / ${list.totalItems} ${t.itemsDone}',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: list.isAllChecked ? AppColors.income
                                : isDark ? AppColors.textDark : AppColors.textLight),
                      ),
                      const Spacer(),
                      Text('${(pct * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: list.isAllChecked
                                  ? AppColors.income : AppColors.accent)),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct, minHeight: 7,
                        backgroundColor: isDark
                            ? AppColors.borderDark : AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            list.isAllChecked
                                ? AppColors.income : AppColors.accent),
                      ),
                    ),
                  ]),
                ),

              // ── Item list ──────────────────────────────────────────
              Expanded(child: list.items.isEmpty
                  ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    Text(t.addFirstItem, style: TextStyle(fontSize: 15,
                        color: isDark
                            ? AppColors.subTextDark : AppColors.subTextLight)),
                    const SizedBox(height: 4),
                    Text(t.addItemHint, style: TextStyle(fontSize: 13,
                        color: isDark
                            ? AppColors.mutedDark : AppColors.mutedLight)),
                  ]))
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  if (unchecked.isNotEmpty) ...[
                    _SectionLabel(
                        '${t.shoppingList} (${unchecked.length})',
                        isDark: isDark),
                    const SizedBox(height: 6),
                    ...unchecked.map((item) => _ItemTile(
                      item: item, isDark: isDark, t: t,
                      onToggle: () => ctx.read<ShoppingBloc>().add(
                          ToggleShoppingItem(itemId: item.id, listId: list.id)),
                      onDelete: () => ctx.read<ShoppingBloc>().add(
                          DeleteShoppingItem(item.id)),
                      onEdit: () => _showEditItem(ctx, item, isDark, t),
                    )),
                  ],
                  if (checked.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SectionLabel('${t.done} (${checked.length})',
                        isDark: isDark),
                    const SizedBox(height: 6),
                    ...checked.map((item) => _ItemTile(
                      item: item, isDark: isDark, t: t,
                      onToggle: () => ctx.read<ShoppingBloc>().add(
                          ToggleShoppingItem(itemId: item.id, listId: list.id)),
                      onDelete: () => ctx.read<ShoppingBloc>().add(
                          DeleteShoppingItem(item.id)),
                      onEdit: () => _showEditItem(ctx, item, isDark, t),
                    )),
                  ],
                  if (list.isAllChecked)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.income.withValues(alpha: 0.3))),
                      child: Column(children: [
                        const Text('🎉',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(t.allDone, style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: AppColors.income)),
                        const SizedBox(height: 4),
                        Text(t.shoppingComplete, style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.subTextDark
                                : AppColors.subTextLight)),
                      ]),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
              ),

              // ── Add bar ────────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.fromLTRB(
                    16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
                decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: Border(top: BorderSide(
                        color: _addFocused ? AppColors.accent
                            : isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: _addFocused ? 1.5 : 1))),
                child: Row(children: [
                  Expanded(child: TextField(
                    controller: _addCtrl,
                    focusNode:  _addFocus,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 15,
                        color: isDark ? AppColors.textDark : AppColors.textLight),
                    decoration: InputDecoration(
                      hintText: t.addItemHint,
                      hintStyle: TextStyle(color: isDark
                          ? AppColors.mutedDark : AppColors.mutedLight),
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : AppColors.bgLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.accent, width: 1.5)),
                    ),
                    onSubmitted: (v) => _addItem(ctx, list.id, v),
                  )),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: _addFocused
                            ? AppColors.accent
                            : AppColors.accent.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14)),
                    child: Material(color: Colors.transparent,
                        child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _addItem(ctx, list.id, _addCtrl.text),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.black, size: 24))),
                  ),
                ]),
              ),
            ]),

            // ── Confetti ───────────────────────────────────────────
            if (_showConfetti)
              IgnorePointer(child: AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height),
                  painter: _ConfettiPainter(_confettiCtrl.value),
                ),
              )),
          ]),
        );
      },
    );
  }

  void _addItem(BuildContext ctx, String listId, String text) {
    final name = text.trim();
    if (name.isEmpty) return;
    ctx.read<ShoppingBloc>().add(AddShoppingItem(listId: listId, name: name));
    _addCtrl.clear();
    _addFocus.requestFocus();
    HapticFeedback.lightImpact();
  }

  void _showEditItem(BuildContext ctx, ShoppingItemEntity item,
      bool isDark, dynamic t) {
    final ctrl  = TextEditingController(text: item.name);
    final qCtrl = TextEditingController(text: item.quantity ?? '');
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2))),
            Row(children: [
              Text(t.editItem, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDark : AppColors.textLight)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  ctx.read<ShoppingBloc>().add(DeleteShoppingItem(item.id));
                },
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Iconsax.trash,
                        color: AppColors.expense, size: 16)),
              ),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl, autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
              decoration: InputDecoration(
                  labelText: t.itemName, filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.bgLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent, width: 1.5))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qCtrl,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
              decoration: InputDecoration(
                  labelText: t.quantity, hintText: t.quantityHint, filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.bgLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent, width: 1.5))),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent, foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0),
                  onPressed: () {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    ctx.read<ShoppingBloc>().add(UpdateShoppingItem(
                        id: item.id, name: name,
                        quantity: qCtrl.text.trim().isEmpty ? null : qCtrl.text.trim()));
                    Navigator.pop(ctx);
                  },
                  child: Text(t.save, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
                )),
          ]),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text; final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});
  @override Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.subTextDark : AppColors.subTextLight));
}

// ── Item tile — visible delete button ─────────────────────────────────────────
class _ItemTile extends StatelessWidget {
  final ShoppingItemEntity item;
  final bool isDark; final dynamic t;
  final VoidCallback onToggle, onDelete, onEdit;
  const _ItemTile({required this.item, required this.isDark, required this.t,
    required this.onToggle, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: item.isChecked
                ? AppColors.income.withValues(alpha: 0.2)
                : isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(children: [
        // Checkbox
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isChecked ? AppColors.income : Colors.transparent,
                border: Border.all(
                    color: item.isChecked ? AppColors.income
                        : isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 2),
              ),
              child: item.isChecked
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ),
        ),
        // Text — tap to edit
        Expanded(child: GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500,
                      color: item.isChecked
                          ? (isDark ? AppColors.mutedDark : AppColors.mutedLight)
                          : (isDark ? AppColors.textDark : AppColors.textLight),
                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                      decorationColor: isDark
                          ? AppColors.mutedDark : AppColors.mutedLight)),
                  if (item.quantity != null && item.quantity!.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 2),
                        child: Text(item.quantity!, style: TextStyle(fontSize: 12,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight))),
                ]),
          ),
        )),
        // Delete — always visible
        GestureDetector(
          onTap: onDelete,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
            child: Icon(Iconsax.trash, size: 17,
                color: AppColors.expense.withValues(alpha: 0.55)),
          ),
        ),
      ]),
    );
  }
}

// ── Confetti ──────────────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _rng    = Random(42);
  static final _pieces = List.generate(60, (i) => _ConfettiPiece(
    x: _rng.nextDouble(), vx: (_rng.nextDouble() - 0.5) * 0.004,
    vy: 0.003 + _rng.nextDouble() * 0.005,
    size: 6 + _rng.nextDouble() * 8,
    color: [
      const Color(0xFFFFC107), const Color(0xFF7C3AED),
      const Color(0xFF10B981), const Color(0xFFEC4899),
      const Color(0xFF3B82F6), const Color(0xFFFF6348),
    ][i % 6],
    isCircle: i % 3 == 0,
    rot: _rng.nextDouble() * 6.28,
    rotV: (_rng.nextDouble() - 0.5) * 0.15,
  ));
  const _ConfettiPainter(this.progress);
  @override
  void paint(Canvas canvas, Size s) {
    for (final p in _pieces) {
      final x = (p.x + p.vx * progress * 60) * s.width;
      final y = -30 + p.vy * progress * 60 * s.height;
      if (y > s.height + 20) continue;
      final alpha = progress < 0.7 ? 1.0 : (1 - progress) / 0.3;
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha.clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + p.rotV * progress * 60);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero,
            width: p.size, height: p.size * 0.5), paint);
      }
      canvas.restore();
    }
  }
  @override bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress;
}
class _ConfettiPiece {
  final double x, vx, vy, size, rot, rotV;
  final Color color; final bool isCircle;
  const _ConfettiPiece({required this.x, required this.vx, required this.vy,
    required this.size, required this.color, required this.isCircle,
    required this.rot, required this.rotV});
}