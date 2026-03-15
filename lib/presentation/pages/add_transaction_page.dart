import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/error_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/i18n/translations.dart';
import '../../domain/entities/transaction_entity.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/category/category_bloc.dart';

class AddTransactionPage extends StatefulWidget {
  final String currencySymbol;
  final TransactionEntity? existing;

  const AddTransactionPage({
    super.key,
    required this.currencySymbol,
    this.existing,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();

  TransactionType _type               = TransactionType.expense;
  String?         _selectedCategoryId;
  DateTime        _selectedDate       = DateTime.now();

  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;
  late Translations        _t;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<CategoryBloc>().add(LoadCategories()));
    if (_isEditing) {
      final e = widget.existing!;
      _titleCtrl.text     = e.title;
      _amountCtrl.text    = e.amount.toString();
      _noteCtrl.text      = e.note ?? '';
      _type               = e.type;
      _selectedCategoryId = e.categoryId;
      _selectedDate       = e.date;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _t = context.read<LanguageProvider>().t;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t.selectCategory),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.expense,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final transaction = TransactionEntity(
      id:         _isEditing ? widget.existing!.id : const Uuid().v4(),
      title:      _titleCtrl.text.trim(),
      amount:     double.parse(_amountCtrl.text),
      type:       _type,
      categoryId: _selectedCategoryId!,
      date:       _selectedDate,
      note:       _noteCtrl.text.trim().isEmpty
          ? null
          : _noteCtrl.text.trim(),
    );

    if (_isEditing) {
      context.read<TransactionBloc>().add(UpdateTransactionEvent(transaction));
    } else {
      context.read<TransactionBloc>().add(AddTransactionEvent(transaction));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t      = context.watch<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = _type == TransactionType.income;
    final accentColor = isIncome ? AppColors.income : AppColors.expense;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? t.editTransaction : t.addTransaction,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Type toggle ────────────────────────
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: TransactionType.values.map((type) {
                      final sel   = _type == type;
                      final color = type == TransactionType.income
                          ? AppColors.income
                          : AppColors.expense;
                      final label = type == TransactionType.income
                          ? t.income
                          : t.expense;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _type = type);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: sel ? color : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? Colors.white
                                      : (isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[500]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Amount (prominent) ─────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.amount,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.currencySymbol,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                                letterSpacing: -0.5,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                hintText: '0',
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (v == null || v.isEmpty) return t.enterAmount;
                                if (double.tryParse(v) == null) return t.invalidNumber;
                                if (double.parse(v) <= 0) return t.greaterThanZero;
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Title ──────────────────────────────
                _InputField(
                  controller: _titleCtrl,
                  label: t.title,
                  icon: Iconsax.edit_2,
                  isDark: isDark,
                  validator: (v) =>
                  v == null || v.isEmpty ? t.enterTitle : null,
                ),
                const SizedBox(height: 12),

                // ── Category ───────────────────────────
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryError) {
                      return ErrorBanner(
                        message: 'Kategoriyalar yuklanmadi',
                        onRetry: () => context
                            .read<CategoryBloc>()
                            .add(LoadCategories()),
                      );
                    }
                    if (state is! CategoryLoaded) {
                      return const SizedBox.shrink();
                    }
                    return _CategoryPicker(
                      categories: state.categories,
                      selectedId: _selectedCategoryId,
                      isDark: isDark,
                      label: t.category,
                      onSelect: (id) =>
                          setState(() => _selectedCategoryId = id),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // ── Date ───────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(
                              primary: AppColors.accent),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Iconsax.calendar,
                              color: AppColors.accent, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t.date,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.navyText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 18,
                            color: isDark
                                ? Colors.grey[600]
                                : Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Note ───────────────────────────────
                _InputField(
                  controller: _noteCtrl,
                  label: t.note,
                  icon: Iconsax.note,
                  isDark: isDark,
                  maxLines: 3,
                ),
                const SizedBox(height: 28),

                // ── Submit ─────────────────────────────
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _isEditing ? t.editTransaction : t.addTransaction,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable input field ──────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.navyText,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}

// ── Category picker ───────────────────────────────────────────────────────────
class _CategoryPicker extends StatelessWidget {
  final List<dynamic> categories;
  final String? selectedId;
  final bool isDark;
  final String label;
  final ValueChanged<String> onSelect;

  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.isDark,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final selected = selectedId == cat.id;
            final color    = cat.color;
            final hasEmoji = cat.emoji != null;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(cat.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.15)
                      : (isDark
                      ? AppColors.cardDark
                      : AppColors.cardLight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? color
                        : (isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasEmoji)
                      Text(cat.emoji,
                          style: const TextStyle(fontSize: 13))
                    else
                      Icon(cat.icon,
                          size: 13,
                          color: selected ? color : Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? color
                            : (isDark
                            ? Colors.grey[400]
                            : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}