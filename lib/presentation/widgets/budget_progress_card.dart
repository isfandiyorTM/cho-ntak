import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/i18n/translations.dart';
import '../../core/i18n/language_provider.dart';
import '../../domain/entities/budget_entity.dart';
import '../blocs/budget/budget_bloc.dart';

class BudgetProgressCard extends StatefulWidget {
  final BudgetEntity budget;
  final String currencySymbol;
  final Translations t;

  const BudgetProgressCard({
    super.key,
    required this.budget,
    required this.currencySymbol,
    required this.t,
  });

  @override
  State<BudgetProgressCard> createState() => _BudgetProgressCardState();
}

class _BudgetProgressCardState extends State<BudgetProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progressAnim;

  BudgetEntity get budget => widget.budget;
  String get currencySymbol => widget.currencySymbol;
  Translations get t => widget.t;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _progressAnim = Tween<double>(begin: 0, end: budget.percentage)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(BudgetProgressCard old) {
    super.didUpdateWidget(old);
    if (old.budget.percentage != budget.percentage) {
      _progressAnim = Tween<double>(
          begin: old.budget.percentage, end: budget.percentage)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _showEditDialog(BuildContext context) {
    final ctrl = TextEditingController(
        text: budget.limit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Iconsax.edit, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(t.editBudget,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: t.budgetAmount,
            prefixText: '$currencySymbol ',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: AppColors.gold, width: 1.5),
            ),
          ),
        ),
        actions: [
          // Delete budget button
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(context);
            },
            icon: const Icon(Iconsax.trash, color: AppColors.expense,
                size: 16),
            label: Text(t.deleteBudget,
                style: const TextStyle(color: AppColors.expense)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                context.read<BudgetBloc>().add(SetBudgetEvent(
                    limit: val,
                    month: budget.month,
                    year: budget.year));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black),
            child: Text(t.save,
                style:
                const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(t.deleteBudgetTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(t.deleteBudgetBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<BudgetBloc>().add(DeleteBudgetEvent(
                  month: budget.month, year: budget.year));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white),
            child: Text(t.delete,
                style:
                const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct    = budget.percentage;
    final color  = budget.isOverBudget
        ? AppColors.expense
        : budget.isNearLimit
        ? AppColors.warning
        : AppColors.income;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Iconsax.chart,
                    color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Text(t.monthlyBudgetCard,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
              Row(children: [
                // Status badge
                if (budget.isNearLimit || budget.isOverBudget)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.warning_2,
                              size: 12, color: color),
                          const SizedBox(width: 4),
                          Text(
                            budget.isOverBudget
                                ? t.overBudget
                                : t.nearLimit,
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                  ),
                // Edit button
                GestureDetector(
                  onTap: () => _showEditDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Iconsax.edit,
                        color: AppColors.gold, size: 14),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 16),

          // ── Progress bar ─────────────────────────────────
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progressAnim.value,
                minHeight: 10,
                backgroundColor: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Percentage label
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),

          // ── Stats row ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: t.spent,
                value: CurrencyFormatter.formatCompact(
                    budget.spent, currencySymbol),
                color: AppColors.expense,
              ),
              _StatItem(
                label: t.remaining,
                value: CurrencyFormatter.formatCompact(
                    budget.remaining.abs(), currencySymbol),
                color: budget.isOverBudget
                    ? AppColors.expense
                    : AppColors.income,
              ),
              _StatItem(
                label: t.limit,
                value: CurrencyFormatter.formatCompact(
                    budget.limit, currencySymbol),
                color: AppColors.gold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color)),
      const SizedBox(height: 2),
      Text(label,
          style:
          const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}