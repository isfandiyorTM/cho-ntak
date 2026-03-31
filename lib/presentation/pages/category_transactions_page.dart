import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../pages/transaction_detail_page.dart';
import '../pages/add_transaction_page.dart';
import '../widgets/transaction_tile.dart';

class CategoryTransactionsPage extends StatelessWidget {
  final CategoryEntity category;
  final List<TransactionEntity> transactions;
  final String currencySymbol;

  const CategoryTransactionsPage({
    super.key,
    required this.category,
    required this.transactions,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final t      = context.watch<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = category.color;

    // Summary stats
    final income  = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final net = income - expense;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [

          // ── Hero header ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      Color.lerp(color, Colors.black, 0.3)!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Icon / emoji
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: category.emoji != null
                                ? Text(category.emoji!,
                                style: const TextStyle(fontSize: 28))
                                : Icon(category.icon,
                                color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(category.name,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        Text('${transactions.length} transactions',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Summary cards ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  if (income > 0)
                    Expanded(child: _SummaryCard(
                      label: t.income,
                      amount: income,
                      color: AppColors.income,
                      currencySymbol: currencySymbol,
                      isDark: isDark,
                    )),
                  if (income > 0 && expense > 0)
                    const SizedBox(width: 10),
                  if (expense > 0)
                    Expanded(child: _SummaryCard(
                      label: t.expense,
                      amount: expense,
                      color: AppColors.expense,
                      currencySymbol: currencySymbol,
                      isDark: isDark,
                    )),
                ],
              ),
            ),
          ),

          // ── Transactions list ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: transactions.isEmpty
                ? SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(children: [
                    Icon(Iconsax.receipt_item,
                        size: 48,
                        color: isDark
                            ? AppColors.mutedDark
                            : AppColors.mutedLight),
                    const SizedBox(height: 12),
                    Text('Tranzaksiyalar yo\'q',
                        style: TextStyle(
                            color: isDark
                                ? AppColors.mutedDark
                                : AppColors.mutedLight,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                  final tx = transactions[i];
                  return TransactionTile(
                    transaction: tx,
                    category: category,
                    index: i,
                    currencySymbol: currencySymbol,
                    onTap: () => TransactionDetailPage.show(
                      ctx,
                      transaction: tx,
                      currencySymbol: currencySymbol,
                      category: category,
                    ),
                  );
                },
                childCount: transactions.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, currencySymbol;
  final double amount;
  final Color color;
  final bool isDark;
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCompact(amount, currencySymbol),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color),
          ),
        ],
      ),
    );
  }
}