import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/category/category_bloc.dart';
import '../widgets/error_widgets.dart';
import 'category_transactions_page.dart';

class StatsPage extends StatefulWidget {
  final String currencySymbol;
  const StatsPage({super.key, required this.currencySymbol});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;

  // Master animation controller — drives everything on this page
  late AnimationController _masterCtrl;
  late Animation<double> _masterAnim;

  @override
  void initState() {
    super.initState();
    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _masterAnim =
        CurvedAnimation(parent: _masterCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final txState = context.read<TransactionBloc>().state;
      if (txState is TransactionInitial) {
        final now = DateTime.now();
        context
            .read<TransactionBloc>()
            .add(LoadTransactions(month: now.month, year: now.year));
      }
      final catState = context.read<CategoryBloc>().state;
      if (catState is CategoryInitial) {
        context.read<CategoryBloc>().add(LoadCategories());
      }
    }
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _masterCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<LanguageProvider>().t.stats),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, txState) {
          return BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, catState) {

              if (txState is TransactionInitial ||
                  txState is TransactionLoading ||
                  catState is CategoryInitial ||
                  catState is CategoryLoading) {
                return const HomeLoadingSkeleton();
              }

              if (txState is TransactionError) {
                return ErrorScreen(
                  title: 'Statistika yuklanmadi',
                  message: txState.message,
                  onRetry: () {
                    final now = DateTime.now();
                    context.read<TransactionBloc>().add(
                        LoadTransactions(month: now.month, year: now.year));
                  },
                );
              }

              if (txState is! TransactionLoaded ||
                  catState is! CategoryLoaded) {
                return const SizedBox.shrink();
              }

              // Start animations whenever data arrives
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _startAnimation());

              final categories = catState.categories;
              final Map<String, double> byCategory = {};
              for (final tx in txState.transactions) {
                if (tx.type == TransactionType.expense) {
                  byCategory[tx.categoryId] =
                      (byCategory[tx.categoryId] ?? 0) + tx.amount;
                }
              }

              final sortedCategories = byCategory.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              // Show ALL categories that have transactions, not just top 5
              final topCategories = sortedCategories;

              final t = context.read<LanguageProvider>().t;

              if (txState.transactions.isEmpty) {
                return EmptyState(
                  title: t.noData,
                  subtitle: t.addToSeeStats,
                  icon: Iconsax.chart,
                  iconColor: AppColors.gold.withValues(alpha: 0.5),
                );
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Overview section ──────────────────────
                    _AnimatedSection(
                      anim: _masterAnim,
                      delay: 0.0,
                      child: _SectionTitle(t.overview),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSection(
                      anim: _masterAnim,
                      delay: 0.05,
                      child: _OverviewChart(
                        income: txState.totalIncome,
                        expense: txState.totalExpense,
                        currencySymbol: widget.currencySymbol,
                        masterAnim: _masterAnim,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (byCategory.isNotEmpty) ...[
                      // ── Pie chart section ─────────────────
                      _AnimatedSection(
                        anim: _masterAnim,
                        delay: 0.1,
                        child: _SectionTitle(t.spendingByCategory),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedSection(
                        anim: _masterAnim,
                        delay: 0.15,
                        child: _CategoryPieChart(
                          byCategory: byCategory,
                          categories: categories,
                          masterAnim: _masterAnim,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Top categories ────────────────────
                      _AnimatedSection(
                        anim: _masterAnim,
                        delay: 0.25,
                        child: _SectionTitle(t.spendingByCategory),
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < topCategories.length; i++)
                        _AnimatedSection(
                          anim: _masterAnim,
                          delay: 0.3 + i * 0.06,
                          child: _buildCategoryRow(
                            entry: topCategories[i],
                            categories: categories,
                            totalExpense: txState.totalExpense,
                            allTransactions: txState.transactions,
                          ),
                        ),
                    ],

                    const SizedBox(height: 60),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryRow({
    required MapEntry<String, double> entry,
    required List<CategoryEntity> categories,
    required double totalExpense,
    required List<TransactionEntity> allTransactions,
  }) {
    CategoryEntity? cat;
    try {
      cat = categories.firstWhere((c) => c.id == entry.key);
    } catch (_) {}

    final pct = totalExpense > 0
        ? (entry.value / totalExpense).clamp(0.0, 1.0)
        : 0.0;

    // Transactions for this specific category
    final catTxs = allTransactions
        .where((tx) => tx.categoryId == entry.key)
        .toList();

    return _CategoryRow(
      name: cat?.name ?? 'Unknown',
      icon: cat?.icon ?? Iconsax.more_circle,
      emoji: cat?.emoji,
      color: cat?.color ?? AppColors.gold,
      amount: entry.value,
      percentage: pct,
      currencySymbol: widget.currencySymbol,
      onTap: cat != null ? () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryTransactionsPage(
            category: cat!,
            transactions: catTxs,
            currencySymbol: widget.currencySymbol,
          ),
        ),
      ) : null,
    );
  }
}

// ── Animated section wrapper ──────────────────────────────────────────────────
// Fades + slides in at a delayed point in the master animation timeline
class _AnimatedSection extends StatelessWidget {
  final Animation<double> anim;
  final double delay; // 0.0–1.0 when in the master timeline to start
  final Widget child;

  const _AnimatedSection({
    required this.anim,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final progress = ((anim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final offset   = Offset(0, 20 * (1 - progress));
        return Opacity(
          opacity: progress,
          child: Transform.translate(offset: offset, child: child),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyStats extends StatelessWidget {
  final dynamic t;
  final Animation<double> anim;
  const _EmptyStats({required this.t, required this.anim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, child) => Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - anim.value)),
            child: child,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.chart, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(t.noData,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subTextLight)),
            const SizedBox(height: 8),
            Text(t.addToSeeStats,
                style: TextStyle(fontSize: 13, color: AppColors.subTextLight)),
          ],
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700));
  }
}

// ── Overview bar chart ────────────────────────────────────────────────────────
class _OverviewChart extends StatelessWidget {
  final double income, expense;
  final String currencySymbol;
  final Animation<double> masterAnim;

  const _OverviewChart({
    required this.income,
    required this.expense,
    required this.currencySymbol,
    required this.masterAnim,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t      = context.watch<LanguageProvider>().t;
    final maxVal = [income, expense, 1.0].reduce((a, b) => a > b ? a : b);
    final maxY   = maxVal * 1.3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final labels = [t.income, t.expense];
                        if (v.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(labels[v.toInt()],
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.subTextLight)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBar(0, income, AppColors.income),
                  _buildBar(1, expense, AppColors.expense),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppColors.cardDark
                        : AppColors.surfaceLight,
                    getTooltipItem: (group, _, rod, __) =>
                        BarTooltipItem(
                          CurrencyFormatter.format(
                              rod.toY, currencySymbol),
                          const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                  ),
                ),
              ),
              // ← fl_chart built-in grow-up animation
              swapAnimationDuration:
              const Duration(milliseconds: 800),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 20),
          // Count-up legend values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Legend(label: t.income,
                  value: CurrencyFormatter.formatCompact(income, currencySymbol),
                  color: AppColors.income),
              _Legend(label: t.expense,
                  value: CurrencyFormatter.formatCompact(expense, currencySymbol),
                  color: AppColors.expense),
              _Legend(
                  label: t.balance,
                  value: CurrencyFormatter.formatCompact((income - expense).abs(), currencySymbol),
                  color: income >= expense ? AppColors.gold : AppColors.expense),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 52,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 0,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }
}


// ── Plain legend ──────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Legend({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
          ],
        ),
      ],
    );
  }
}

// ── Pie chart with spin-in ────────────────────────────────────────────────────
class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> byCategory;
  final List<CategoryEntity> categories;
  final Animation<double> masterAnim;

  const _CategoryPieChart({
    required this.byCategory,
    required this.categories,
    required this.masterAnim,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total  = byCategory.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = byCategory.entries.map((e) {
      CategoryEntity? cat;
      try {
        cat = categories.firstWhere((c) => c.id == e.key);
      } catch (_) {}
      final pct = (e.value / total) * 100;
      return PieChartSectionData(
        value: e.value,
        color: cat?.color ?? AppColors.gold,
        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 65,
        titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      // AnimatedBuilder spins the pie in using a rotation transform
      child: AnimatedBuilder(
        animation: masterAnim,
        builder: (_, child) {
          final progress = ((masterAnim.value - 0.1) / 0.9).clamp(0.0, 1.0);
          return Opacity(
            opacity: progress,
            child: Transform.rotate(
              angle: (1 - progress) * -0.5,
              child: child,
            ),
          );
        },
        child: SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 44,
              sectionsSpace: 3,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(enabled: true),
            ),
            // fl_chart built-in spin animation
            swapAnimationDuration: const Duration(milliseconds: 900),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }
}

// ── Category row with animated progress bar ───────────────────────────────────
class _CategoryRow extends StatefulWidget {
  final String        name;
  final IconData      icon;
  final String?       emoji;
  final Color         color;
  final double        amount, percentage;
  final String        currencySymbol;
  final VoidCallback? onTap;
  const _CategoryRow({
    required this.name,
    required this.icon,
    this.emoji,
    required this.color,
    required this.amount,
    required this.percentage,
    required this.currencySymbol,
    this.onTap,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _barAnim = Tween<double>(begin: 0, end: widget.percentage).animate(
        CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic));

    // Start bar after page fades in
    Future.delayed(const Duration(milliseconds: 400),
            () { if (mounted) _barCtrl.forward(); });
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: widget.emoji != null
                        ? Text(widget.emoji!, style: const TextStyle(fontSize: 16))
                        : Icon(widget.icon, color: widget.color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(widget.amount, widget.currencySymbol),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.expense,
                            fontSize: 13),
                      ),
                      Text(
                        '${(widget.percentage * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
                      ),
                    ],
                  ),
                  if (widget.onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        size: 18,
                        color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Animated progress bar
              AnimatedBuilder(
                animation: _barAnim,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _barAnim.value,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                ),
              ),
            ],
          ),
        ), // Container
      ), // InkWell
    ); // Material
  }
}