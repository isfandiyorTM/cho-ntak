import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/saving_entity.dart';
import '../blocs/saving/saving_bloc.dart';
import '../widgets/error_widgets.dart';

class SavingsPage extends StatefulWidget {
  final String currencySymbol;
  const SavingsPage({super.key, required this.currencySymbol});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SavingBloc>().add(LoadSavings());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.savingsGoals),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<SavingBloc, SavingState>(
        builder: (context, state) {
          if (state is SavingLoading || state is SavingInitial) {
            return const HomeLoadingSkeleton();
          }
          if (state is SavingError) {
            return ErrorScreen(
              title: 'Maqsadlar yuklanmadi',
              message: state.message,
              onRetry: () => context.read<SavingBloc>().add(LoadSavings()),
            );
          }
          if (state is! SavingLoaded) return const SizedBox.shrink();

          if (state.savings.isEmpty) {
            return EmptyState(
              title: t.noSavings,
              subtitle: t.noSavingsSub,
              icon: Iconsax.coin,
              iconColor: AppColors.gold.withOpacity(0.6),
              action: _AddButton(
                onTap: () => _showAddSheet(context),
                label: t.addGoal,
              ),
            );
          }

          // Summary header
          final totalTarget = state.savings.fold(0.0, (s, g) => s + g.target);
          final totalSaved  = state.savings.fold(0.0, (s, g) => s + g.saved);
          final completed   = state.savings.where((g) => g.isCompleted).length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _SummaryHeader(
                    totalTarget:    totalTarget,
                    totalSaved:     totalSaved,
                    completed:      completed,
                    total:          state.savings.length,
                    currencySymbol: widget.currencySymbol,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _SavingCard(
                      saving:         state.savings[i],
                      currencySymbol: widget.currencySymbol,
                      index:          i,
                      onAddMoney: () => _showAddMoneySheet(context, state.savings[i]),
                      onEdit:     () => _showAddSheet(context, existing: state.savings[i]),
                      onDelete:   () => _confirmDelete(context, state.savings[i].id),
                    ),
                    childCount: state.savings.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _PulseAddFab(
        onPressed: () => _showAddSheet(context),
      ),
    );
  }

  void _showAddSheet(BuildContext context, {SavingEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SavingBloc>(),
        child: _AddSavingSheet(
          currencySymbol: widget.currencySymbol,
          existing: existing,
        ),
      ),
    );
  }

  void _showAddMoneySheet(BuildContext context, SavingEntity saving) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SavingBloc>(),
        child: _AddMoneySheet(
          saving: saving,
          currencySymbol: widget.currencySymbol,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Maqsadni o'chirish?",
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text("Bu maqsad va unga saqlangan mablag' o'chiriladi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor')),
          ElevatedButton(
            onPressed: () {
              context.read<SavingBloc>().add(DeleteSavingEvent(id));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white),
            child: const Text("O'chirish",
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Summary header ────────────────────────────────────────────────────────────
class _SummaryHeader extends StatelessWidget {
  final double totalTarget, totalSaved;
  final int completed, total;
  final String currencySymbol;

  const _SummaryHeader({
    required this.totalTarget, required this.totalSaved,
    required this.completed,   required this.total,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withOpacity(0.15),
            AppColors.gold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Jami tejamkor',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatCompact(totalSaved, currencySymbol),
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: AppColors.gold, letterSpacing: -0.5),
                ),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: completed == total && total > 0
                      ? AppColors.income.withOpacity(0.15)
                      : AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: completed == total && total > 0
                        ? AppColors.income.withOpacity(0.3)
                        : AppColors.gold.withOpacity(0.2),
                  ),
                ),
                child: Column(children: [
                  Text('$completed/$total',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: completed == total && total > 0
                              ? AppColors.income : AppColors.gold)),
                  Text('bajarildi', style: TextStyle(
                      fontSize: 11, color: Colors.grey[500])),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Overall progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.goldLight, AppColors.gold]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(pct * 100).toStringAsFixed(0)}% bajarildi',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.gold,
                      fontWeight: FontWeight.w600)),
              Text(
                'Maqsad: ${CurrencyFormatter.formatCompact(totalTarget, currencySymbol)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Saving card ───────────────────────────────────────────────────────────────
class _SavingCard extends StatefulWidget {
  final SavingEntity saving;
  final String currencySymbol;
  final int index;
  final VoidCallback onAddMoney, onEdit, onDelete;

  const _SavingCard({
    required this.saving, required this.currencySymbol,
    required this.index,  required this.onAddMoney,
    required this.onEdit, required this.onDelete,
  });

  @override
  State<_SavingCard> createState() => _SavingCardState();
}

class _SavingCardState extends State<_SavingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _barAnim   = Tween<double>(begin: 0, end: widget.saving.percentage)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(_SavingCard old) {
    super.didUpdateWidget(old);
    if (old.saving.saved != widget.saving.saved) {
      _barAnim = Tween<double>(
          begin: old.saving.percentage, end: widget.saving.percentage)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl..reset()..forward();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s     = widget.saving;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = s.isCompleted ? AppColors.income : s.color;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: s.isCompleted
                  ? AppColors.income.withOpacity(0.4)
                  : color.withOpacity(0.2),
              width: s.isCompleted ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
                Row(
                  children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(s.title,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (s.isCompleted)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.income.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('✓ Bajarildi',
                                    style: TextStyle(
                                        fontSize: 11, color: AppColors.income,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ]),
                          const SizedBox(height: 2),
                          if (s.daysLeft != null)
                            Text(
                              s.daysLeft! < 0
                                  ? 'Muddat o\'tgan!'
                                  : s.daysLeft! == 0
                                  ? 'Bugun muddati!'
                                  : '${s.daysLeft} kun qoldi',
                              style: TextStyle(
                                fontSize: 12,
                                color: s.daysLeft! <= 7
                                    ? AppColors.expense
                                    : Colors.grey[500],
                                fontWeight: s.daysLeft! <= 7
                                    ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Iconsax.more, size: 18,
                          color: isDark ? Colors.grey[600] : Colors.grey[400]),
                      onSelected: (v) {
                        if (v == 'edit')   widget.onEdit();
                        if (v == 'delete') widget.onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit',
                            child: Row(children: [
                              Icon(Iconsax.edit, size: 16),
                              SizedBox(width: 8), Text('Tahrirlash')])),
                        const PopupMenuItem(value: 'delete',
                            child: Row(children: [
                              Icon(Iconsax.trash, size: 16, color: AppColors.expense),
                              SizedBox(width: 8),
                              Text("O'chirish",
                                  style: TextStyle(color: AppColors.expense))])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Progress bar ─────────────────────────────
                AnimatedBuilder(
                  animation: _barAnim,
                  builder: (_, __) => Stack(children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _barAnim.value,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            color.withOpacity(0.7), color,
                          ]),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 4, offset: const Offset(0, 2),
                          )],
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Amounts + button ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        CurrencyFormatter.format(s.saved, widget.currencySymbol),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: color),
                      ),
                      Text(
                        '/ ${CurrencyFormatter.formatCompact(s.target, widget.currencySymbol)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ]),
                    Row(children: [
                      Text(
                        '${(s.percentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: color),
                      ),
                      const SizedBox(width: 12),
                      if (!s.isCompleted)
                        GestureDetector(
                          onTap: widget.onAddMoney,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(
                                color: color.withOpacity(0.35),
                                blurRadius: 8, offset: const Offset(0, 3),
                              )],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.add, color: Colors.black, size: 16),
                                SizedBox(width: 4),
                                Text('Qo\'shish',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Add/Edit saving bottom sheet ──────────────────────────────────────────────
class _AddSavingSheet extends StatefulWidget {
  final String currencySymbol;
  final SavingEntity? existing;
  const _AddSavingSheet({required this.currencySymbol, this.existing});

  @override
  State<_AddSavingSheet> createState() => _AddSavingSheetState();
}

class _AddSavingSheetState extends State<_AddSavingSheet> {
  final _titleCtrl  = TextEditingController();
  final _targetCtrl = TextEditingController();
  String    _emoji    = '🎯';
  Color     _color    = AppColors.gold;
  DateTime? _deadline;

  static const _emojis = ['🎯','📱','🚗','🏠','✈️','💻','👟','🎮',
    '📚','💍','🏋️','🌴','🎓','💰','🎁','🐶'];
  static const _colors = [
    AppColors.gold, AppColors.income, AppColors.expense,
    Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFFDB2777),
    Color(0xFF0891B2), Color(0xFFD97706),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text  = widget.existing!.title;
      _targetCtrl.text = widget.existing!.target.toStringAsFixed(0);
      _emoji    = widget.existing!.emoji;
      _color    = widget.existing!.color;
      _deadline = widget.existing!.deadline;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title  = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text);
    if (title.isEmpty || target == null || target <= 0) return;

    if (widget.existing != null) {
      final updated = SavingEntity(
        id:        widget.existing!.id,
        title:     title,
        target:    target,
        saved:     widget.existing!.saved,
        emoji:     _emoji,
        color:     _color,
        createdAt: widget.existing!.createdAt,
        deadline:  _deadline,
      );
      context.read<SavingBloc>().add(UpdateSavingEvent(updated));
    } else {
      context.read<SavingBloc>().add(AddSavingEvent(
        title: title, target: target,
        emoji: _emoji, color: _color, deadline: _deadline,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 20),

              Text(isEdit ? 'Maqsadni tahrirlash' : 'Yangi maqsad',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),

              // Emoji picker
              Text('Emoji tanlang',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500],
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _emojis.map((e) => GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: _emoji == e
                          ? _color.withOpacity(0.2)
                          : (isDark ? AppColors.cardDark : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _emoji == e ? _color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 22))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Color picker
              Text('Rang tanlang',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500],
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: _colors.map((c) => GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == c ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: _color == c ? [BoxShadow(
                        color: c.withOpacity(0.5),
                        blurRadius: 8,
                      )] : [],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Title field
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Maqsad nomi',
                  hintText: 'masalan: iPhone uchun',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _color, width: 1.5),
                  ),
                  prefixText: '$_emoji  ',
                ),
              ),
              const SizedBox(height: 14),

              // Target amount field
              TextField(
                controller: _targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Maqsad summasi',
                  prefixText: '${widget.currencySymbol} ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _color, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Deadline picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now().add(
                        const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: ColorScheme.dark(primary: _color),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(children: [
                    Icon(Iconsax.calendar, color: _color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _deadline == null
                            ? 'Muddat (ixtiyoriy)'
                            : '${_deadline!.day}.${_deadline!.month}.${_deadline!.year}',
                        style: TextStyle(
                          color: _deadline == null ? Colors.grey[500] : null,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (_deadline != null)
                      GestureDetector(
                        onTap: () => setState(() => _deadline = null),
                        child: Icon(Icons.close,
                            size: 18, color: Colors.grey[500]),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: _color.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 4),
                      )],
                    ),
                    child: Center(
                      child: Text(
                        isEdit ? 'Saqlash' : 'Maqsad qo\'shish',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add money sheet ───────────────────────────────────────────────────────────
class _AddMoneySheet extends StatefulWidget {
  final SavingEntity saving;
  final String currencySymbol;
  const _AddMoneySheet({required this.saving, required this.currencySymbol});

  @override
  State<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<_AddMoneySheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final s       = widget.saving;
    final color   = s.color;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(s.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${CurrencyFormatter.format(s.saved, widget.currencySymbol)} / '
                  '${CurrencyFormatter.format(s.target, widget.currencySymbol)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            // Quick amounts
            Row(
              children: [100000, 250000, 500000].map((amt) =>
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _ctrl.text = amt.toString(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Text(
                            CurrencyFormatter.formatCompact(
                                amt.toDouble(), widget.currencySymbol),
                            style: TextStyle(
                                fontSize: 12, color: color,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
              ).toList(),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Miqdor kiriting',
                prefixText: '${widget.currencySymbol} ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  final amt = double.tryParse(_ctrl.text);
                  if (amt != null && amt > 0) {
                    context.read<SavingBloc>().add(
                        AddToSavedEvent(id: s.id, amount: amt));
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )],
                  ),
                  child: const Center(
                    child: Text("Qo'shish",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add button widget ─────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _AddButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 10, offset: const Offset(0, 3),
          )],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Iconsax.add, color: Colors.black, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }
}

// ── Pulse FAB ─────────────────────────────────────────────────────────────────
class _PulseAddFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _PulseAddFab({required this.onPressed});
  @override State<_PulseAddFab> createState() => _PulseAddFabState();
}

class _PulseAddFabState extends State<_PulseAddFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: AppColors.gold.withOpacity(0.4),
            blurRadius: 16, spreadRadius: 2,
          )],
        ),
        child: FloatingActionButton.extended(
          onPressed: widget.onPressed,
          icon: const Icon(Iconsax.add),
          label: const Text('Maqsad', style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}