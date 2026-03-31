import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/category/category_bloc.dart';


import '../widgets/error_widgets.dart';
import 'category_transactions_page.dart';

// ══════════════════════════════════════════════════════════════════════════════
class StatsPage extends StatefulWidget {
  final String currencySymbol;
  const StatsPage({super.key, required this.currencySymbol});
  @override State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _anim;
  bool _initialized = false;

  // Month navigation
  late DateTime _selectedMonth;

  // 6-month trend data: list of {month, income, expense}
  List<_MonthData> _trend = [];
  bool _trendLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _anim = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadCurrentMonth();
      _loadTrend();
    }
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  void _loadCurrentMonth() {
    context.read<TransactionBloc>().add(LoadTransactions(
        month: _selectedMonth.month, year: _selectedMonth.year));
  }

  Future<void> _loadTrend() async {
    setState(() => _trendLoading = true);
    try {
      final repo = context.read<TransactionRepositoryImpl>();
      final all  = await repo.getAllTransactions();
      final now  = DateTime.now();
      final months = <_MonthData>[];
      for (int i = 5; i >= 0; i--) {
        final m    = DateTime(now.year, now.month - i);
        final inc  = all.where((t) =>
        t.type == TransactionType.income &&
            t.date.year == m.year && t.date.month == m.month)
            .fold(0.0, (s, t) => s + t.amount);
        final exp  = all.where((t) =>
        t.type == TransactionType.expense &&
            t.date.year == m.year && t.date.month == m.month)
            .fold(0.0, (s, t) => s + t.amount);
        months.add(_MonthData(date: m, income: inc, expense: exp));
      }
      if (mounted) setState(() { _trend = months; _trendLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _trendLoading = false);
    }
  }

  void _goToPrevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _anim.forward(from: 0);
    _loadCurrentMonth();
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _anim.forward(from: 0);
    _loadCurrentMonth();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final t      = context.watch<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _buildAppBar(t, isDark),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (ctx, txState) =>
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (ctx2, catState) {
                if (txState is TransactionLoading ||
                    txState is TransactionInitial ||
                    catState is CategoryLoading ||
                    catState is CategoryInitial) {
                  return const Center(child: CircularProgressIndicator(
                      color: AppColors.gold));
                }
                if (txState is TransactionError) {
                  return ErrorScreen(
                      title: t.error, message: txState.message,
                      onRetry: _loadCurrentMonth);
                }
                if (txState is! TransactionLoaded ||
                    catState is! CategoryLoaded) {
                  return const SizedBox.shrink();
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _anim.forward(from: 0));

                final txs        = txState.transactions;
                final cats       = catState.categories;
                final income     = txState.totalIncome;
                final expense    = txState.totalExpense;
                final balance    = txState.balance;
                final savingsRate= income > 0
                    ? ((income - expense) / income * 100).clamp(0.0, 100.0) : 0.0;

                // ── Category spending map ─────────────────────────────────
                final byCategory = <String, double>{};
                for (final tx in txs) {
                  if (tx.type == TransactionType.expense) {
                    byCategory[tx.categoryId] =
                        (byCategory[tx.categoryId] ?? 0) + tx.amount;
                  }
                }
                final sortedCats = byCategory.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                // ── Daily spending map ────────────────────────────────────
                final dailySpend = <int, double>{};
                for (final tx in txs) {
                  if (tx.type == TransactionType.expense) {
                    dailySpend[tx.date.day] =
                        (dailySpend[tx.date.day] ?? 0) + tx.amount;
                  }
                }

                // ── Largest expense ───────────────────────────────────────
                TransactionEntity? biggest;
                for (final tx in txs) {
                  if (tx.type == TransactionType.expense) {
                    if (biggest == null || tx.amount > biggest.amount) {
                      biggest = tx;
                    }
                  }
                }

                if (txs.isEmpty) {
                  return _buildEmpty(t, isDark);
                }

                return RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: () async {
                    _loadCurrentMonth();
                    await _loadTrend();
                  },
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (_, child) => FadeTransition(
                        opacity: _anim,
                        child: child),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [

                        // ── Summary cards ─────────────────────────────────
                        _SummaryCards(
                          income:      income,
                          expense:     expense,
                          balance:     balance,
                          savingsRate: savingsRate,
                          currency:    widget.currencySymbol,
                          isDark:      isDark,
                          t:           t,
                        ),
                        const SizedBox(height: 24),

                        // ── 6-month trend ─────────────────────────────────
                        _SectionHeader(t.monthlyTrend, isDark: isDark),
                        const SizedBox(height: 12),
                        _TrendChart(
                          data:     _trend,
                          loading:  _trendLoading,
                          currency: widget.currencySymbol,
                          isDark:   isDark,
                          t:        t,
                          selected: _selectedMonth,
                        ),
                        const SizedBox(height: 24),

                        // ── Daily spending line ───────────────────────────
                        if (dailySpend.isNotEmpty) ...[
                          _SectionHeader(t.dailySpending, isDark: isDark),
                          const SizedBox(height: 12),
                          _DailyChart(
                            dailySpend: dailySpend,
                            month:      _selectedMonth,
                            currency:   widget.currencySymbol,
                            isDark:     isDark,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Spending by category ──────────────────────────
                        if (byCategory.isNotEmpty) ...[
                          _SectionHeader(t.spendingByCategory, isDark: isDark),
                          const SizedBox(height: 12),
                          _PieSection(
                            byCategory: byCategory,
                            categories: cats,
                            totalExpense: expense,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          // Category rows
                          ...sortedCats.map((e) {
                            final cat = cats.cast<CategoryEntity?>()
                                .firstWhere((c) => c?.id == e.key,
                                orElse: () => null);
                            final pct = expense > 0
                                ? (e.value / expense).clamp(0.0, 1.0) : 0.0;
                            final catTxs = txs.where(
                                    (tx) => tx.categoryId == e.key).toList();
                            return _CategoryRow(
                              cat:      cat,
                              amount:   e.value,
                              pct:      pct,
                              currency: widget.currencySymbol,
                              isDark:   isDark,
                              onTap:    cat == null ? null : () =>
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => CategoryTransactionsPage(
                                        category:       cat,
                                        transactions:   catTxs,
                                        currencySymbol: widget.currencySymbol,
                                      ))),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  // ── AppBar with month switcher ────────────────────────────────────────────
  AppBar _buildAppBar(dynamic t, bool isDark) {
    final monthStr = DateFormat('MMMM yyyy').format(_selectedMonth);
    return AppBar(
      backgroundColor:
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(children: [
        Text(t.stats, style: const TextStyle(fontWeight: FontWeight.w700)),
        const Spacer(),
        // ── Month navigator ───────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _MonthBtn(
              icon: Icons.chevron_left_rounded,
              onTap: _goToPrevMonth,
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(monthStr,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textDark : AppColors.textLight)),
            ),
            _MonthBtn(
              icon: Icons.chevron_right_rounded,
              onTap: _isCurrentMonth ? null : _goToNextMonth,
              isDark: isDark,
            ),
          ]),
        ),
      ]),
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight)),
    );
  }

  Widget _buildEmpty(dynamic t, bool isDark) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Iconsax.chart, size: 64,
          color: (isDark ? AppColors.mutedDark : AppColors.mutedLight)
              .withValues(alpha: 0.5)),
      const SizedBox(height: 16),
      Text(t.noData, style: TextStyle(fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.subTextDark : AppColors.subTextLight)),
      const SizedBox(height: 8),
      Text(t.addToSeeStats, style: TextStyle(fontSize: 13,
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight)),
    ]),
  );
}

// ── Month data model ──────────────────────────────────────────────────────────
class _MonthData {
  final DateTime date;
  final double   income, expense;
  const _MonthData({required this.date, required this.income,
    required this.expense});
}

// ── Month nav button ──────────────────────────────────────────────────────────
class _MonthBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  final bool          isDark;
  const _MonthBtn({required this.icon, required this.onTap,
    required this.isDark});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Icon(icon, size: 22,
          color: onTap == null
              ? (isDark ? AppColors.mutedDark : AppColors.mutedLight)
              .withValues(alpha: 0.4)
              : isDark ? AppColors.textDark : AppColors.textLight),
    ),
  );
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  final bool   isDark;
  const _SectionHeader(this.text, {required this.isDark});
  @override Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDark : AppColors.textLight));
}

// ── Summary cards ─────────────────────────────────────────────────────────────
class _SummaryCards extends StatelessWidget {
  final double income, expense, balance, savingsRate;
  final String currency;
  final bool   isDark;
  final dynamic t;
  const _SummaryCards({required this.income, required this.expense,
    required this.balance, required this.savingsRate,
    required this.currency, required this.isDark, required this.t});

  @override Widget build(BuildContext context) {
    return Column(children: [
      // Top row: income + expense
      Row(children: [
        Expanded(child: _SummaryCard(
          label:    t.income,
          value:    CurrencyFormatter.formatCompact(income, currency),
          icon:     Iconsax.arrow_up_3,
          color:    AppColors.income,
          isDark:   isDark,
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(
          label:    t.expense,
          value:    CurrencyFormatter.formatCompact(expense, currency),
          icon:     Iconsax.arrow_down,
          color:    AppColors.expense,
          isDark:   isDark,
        )),
      ]),
      const SizedBox(height: 12),
      // Bottom row: balance + savings rate
      Row(children: [
        Expanded(child: _SummaryCard(
          label:    t.balance,
          value:    CurrencyFormatter.formatCompact(balance.abs(), currency),
          icon:     Iconsax.wallet_3,
          color:    balance >= 0 ? AppColors.gold : AppColors.expense,
          isDark:   isDark,
          prefix:   balance < 0 ? '- ' : '',
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(
          label:    t.savingsRate,
          value:    '${savingsRate.toStringAsFixed(1)}%',
          icon:     Iconsax.chart_success,
          color:    savingsRate >= 20
              ? AppColors.income
              : savingsRate >= 5
              ? AppColors.gold
              : AppColors.expense,
          isDark:   isDark,
        )),
      ]),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final String   label, value;
  final String   prefix;
  final IconData icon;
  final Color    color;
  final bool     isDark;
  const _SummaryCard({required this.label, required this.value,
    required this.icon, required this.color, required this.isDark,
    this.prefix = ''});

  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        isDark ? AppColors.cardDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight),
      boxShadow: isDark ? [] : [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const Spacer(),
      ]),
      const SizedBox(height: 12),
      Text('$prefix$value',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 12,
          color: isDark ? AppColors.subTextDark : AppColors.subTextLight)),
    ]),
  );
}

// ── 6-month trend chart ───────────────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  final List<_MonthData> data;
  final bool             loading;
  final String           currency;
  final bool             isDark;
  final dynamic          t;
  final DateTime         selected;
  const _TrendChart({required this.data, required this.loading,
    required this.currency, required this.isDark,
    required this.t, required this.selected});

  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: loading
          ? const SizedBox(height: 160,
          child: Center(child: CircularProgressIndicator(
              color: AppColors.gold, strokeWidth: 2)))
          : data.isEmpty
          ? SizedBox(height: 160,
          child: Center(child: Text(t.noData,
              style: TextStyle(color: isDark
                  ? AppColors.subTextDark : AppColors.subTextLight))))
          : _buildChart(context),
    );
  }

  Widget _buildChart(BuildContext context) {
    final maxVal = data.map((d) => max(d.income, d.expense))
        .fold(0.0, max);
    final maxY = maxVal <= 0 ? 100.0 : maxVal * 1.25;
    final gridColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(children: [
      SizedBox(
          height: 160,
          child: BarChart(BarChartData(
            maxY: maxY,
            gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: gridColor, strokeWidth: 0.8)),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  final d = data[i];
                  final isSelected = d.date.year == selected.year &&
                      d.date.month == selected.month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('MMM').format(d.date),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w800 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.gold
                                : isDark ? AppColors.subTextDark
                                : AppColors.subTextLight)),
                  );
                },
              )),
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(data.length, (i) {
              final d = data[i];
              final isSelected = d.date.year == selected.year &&
                  d.date.month == selected.month;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: d.income,
                  color: AppColors.income.withValues(
                      alpha: isSelected ? 1.0 : 0.45),
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: d.expense,
                  color: AppColors.expense.withValues(
                      alpha: isSelected ? 1.0 : 0.45),
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ]);
            }),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => isDark
                    ? AppColors.surfaceDark : Colors.white,
                getTooltipItem: (group, _, rod, rodIndex) {
                  final d = data[group.x];
                  final label = rodIndex == 0 ? t.income : t.expense;
                  return BarTooltipItem(
                    '$label\n${CurrencyFormatter.formatCompact(rod.toY, currency)}',
                    TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: rodIndex == 0
                            ? AppColors.income : AppColors.expense),
                  );
                },
              ),
            ),
            groupsSpace: 12,
          ),
            swapAnimationDuration: const Duration(milliseconds: 600),
            swapAnimationCurve: Curves.easeOutCubic,
          )),
      const SizedBox(height: 12),
      // Legend
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _dot(AppColors.income, t.income, isDark),
        const SizedBox(width: 20),
        _dot(AppColors.expense, t.expense, isDark),
      ]),
    ]);
  }

  Widget _dot(Color color, String label, bool isDark) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 11,
          color: isDark ? AppColors.subTextDark : AppColors.subTextLight)),
    ],
  );
}

// ── Daily spending line chart ─────────────────────────────────────────────────
class _DailyChart extends StatelessWidget {
  final Map<int, double> dailySpend;
  final DateTime         month;
  final String           currency;
  final bool             isDark;
  const _DailyChart({required this.dailySpend, required this.month,
    required this.currency, required this.isDark});

  @override Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final spots = <FlSpot>[];
    for (int d = 1; d <= daysInMonth; d++) {
      spots.add(FlSpot(d.toDouble(), dailySpend[d] ?? 0));
    }
    final maxY = spots.map((s) => s.y).fold(0.0, max);
    final gridColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: SizedBox(
        height: 140,
        child: LineChart(LineChartData(
          minX: 1, maxX: daysInMonth.toDouble(),
          minY: 0, maxY: maxY <= 0 ? 100 : maxY * 1.3,
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY <= 0 ? 50 : maxY * 1.3 / 4,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: gridColor, strokeWidth: 0.8)),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 22,
              interval: daysInMonth > 20 ? 7 : 5,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${v.toInt()}',
                    style: TextStyle(fontSize: 9,
                        color: isDark
                            ? AppColors.subTextDark : AppColors.subTextLight)),
              ),
            )),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.expense,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot.y > 0,
                getDotPainter: (spot, _, __, ___) =>
                    FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.expense,
                        strokeWidth: 1.5,
                        strokeColor: isDark
                            ? AppColors.cardDark : Colors.white),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.expense.withValues(alpha: 0.25),
                    AppColors.expense.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => isDark
                  ? AppColors.surfaceDark : Colors.white,
              getTooltipItems: (spots) => spots.map((s) =>
                  LineTooltipItem(
                    'Day ${s.x.toInt()}\n${CurrencyFormatter.formatCompact(s.y, currency)}',
                    TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppColors.expense),
                  )).toList(),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

// ── Pie + legend ──────────────────────────────────────────────────────────────
class _PieSection extends StatefulWidget {
  final Map<String, double>    byCategory;
  final List<CategoryEntity>   categories;
  final double                 totalExpense;
  final bool                   isDark;
  const _PieSection({required this.byCategory, required this.categories,
    required this.totalExpense, required this.isDark});
  @override State<_PieSection> createState() => _PieSectionState();
}

class _PieSectionState extends State<_PieSection> {
  int _touched = -1;

  @override Widget build(BuildContext context) {
    final sorted = widget.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = widget.byCategory.values.fold(0.0, (a, b) => a + b);

    final sections = sorted.asMap().entries.map((e) {
      final i   = e.key;
      final ent = e.value;
      final cat = widget.categories.cast<CategoryEntity?>()
          .firstWhere((c) => c?.id == ent.key, orElse: () => null);
      final pct = total > 0 ? (ent.value / total * 100) : 0.0;
      final isTouched = i == _touched;
      return PieChartSectionData(
        value:    ent.value,
        color:    cat?.color ?? AppColors.gold,
        title:    pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
        radius:   isTouched ? 72 : 60,
        titleStyle: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        widget.isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: widget.isDark
            ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(children: [
        // Pie
        SizedBox(
          width: 160, height: 160,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 36,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (ev, resp) {
                  setState(() {
                    _touched = (ev is FlTapUpEvent || ev is FlPanEndEvent ||
                        resp == null || resp.touchedSection == null)
                        ? -1
                        : resp.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 500),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sorted.take(6).toList().asMap().entries.map((e) {
            final i   = e.key;
            final ent = e.value;
            final cat = widget.categories.cast<CategoryEntity?>()
                .firstWhere((c) => c?.id == ent.key, orElse: () => null);
            final pct = total > 0
                ? (ent.value / total * 100) : 0.0;
            final color = cat?.color ?? AppColors.gold;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Expanded(child: Text(cat?.name ?? '?',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? AppColors.textDark : AppColors.textLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('${pct.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: color)),
              ]),
            );
          }).toList(),
        )),
      ]),
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────────
class _CategoryRow extends StatefulWidget {
  final CategoryEntity? cat;
  final double          amount, pct;
  final String          currency;
  final bool            isDark;
  final VoidCallback?   onTap;
  const _CategoryRow({required this.cat, required this.amount,
    required this.pct, required this.currency, required this.isDark,
    required this.onTap});
  @override State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _bar;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _bar  = Tween<double>(begin: 0, end: widget.pct)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300),
            () { if (mounted) _ctrl.forward(); });
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final color = widget.cat?.color ?? AppColors.gold;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.cardDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isDark
                ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: widget.cat?.emoji != null
                    ? Center(child: Text(widget.cat!.emoji!,
                    style: const TextStyle(fontSize: 16)))
                    : Icon(widget.cat?.icon ?? Iconsax.more_circle,
                    color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.cat?.name ?? '?',
                  style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? AppColors.textDark : AppColors.textLight))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(CurrencyFormatter.format(widget.amount, widget.currency),
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.expense)),
                Text('${(widget.pct * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11,
                        color: widget.isDark
                            ? AppColors.mutedDark : AppColors.mutedLight)),
              ]),
              if (widget.onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 16,
                    color: widget.isDark
                        ? AppColors.mutedDark : AppColors.mutedLight),
              ],
            ]),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _bar,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _bar.value,
                  minHeight: 4,
                  backgroundColor: widget.isDark
                      ? AppColors.borderDark : AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}