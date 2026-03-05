import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/i18n/language_provider.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/budget/budget_bloc.dart';
import '../blocs/category/category_bloc.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/error_widgets.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_page.dart';

class HomePage extends StatefulWidget {
  final String currencySymbol;
  const HomePage({super.key, required this.currencySymbol});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadData();
  }

  void _loadData() {
    context.read<TransactionBloc>().add(LoadTransactions(
        month: _selectedMonth.month, year: _selectedMonth.year));
    context.read<BudgetBloc>().add(LoadBudget(
        month: _selectedMonth.month, year: _selectedMonth.year));
    context.read<CategoryBloc>().add(LoadCategories());
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cho'ntak",
          style: TextStyle(
              color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 22),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthSelector(
              month: _selectedMonth,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 16),

            // Summary cards
            BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading || state is TransactionInitial) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                  );
                }
                if (state is! TransactionLoaded) return const SizedBox.shrink();
                return Column(children: [
                  Row(children: [
                    Expanded(child: SummaryCard(
                      label: t.income, amount: state.totalIncome,
                      icon: Iconsax.arrow_down, color: AppColors.income,
                      currencySymbol: widget.currencySymbol,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: SummaryCard(
                      label: t.expense, amount: state.totalExpense,
                      icon: Iconsax.arrow_up, color: AppColors.expense,
                      currencySymbol: widget.currencySymbol,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  SummaryCard(
                    label: t.balance,
                    amount: state.balance.abs(),
                    icon: state.balance >= 0 ? Iconsax.wallet_check : Iconsax.wallet_minus,
                    color: state.balance >= 0 ? AppColors.gold : AppColors.expense,
                    currencySymbol: state.balance < 0
                        ? '-${widget.currencySymbol}' : widget.currencySymbol,
                  ),
                ]);
              },
            ),
            const SizedBox(height: 16),

            // Budget card
            BlocBuilder<BudgetBloc, BudgetState>(
              builder: (context, state) {
                if (state is BudgetLoaded) {
                  return Column(children: [
                    BudgetProgressCard(
                        budget: state.budget,
                        currencySymbol: widget.currencySymbol,
                        t: t),
                    const SizedBox(height: 16),
                  ]);
                }
                if (state is BudgetNotSet) {
                  return _SetBudgetBanner(
                      month: _selectedMonth.month,
                      year: _selectedMonth.year,
                      t: t);
                }
                return const SizedBox.shrink();
              },
            ),

            // Transactions header
            Text(t.transactions,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            // Transactions list
            BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, txState) {
                return BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, catState) {
                    if (txState is TransactionLoading || txState is TransactionInitial) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: AppColors.gold),
                        ),
                      );
                    }
                    if (txState is! TransactionLoaded) return const SizedBox.shrink();
                    if (txState.transactions.isEmpty) return _EmptyState(t: t);

                    final categories =
                    catState is CategoryLoaded ? catState.categories : [];
                    return Column(
                      children: txState.transactions.asMap().entries.map((entry) {
                        final tx = entry.value;
                        final cat = categories.cast<dynamic>().firstWhere(
                              (c) => c.id == tx.categoryId,
                          orElse: () => null,
                        );
                        return GestureDetector(
                          onTap: () => TransactionDetailPage.show(
                            context,
                            transaction: tx,
                            currencySymbol: widget.currencySymbol,
                            category: cat,
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTransactionPage(
                                    currencySymbol: widget.currencySymbol,
                                    existing: tx),
                              ),
                            ).then((_) => _loadData()),
                            onDelete: () => _confirmDelete(context, tx.id, t),
                          ),
                          child: TransactionTile(
                            transaction: tx,
                            category: cat,
                            index: entry.key,
                            currencySymbol: widget.currencySymbol,
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTransactionPage(
                                    currencySymbol: widget.currencySymbol,
                                    existing: tx),
                              ),
                            ).then((_) => _loadData()),
                            onDelete: () => _confirmDelete(context, tx.id, t),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: _PulseFab(
        label: t.add,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddTransactionPage(currencySymbol: widget.currencySymbol),
          ),
        ).then((_) => _loadData()),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.deleteTitle),
        content: Text(t.deleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TransactionBloc>().add(DeleteTransactionEvent(
                id,
                month: _selectedMonth.month,
                year: _selectedMonth.year,
              ));
            },
            child: Text(t.delete,
                style: const TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthSelector({required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrev,
            icon: const Icon(Iconsax.arrow_left_2, color: AppColors.gold)),
        Text(DateFormatter.formatMonth(month),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        IconButton(onPressed: onNext,
            icon: const Icon(Iconsax.arrow_right_2, color: AppColors.gold)),
      ],
    );
  }
}

class _SetBudgetBanner extends StatelessWidget {
  final int month, year;
  final dynamic t;
  const _SetBudgetBanner({required this.month, required this.year, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Iconsax.wallet_add, color: AppColors.gold),
        const SizedBox(width: 12),
        Expanded(child: Text(t.noBudget, style: const TextStyle(fontSize: 13))),
        TextButton(
          onPressed: () => _showDialog(context),
          child: Text(t.setBudget, style: const TextStyle(color: AppColors.gold)),
        ),
      ]),
    );
  }

  void _showDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.monthlyBudget),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t.budgetAmount),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                context.read<BudgetBloc>().add(
                    SetBudgetEvent(limit: val, month: month, year: year));
                Navigator.pop(context);
              }
            },
            child: Text(t.set),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic t;
  const _EmptyState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(children: [
          Icon(Iconsax.empty_wallet, size: 56, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(t.noTransactions,
              style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          const SizedBox(height: 4),
          Text(t.addFirst,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── Carryover card ────────────────────────────────────────────────────────────
class _CarryoverCard extends StatelessWidget {
  final double carryover;
  final String currencySymbol;
  final dynamic t;

  const _CarryoverCard({
    required this.carryover,
    required this.currencySymbol,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final isPositive = carryover >= 0;
    final color     = isPositive ? AppColors.income : AppColors.expense;
    final sign      = isPositive ? '+' : '-';
    final formatted = CurrencyFormatter.formatCompact(
        carryover.abs(), currencySymbol);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.clock, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.carryover,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$sign$formatted',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing FAB ───────────────────────────────────────────────────────────────
class _PulseFab extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _PulseFab({required this.label, required this.onPressed});

  @override
  State<_PulseFab> createState() => _PulseFabState();
}

class _PulseFabState extends State<_PulseFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: widget.onPressed,
          icon: const Icon(Iconsax.add),
          label: Text(widget.label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}