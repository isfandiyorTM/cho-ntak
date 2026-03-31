import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_budget_entity.dart';
import '../blocs/category/category_bloc.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/category_budget/category_budget_bloc.dart';

class CategoryBudgetPage extends StatefulWidget {
  final String currencySymbol;
  const CategoryBudgetPage({super.key, required this.currencySymbol});
  @override State<CategoryBudgetPage> createState() =>
      _CategoryBudgetPageState();
}

class _CategoryBudgetPageState extends State<CategoryBudgetPage> {

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Load budgets for this month
    context.read<CategoryBudgetBloc>().add(
        LoadCategoryBudgets(month: now.month, year: now.year));
    // Refresh spent amounts from transactions
    _refreshSpent();
  }

  void _refreshSpent() {
    final txState = context.read<TransactionBloc>().state;
    if (txState is! TransactionLoaded) return;
    final now = DateTime.now();
    final spentMap = <String, double>{};
    for (final tx in txState.transactions) {
      if (tx.type.name == 'expense') {
        spentMap[tx.categoryId] = (spentMap[tx.categoryId] ?? 0) + tx.amount;
      }
    }
    context.read<CategoryBudgetBloc>().add(RefreshCategoryBudgetSpent(
        month: now.month, year: now.year, spentByCategory: spentMap));
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
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left,
              color: isDark ? AppColors.textDark : AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t.categoryBudgets,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      body: BlocBuilder<CategoryBudgetBloc, CategoryBudgetState>(
        builder: (ctx, budgetState) =>
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (ctx2, catState) {
                if (catState is! CategoryLoaded) {
                  return const Center(child: CircularProgressIndicator(
                      color: AppColors.gold));
                }

                final cats    = catState.categories
                    .where((c) => !c.isDefault).toList();
                final defCats = catState.categories
                    .where((c) => c.isDefault).toList();
                final allCats = [...defCats, ...cats];

                final budgets = budgetState is CategoryBudgetLoaded
                    ? budgetState.budgets : <CategoryBudgetEntity>[];
                final budgetMap = {for (final b in budgets) b.id: b};

                final now     = DateTime.now();
                final setBudgets = allCats
                    .where((c) => budgetMap.containsKey(c.id)).toList();
                final unsetCats  = allCats
                    .where((c) => !budgetMap.containsKey(c.id)).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [

                    // ── Info banner ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.25))),
                      child: Row(children: [
                        Icon(Iconsax.info_circle,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t.categoryBudgetInfo,
                            style: TextStyle(fontSize: 12,
                                color: isDark
                                    ? AppColors.subTextDark
                                    : AppColors.subTextLight))),
                      ]),
                    ),

                    // ── Active budgets ──────────────────────────────
                    if (setBudgets.isNotEmpty) ...[
                      _Header(t.activeBudgets, isDark: isDark),
                      const SizedBox(height: 10),
                      ...setBudgets.map((cat) {
                        final b = budgetMap[cat.id]!;
                        return _BudgetCard(
                          cat:      cat,
                          budget:   b,
                          currency: widget.currencySymbol,
                          isDark:   isDark,
                          t:        t,
                          onEdit: () => _showSetDialog(
                              context, cat, b.limit, b.spent,
                              now.month, now.year, isDark, t),
                          onDelete: () {
                            context.read<CategoryBudgetBloc>().add(
                                DeleteCategoryBudget(
                                    categoryId: cat.id,
                                    month: now.month, year: now.year));
                          },
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    // ── Add budget for category ──────────────────────
                    _Header(t.addBudgetFor, isDark: isDark),
                    const SizedBox(height: 10),
                    if (unsetCats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: Text(t.allCategoriesHaveBudget,
                            style: TextStyle(fontSize: 13,
                                color: isDark
                                    ? AppColors.mutedDark
                                    : AppColors.mutedLight))),
                      )
                    else
                      ...unsetCats.map((cat) => _CategoryTile(
                        cat:    cat,
                        isDark: isDark,
                        onTap:  () => _showSetDialog(
                            context, cat, null, 0,
                            now.month, now.year, isDark, t),
                      )),
                  ],
                );
              },
            ),
      ),
    );
  }

  void _showSetDialog(
      BuildContext ctx,
      CategoryEntity cat,
      double? existingLimit,
      double spent,
      int month, int year,
      bool isDark,
      dynamic t,
      ) {
    final ctrl = TextEditingController(
        text: existingLimit?.toStringAsFixed(0) ?? '');
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2))),
            // Category label
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: cat.emoji != null
                    ? Center(child: Text(cat.emoji!,
                    style: const TextStyle(fontSize: 20)))
                    : Icon(cat.icon, color: cat.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name, style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDark : AppColors.textLight)),
                  Text(existingLimit != null
                      ? t.editBudget : t.setBudget,
                      style: TextStyle(fontSize: 12,
                          color: isDark
                              ? AppColors.subTextDark : AppColors.subTextLight)),
                ],
              )),
            ]),
            const SizedBox(height: 20),
            // Amount input
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDark : AppColors.textLight),
              decoration: InputDecoration(
                labelText: t.budgetAmount,
                prefixText: '${widget.currencySymbol} ',
                prefixStyle: TextStyle(fontSize: 16,
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.bgLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              if (existingLimit != null) ...[
                Expanded(child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<CategoryBudgetBloc>().add(
                        DeleteCategoryBudget(categoryId: cat.id,
                            month: month, year: year));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: const BorderSide(color: AppColors.expense),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(t.delete),
                )),
                const SizedBox(width: 12),
              ],
              Expanded(child: ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(ctrl.text);
                  if (val != null && val > 0) {
                    context.read<CategoryBudgetBloc>().add(SetCategoryBudget(
                        categoryId: cat.id, limit: val,
                        spent: spent, month: month, year: year));
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text(t.save,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 16)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Budget card with animated progress ───────────────────────────────────────
class _BudgetCard extends StatefulWidget {
  final CategoryEntity       cat;
  final CategoryBudgetEntity budget;
  final String               currency;
  final bool                 isDark;
  final dynamic              t;
  final VoidCallback         onEdit, onDelete;
  const _BudgetCard({required this.cat, required this.budget,
    required this.currency, required this.isDark, required this.t,
    required this.onEdit, required this.onDelete});
  @override State<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<_BudgetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _bar;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _bar  = Tween<double>(begin: 0, end: widget.budget.percentage)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200),
            () { if (mounted) _ctrl.forward(); });
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final b     = widget.budget;
    final cat   = widget.cat;
    final color = b.isOver ? AppColors.expense
        : b.isNear ? AppColors.warning : AppColors.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(children: [
          // Category icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: cat.emoji != null
                ? Center(child: Text(cat.emoji!,
                style: const TextStyle(fontSize: 18)))
                : Icon(cat.icon, color: cat.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cat.name, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: widget.isDark ? AppColors.textDark : AppColors.textLight)),
              Text('${(b.percentage * 100).toStringAsFixed(0)}% ${widget.t.used}',
                  style: TextStyle(fontSize: 11, color: color,
                      fontWeight: FontWeight.w600)),
            ],
          )),
          // Status badge
          if (b.isOver || b.isNear)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(b.isOver ? widget.t.overBudget : widget.t.nearLimit,
                  style: TextStyle(fontSize: 10, color: color,
                      fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
          // Edit
          GestureDetector(
              onTap: widget.onEdit,
              child: Icon(Iconsax.edit, size: 16,
                  color: widget.isDark ? AppColors.mutedDark : AppColors.mutedLight)),
        ]),
        const SizedBox(height: 12),
        // Progress bar
        AnimatedBuilder(
          animation: _bar,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _bar.value.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: widget.isDark
                  ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Stat(widget.t.spent,
                CurrencyFormatter.formatCompact(b.spent, widget.currency),
                AppColors.expense, widget.isDark),
            _Stat(widget.t.remaining,
                CurrencyFormatter.formatCompact(
                    b.remaining.abs(), widget.currency),
                b.isOver ? AppColors.expense : AppColors.income,
                widget.isDark),
            _Stat(widget.t.limit,
                CurrencyFormatter.formatCompact(b.limit, widget.currency),
                AppColors.gold, widget.isDark),
          ],
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value; final Color color; final bool isDark;
  const _Stat(this.label, this.value, this.color, this.isDark);
  @override Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: color)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 10,
        color: isDark ? AppColors.mutedDark : AppColors.mutedLight)),
  ]);
}

class _CategoryTile extends StatelessWidget {
  final CategoryEntity cat; final bool isDark; final VoidCallback onTap;
  const _CategoryTile({required this.cat, required this.isDark,
    required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: cat.emoji != null
              ? Center(child: Text(cat.emoji!,
              style: const TextStyle(fontSize: 16)))
              : Icon(cat.icon, color: cat.color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(cat.name, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : AppColors.textLight))),
        Icon(Icons.add_rounded, color: AppColors.accent, size: 20),
      ]),
    ),
  );
}

class _Header extends StatelessWidget {
  final String text; final bool isDark;
  const _Header(this.text, {required this.isDark});
  @override Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? AppColors.subTextDark : AppColors.subTextLight));
}