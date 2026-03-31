import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/i18n/language_provider.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/budget/budget_bloc.dart';
import '../blocs/category/category_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/error_widgets.dart';
import 'add_transaction_page.dart';
import 'category_budget_page.dart';
import '../blocs/category_budget/category_budget_bloc.dart';
import 'transaction_detail_page.dart';

class HomePage extends StatefulWidget {
  final String currencySymbol;
  const HomePage({super.key, required this.currencySymbol});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  bool   _historyExpanded = false;
  String? _txFilter;   // null = all, 'income', 'expense'
  String  _searchQuery  = '';
  bool    _searchActive = false;
  final   _searchCtrl   = TextEditingController();
  final   _searchFocus  = FocusNode();
  final   _scrollCtrl   = ScrollController();
  final   _searchKey    = GlobalKey();

  // ── Advanced filter state ──────────────────────────────────────
  Set<String> _filterCategories = {};     // empty = all categories
  double?     _filterAmountMin;
  double?     _filterAmountMax;
  DateTime?   _filterDateFrom;
  DateTime?   _filterDateTo;

  bool get _hasActiveFilters =>
      _filterCategories.isNotEmpty ||
          _filterAmountMin != null ||
          _filterAmountMax != null ||
          _filterDateFrom  != null ||
          _filterDateTo    != null;

  void _clearAllFilters() => setState(() {
    _txFilter         = null;
    _filterCategories = {};
    _filterAmountMin  = null;
    _filterAmountMax  = null;
    _filterDateFrom   = null;
    _filterDateTo     = null;
    _searchQuery      = '';
    _searchCtrl.clear();
    _searchActive     = false;
  });
  late AnimationController _expandCtrl;
  late Animation<double>   _expandAnim;
  late Animation<double>   _chevronAnim;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    // postFrameCallback ensures BLoC providers are mounted before dispatch
    // Without this, release builds silently drop the event
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _expandAnim = CurvedAnimation(
        parent: _expandCtrl, curve: Curves.easeInOutCubic);
    _chevronAnim = Tween<double>(begin: 0.0, end: 0.5)
        .animate(CurvedAnimation(
        parent: _expandCtrl, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    context.read<TransactionBloc>().add(LoadTransactions(
        month: _selectedMonth.month, year: _selectedMonth.year));
    context.read<BudgetBloc>().add(LoadBudget(
        month: _selectedMonth.month, year: _selectedMonth.year));
    context.read<CategoryBloc>().add(LoadCategories());
  }

  void _changeMonth(int delta) {
    setState(() => _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + delta));
    _loadData();
  }

  void _toggleHistory() {
    setState(() => _historyExpanded = !_historyExpanded);
    _historyExpanded
        ? _expandCtrl.forward()
        : _expandCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final t           = context.watch<LanguageProvider>().t;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.bgDark : AppColors.bgLight,
      resizeToAvoidBottomInset: false,  // We handle insets manually
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: _searchActive
              ? MediaQuery.of(context).viewInsets.bottom
              : 0,
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            _loadData();
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: AppColors.amber,
          backgroundColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          displacement: 60,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Hero header ─────────────────────────────
              SliverToBoxAdapter(
                child: _HeroCard(
                  currencySymbol: widget.currencySymbol,
                  selectedMonth: _selectedMonth,
                  onPrev: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                  t: t,
                  isDark: isDark,
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Income / Expense ───────────────────
                    BlocBuilder<TransactionBloc, TransactionState>(
                      builder: (ctx, state) {
                        if (state is TransactionLoading ||
                            state is TransactionInitial) {
                          return const HomeLoadingSkeleton();
                        }
                        if (state is TransactionError) {
                          return ErrorScreen(
                            title: 'Xato',
                            message: state.message,
                            onRetry: () {
                              final n = DateTime.now();
                              ctx.read<TransactionBloc>().add(
                                  LoadTransactions(
                                      month: n.month, year: n.year));
                            },
                          );
                        }
                        if (state is! TransactionLoaded) {
                          return const SizedBox.shrink();
                        }
                        return Row(children: [
                          Expanded(
                            child: _StatPill(
                              label: t.income,
                              amount: state.totalIncome,
                              icon: Icons.south_rounded,
                              color: AppColors.income,
                              currencySymbol: widget.currencySymbol,
                              isDark: isDark,
                              isActive: _txFilter == 'income',
                              onTap: () => setState(() =>
                              _txFilter = _txFilter == 'income' ? null : 'income'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatPill(
                              label: t.expense,
                              amount: state.totalExpense,
                              icon: Icons.north_rounded,
                              color: AppColors.expense,
                              currencySymbol: widget.currencySymbol,
                              isDark: isDark,
                              isActive: _txFilter == 'expense',
                              onTap: () => setState(() =>
                              _txFilter = _txFilter == 'expense' ? null : 'expense'),
                            ),
                          ),
                        ]);
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Budget ─────────────────────────────
                    BlocBuilder<BudgetBloc, BudgetState>(
                      builder: (ctx, state) {
                        if (state is BudgetLoaded) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: BudgetProgressCard(
                              budget: state.budget,
                              currencySymbol: widget.currencySymbol,
                              t: t,
                            ),
                          );
                        }
                        if (state is BudgetNotSet) {
                          return _BudgetBanner(
                              month: _selectedMonth.month,
                              year: _selectedMonth.year,
                              t: t,
                              isDark: isDark);
                        }
                        if (state is BudgetError) {
                          return ErrorBanner(
                            message: 'Byudjet yuklanmadi',
                            onRetry: () {
                              final n = DateTime.now();
                              ctx.read<BudgetBloc>().add(
                                  LoadBudget(month: n.month, year: n.year));
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // ── Transactions ───────────────────────
                    BlocBuilder<TransactionBloc, TransactionState>(
                      builder: (ctx, txState) {
                        if (txState is! TransactionLoaded) {
                          return const SizedBox.shrink();
                        }
                        // Apply income/expense filter + search
                        final allTxs = txState.transactions;
                        var txs = _txFilter == null
                            ? allTxs
                            : allTxs.where((tx) =>
                        (_txFilter == 'income'
                            ? tx.type == TransactionType.income
                            : tx.type == TransactionType.expense))
                            .toList();
                        if (_searchQuery.isNotEmpty) {
                          final q = _searchQuery.toLowerCase();
                          txs = txs.where((tx) =>
                          tx.title.toLowerCase().contains(q) ||
                              (tx.note?.toLowerCase().contains(q) ?? false))
                              .toList();
                        }
                        // ── Category filter ──────────────────────────
                        if (_filterCategories.isNotEmpty) {
                          txs = txs.where((tx) =>
                              _filterCategories.contains(tx.categoryId)).toList();
                        }
                        // ── Amount range filter ───────────────────────
                        if (_filterAmountMin != null) {
                          txs = txs.where((tx) =>
                          tx.amount >= _filterAmountMin!).toList();
                        }
                        if (_filterAmountMax != null) {
                          txs = txs.where((tx) =>
                          tx.amount <= _filterAmountMax!).toList();
                        }
                        // ── Date range filter ─────────────────────────
                        if (_filterDateFrom != null) {
                          txs = txs.where((tx) =>
                          !tx.date.isBefore(_filterDateFrom!)).toList();
                        }
                        if (_filterDateTo != null) {
                          final to = _filterDateTo!
                              .add(const Duration(days: 1));
                          txs = txs.where((tx) =>
                              tx.date.isBefore(to)).toList();
                        }
                        final count = txs.length;

                        return BlocBuilder<CategoryBloc, CategoryState>(
                          builder: (ctx2, catState) {
                            final cats = catState is CategoryLoaded
                                ? catState.categories
                                : <dynamic>[];

                            CategoryEntity? findCat(String id) =>
                                cats.cast<dynamic>().firstWhere(
                                        (c) => c.id == id,
                                    orElse: () => null);

                            Widget tileFor(int i) {
                              final tx  = txs[i];
                              final cat = findCat(tx.categoryId);
                              return Dismissible(
                                key: ValueKey(tx.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  // Quick haptic on swipe
                                  bool confirmed = false;
                                  await showDialog(
                                    context: ctx,
                                    builder: (_) => AlertDialog(
                                      title: Text(t.deleteTitle),
                                      content: Text(t.deleteBody),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text(t.cancel),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            confirmed = true;
                                            Navigator.pop(ctx, true);
                                          },
                                          child: Text(t.delete,
                                              style: const TextStyle(
                                                  color: AppColors.expense)),
                                        ),
                                      ],
                                    ),
                                  );
                                  return confirmed;
                                },
                                onDismissed: (_) {
                                  ctx.read<TransactionBloc>().add(
                                    DeleteTransactionEvent(
                                      tx.id,
                                      month: _selectedMonth.month,
                                      year:  _selectedMonth.year,
                                    ),
                                  );
                                },
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.expense.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.expense.withValues(alpha: 0.4)),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.delete_outline_rounded,
                                          color: AppColors.expense, size: 24),
                                      const SizedBox(height: 4),
                                      Text(t.delete,
                                          style: const TextStyle(
                                              color: AppColors.expense,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                child: TransactionTile(
                                  transaction:    tx,
                                  category:       cat,
                                  index:          i,
                                  currencySymbol: widget.currencySymbol,
                                  onTap: () => TransactionDetailPage.show(
                                    ctx,
                                    transaction:    tx,
                                    currencySymbol: widget.currencySymbol,
                                    category:       cat,
                                    onEdit: () => Navigator.push(ctx,
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionPage(
                                          currencySymbol: widget.currencySymbol,
                                          existing: tx,
                                        ),
                                      ),
                                    ).then((_) => _loadData()),
                                    onDelete: () =>
                                        _confirmDelete(ctx, tx.id, t),
                                  ),
                                  onEdit: () => Navigator.push(ctx,
                                    MaterialPageRoute(
                                      builder: (_) => AddTransactionPage(
                                        currencySymbol: widget.currencySymbol,
                                        existing: tx,
                                      ),
                                    ),
                                  ).then((_) => _loadData()),
                                  onDelete: () =>
                                      _confirmDelete(ctx, tx.id, t),
                                ),  // TransactionTile
                              );  // Dismissible
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Header: title + Hammasi + search icon
                                SizedBox(key: _searchKey, height: 0),
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 250),
                                  crossFadeState: _searchActive
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  sizeCurve: Curves.easeInOut,
                                  firstChild: Row(
                                    children: [
                                      Text(
                                        _txFilter == 'income' ? t.income
                                            : _txFilter == 'expense' ? t.expense : t.transactions,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                            color: isDark ? AppColors.textDark : AppColors.textLight),
                                      ),
                                      if (_txFilter != null) ...[
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => setState(() => _txFilter = null),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (_txFilter == 'income' ? AppColors.income : AppColors.expense)
                                                  .withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.close_rounded, size: 12,
                                                  color: _txFilter == 'income' ? AppColors.income : AppColors.expense),
                                              const SizedBox(width: 3),
                                              Text(t.clear, style: TextStyle(fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: _txFilter == 'income' ? AppColors.income : AppColors.expense)),
                                            ]),
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      if (count > 3)
                                        GestureDetector(
                                          onTap: _toggleHistory,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _historyExpanded
                                                  ? AppColors.accent.withValues(alpha: 0.12)
                                                  : (isDark ? AppColors.cardDark : AppColors.cardLight),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: _historyExpanded
                                                  ? AppColors.accent.withValues(alpha: 0.4)
                                                  : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                                            ),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              Text(_historyExpanded ? t.close : '${t.showAll} ($count)',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                                      color: _historyExpanded ? AppColors.accent
                                                          : (isDark ? AppColors.subTextDark : AppColors.subTextLight))),
                                              const SizedBox(width: 3),
                                              RotationTransition(turns: _chevronAnim,
                                                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 14,
                                                      color: _historyExpanded ? AppColors.accent
                                                          : (isDark ? AppColors.subTextDark : AppColors.subTextLight))),
                                            ]),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() { _searchActive = true; _searchQuery = ''; });
                                          Future.delayed(const Duration(milliseconds: 100),
                                                  () { if (mounted) _searchFocus.requestFocus(); });
                                        },
                                        child: Container(
                                          width: 34, height: 34,
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.cardDark : AppColors.bgLight,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: isDark
                                                ? AppColors.borderDark : AppColors.borderLight),
                                          ),
                                          child: Icon(Icons.search_rounded, size: 16,
                                              color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // ── Filter button ──────────────────
                                      GestureDetector(
                                        onTap: () => _showFilterSheet(
                                            context, cats.cast<CategoryEntity>(), isDark, t),
                                        child: Container(
                                          width: 34, height: 34,
                                          decoration: BoxDecoration(
                                            color: _hasActiveFilters
                                                ? AppColors.accent.withValues(alpha: 0.15)
                                                : (isDark ? AppColors.cardDark : AppColors.bgLight),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: _hasActiveFilters
                                                ? AppColors.accent
                                                : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(Iconsax.filter, size: 15,
                                                  color: _hasActiveFilters
                                                      ? AppColors.accent
                                                      : (isDark ? AppColors.mutedDark : AppColors.mutedLight)),
                                              if (_hasActiveFilters)
                                                Positioned(top: 5, right: 5,
                                                    child: Container(width: 6, height: 6,
                                                        decoration: const BoxDecoration(
                                                            color: AppColors.accent,
                                                            shape: BoxShape.circle))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  secondChild: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: _searchQuery.isNotEmpty
                                                    ? AppColors.amber.withValues(alpha: 0.6)
                                                    : isDark ? AppColors.borderDark : AppColors.borderLight,
                                                width: _searchQuery.isNotEmpty ? 1.5 : 1),
                                          ),
                                          child: TextField(
                                            controller: _searchCtrl,
                                            focusNode: _searchFocus,
                                            onChanged: (v) => setState(() => _searchQuery = v),
                                            style: TextStyle(fontSize: 14,
                                                color: isDark ? Colors.white : AppColors.navyText),
                                            decoration: InputDecoration(
                                              hintText: 'Qidirish...',
                                              hintStyle: TextStyle(fontSize: 14,
                                                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
                                              prefixIcon: Icon(Icons.search_rounded, size: 16,
                                                  color: _searchQuery.isNotEmpty ? AppColors.amber
                                                      : isDark ? AppColors.mutedDark : AppColors.mutedLight),
                                              suffixIcon: _searchQuery.isNotEmpty
                                                  ? GestureDetector(
                                                  onTap: () { setState(() => _searchQuery = ''); _searchCtrl.clear(); },
                                                  child: Icon(Icons.close_rounded, size: 14,
                                                      color: isDark ? AppColors.mutedDark : AppColors.mutedLight))
                                                  : null,
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _searchActive = false; _searchQuery = '';
                                            _searchCtrl.clear(); _searchFocus.unfocus();
                                          });
                                        },
                                        child: Text(t.cancelShort, style: TextStyle(fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                if (txs.isEmpty)
                                  _EmptyTxState(isDark: isDark, t: t)
                                else ...[
                                  // Always show first 3
                                  for (int i = 0;
                                  i < txs.length.clamp(0, 3);
                                  i++)
                                    tileFor(i),

                                  // Expandable rest
                                  if (count > 3)
                                    SizeTransition(
                                      sizeFactor: _expandAnim,
                                      axisAlignment: -1,
                                      child: FadeTransition(
                                        opacity: _expandAnim,
                                        child: Column(
                                          children: [
                                            for (int i = 3;
                                            i < count;
                                            i++)
                                              tileFor(i),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),  // CustomScrollView
        ),  // RefreshIndicator
      ),  // AnimatedPadding
      floatingActionButton: _searchActive ? null : _AddFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionPage(
                currencySymbol: widget.currencySymbol),
          ),
        ).then((_) => _loadData()),
      ),
    );
  }

  // ── Filter bottom sheet ─────────────────────────────────────────────────────
  void _showFilterSheet(BuildContext ctx,
      List<CategoryEntity> categories, bool isDark, dynamic t) {
    // Local copies to allow preview before applying
    var tmpType       = _txFilter;
    var tmpCats       = Set<String>.from(_filterCategories);
    var tmpAmtMin     = _filterAmountMin;
    var tmpAmtMax     = _filterAmountMax;
    var tmpDateFrom   = _filterDateFrom;
    var tmpDateTo     = _filterDateTo;
    final minCtrl = TextEditingController(
        text: tmpAmtMin?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(
        text: tmpAmtMax?.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setSheet) => Container(
          height: MediaQuery.of(ctx).size.height * 0.82,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Text(t.filter, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDark : AppColors.textLight)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setSheet(() {
                      tmpType = null; tmpCats = {};
                      tmpAmtMin = null; tmpAmtMax = null;
                      tmpDateFrom = null; tmpDateTo = null;
                      minCtrl.clear(); maxCtrl.clear();
                    });
                  },
                  child: Text(t.clearAll,
                      style: const TextStyle(color: AppColors.accent)),
                ),
              ]),
            ),
            Divider(color: isDark
                ? AppColors.borderDark : AppColors.borderLight),
            // Body
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [

                // ── Type ─────────────────────────────────────────
                _FilterSection(t.type, isDark: isDark),
                const SizedBox(height: 10),
                Row(children: [
                  _FilterChip(
                    label: t.income,
                    selected: tmpType == 'income',
                    color: AppColors.income,
                    onTap: () => setSheet(() =>
                    tmpType = tmpType == 'income' ? null : 'income'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: t.expense,
                    selected: tmpType == 'expense',
                    color: AppColors.expense,
                    onTap: () => setSheet(() =>
                    tmpType = tmpType == 'expense' ? null : 'expense'),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Categories ────────────────────────────────────
                _FilterSection(t.categories, isDark: isDark),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8,
                  children: categories.map((cat) {
                    final sel = tmpCats.contains(cat.id);
                    return _FilterChip(
                      label: cat.emoji != null
                          ? '${cat.emoji} ${cat.name}'
                          : cat.name,
                      selected: sel,
                      color: cat.color,
                      onTap: () => setSheet(() {
                        if (sel) tmpCats.remove(cat.id);
                        else     tmpCats.add(cat.id);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Amount range ──────────────────────────────────
                _FilterSection(t.amountRange, isDark: isDark),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _FilterInput(
                    ctrl:        minCtrl,
                    hint:        t.min,
                    currency:    widget.currencySymbol,
                    isDark:      isDark,
                    onChanged:   (v) => tmpAmtMin =
                        double.tryParse(v),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('—', style: TextStyle(
                        color: isDark
                            ? AppColors.subTextDark
                            : AppColors.subTextLight)),
                  ),
                  Expanded(child: _FilterInput(
                    ctrl:      maxCtrl,
                    hint:      t.max,
                    currency:  widget.currencySymbol,
                    isDark:    isDark,
                    onChanged: (v) => tmpAmtMax =
                        double.tryParse(v),
                  )),
                ]),
                const SizedBox(height: 20),

                // ── Date range ────────────────────────────────────
                _FilterSection(t.dateRange, isDark: isDark),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _DatePickerBtn(
                    label:   tmpDateFrom == null
                        ? t.from
                        : '${tmpDateFrom!.day}/${tmpDateFrom!.month}/${tmpDateFrom!.year}',
                    isDark:  isDark,
                    onTap:   () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: tmpDateFrom ?? DateTime.now(),
                        firstDate:   DateTime(2020),
                        lastDate:    DateTime.now(),
                        builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                                colorScheme: ColorScheme.dark(
                                    primary: AppColors.gold,
                                    surface: isDark
                                        ? AppColors.cardDark : Colors.white)),
                            child: child!),
                      );
                      if (d != null) setSheet(() => tmpDateFrom = d);
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _DatePickerBtn(
                    label:   tmpDateTo == null
                        ? t.to
                        : '${tmpDateTo!.day}/${tmpDateTo!.month}/${tmpDateTo!.year}',
                    isDark:  isDark,
                    onTap:   () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: tmpDateTo ?? DateTime.now(),
                        firstDate:   DateTime(2020),
                        lastDate:    DateTime.now(),
                        builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                                colorScheme: ColorScheme.dark(
                                    primary: AppColors.gold,
                                    surface: isDark
                                        ? AppColors.cardDark : Colors.white)),
                            child: child!),
                      );
                      if (d != null) setSheet(() => tmpDateTo = d);
                    },
                  )),
                ]),
              ],
            )),
            // Apply button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _txFilter          = tmpType;
                      _filterCategories  = tmpCats;
                      _filterAmountMin   = tmpAmtMin;
                      _filterAmountMax   = tmpAmtMax;
                      _filterDateFrom    = tmpDateFrom;
                      _filterDateTo      = tmpDateTo;
                    });
                    Navigator.pop(ctx2);
                  },
                  child: Text(t.applyFilter, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
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
                year:  _selectedMonth.year,
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


// ─────────────────────────────────────────────────────────────────────────────
// HERO CARD — gradient bg, large balance, month pill
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String currencySymbol;
  final DateTime selectedMonth;
  final VoidCallback onPrev, onNext;
  final dynamic t;
  final bool isDark;
  const _HeroCard({
    required this.currencySymbol,
    required this.selectedMonth,
    required this.onPrev,
    required this.onNext,
    required this.t,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Card gradient — subtle, not garish
    final gradStart = isDark
        ? const Color(0xFF1A1D2E)
        : const Color(0xFF6C63FF);
    final gradEnd   = isDark
        ? const Color(0xFF0D0F14)
        : const Color(0xFF4A43CC);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradStart, gradEnd],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar — logo + month selector
              Row(
                children: [
                  const Text(
                    "Cho'ntak",
                    style: TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // Month pill
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Chevron(
                            icon: Icons.chevron_left_rounded,
                            onTap: onPrev),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2),
                          child: Text(
                            DateFormatter.formatMonth(selectedMonth),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _Chevron(
                            icon: Icons.chevron_right_rounded,
                            onTap: onNext),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Balance label
              Text(
                t.balance,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.65),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),

              // Balance amount
              BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is! TransactionLoaded) {
                    return const _BalanceSkeleton();
                  }
                  return _AnimatedBalance(
                    amount: state.balance,
                    currencySymbol: currencySymbol,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Chevron({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.all(7),
      child: Icon(icon, size: 16,
          color: Colors.white.withValues(alpha: 0.9)),
    ),
  );
}

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    width: 200,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class _AnimatedBalance extends StatefulWidget {
  final double amount;
  final String currencySymbol;
  const _AnimatedBalance(
      {required this.amount, required this.currencySymbol});

  @override
  State<_AnimatedBalance> createState() => _AnimatedBalanceState();
}

class _AnimatedBalanceState extends State<_AnimatedBalance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedBalance old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount) {
      _from = _from + _anim.value * (old.amount - _from);
      _ctrl..reset()..forward();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isNeg = widget.amount < 0;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final v = _from + _anim.value * (widget.amount - _from);
        return Text(
          '${v < 0 ? '−' : ''}${CurrencyFormatter.format(v.abs(), widget.currencySymbol)}',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: isNeg
                ? const Color(0xFFFF8080)
                : Colors.white,
          ),
        );
      },
    );
  }
}

// ── Stat pill (income / expense) ─────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label, currencySymbol;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isActive;
  final VoidCallback? onTap;
  const _StatPill({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.currencySymbol,
    required this.isDark,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.12)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.6)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12, offset: const Offset(0, 3))]
              : isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.subTextDark
                            : AppColors.subTextLight,
                        letterSpacing: 0.3,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatCompact(
                        amount, currencySymbol),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),  // AnimatedContainer
    );  // GestureDetector
  }
}

// ── Budget banner ─────────────────────────────────────────────────────────────
class _BudgetBanner extends StatelessWidget {
  final int month, year;
  final dynamic t;
  final bool isDark;
  const _BudgetBanner(
      {required this.month,
        required this.year,
        required this.t,
        required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
        ),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.wallet_add_1,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.noBudgetTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textDark
                          : AppColors.textLight,
                    )),
                Text(t.noBudgetBody,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.subTextDark
                          : AppColors.subTextLight,
                    )),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showBudgetDialog(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(t.setBudget,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                )),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.monthlyBudget),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Summa'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel)),
          TextButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null) {
                context.read<BudgetBloc>().add(SetBudgetEvent(
                    limit: val, month: month, year: year));
                Navigator.pop(context);
              }
            },
            child: Text(t.save,
                style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyTxState extends StatelessWidget {
  final bool isDark;
  final dynamic t;
  const _EmptyTxState({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(children: [
          Icon(Iconsax.receipt_item,
              size: 44,
              color: isDark
                  ? AppColors.subTextDark
                  : AppColors.subTextLight),
          const SizedBox(height: 12),
          Text(t.noTransactions,
              style: TextStyle(
                color: isDark
                    ? AppColors.subTextDark
                    : AppColors.subTextLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              )),
        ]),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────
class _AddFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "fab_home",
      onPressed: onPressed,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
      elevation: 6,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}
// ── Filter sheet helpers ──────────────────────────────────────────────────────
class _FilterSection extends StatelessWidget {
  final String text; final bool isDark;
  const _FilterSection(this.text, {required this.isDark});
  @override Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? AppColors.subTextDark : AppColors.subTextLight));
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected;
  final Color color; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
    required this.color, required this.onTap});
  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : isDark ? AppColors.cardDark : AppColors.bgLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color
                  : isDark ? AppColors.borderDark : AppColors.borderLight,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? color
                : isDark ? AppColors.subTextDark : AppColors.subTextLight)),
      ),
    );
  }
}

class _FilterInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint, currency; final bool isDark;
  final ValueChanged<String> onChanged;
  const _FilterInput({required this.ctrl, required this.hint,
    required this.currency, required this.isDark, required this.onChanged});
  @override Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: onChanged,
    style: TextStyle(fontSize: 14,
        color: isDark ? AppColors.textDark : AppColors.textLight),
    decoration: InputDecoration(
      hintText: hint,
      prefixText: '$currency ',
      prefixStyle: TextStyle(fontSize: 12,
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
      filled: true,
      fillColor: isDark ? AppColors.cardDark : AppColors.bgLight,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent)),
    ),
  );
}

class _DatePickerBtn extends StatelessWidget {
  final String label; final bool isDark; final VoidCallback onTap;
  const _DatePickerBtn({required this.label, required this.isDark,
    required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.bgLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13,
                color: isDark ? AppColors.subTextDark : AppColors.subTextLight)),
            Icon(Iconsax.calendar, size: 14,
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
          ]),
    ),
  );
}