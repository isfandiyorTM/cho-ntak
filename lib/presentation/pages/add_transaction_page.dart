import 'package:flutter/material.dart';
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

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.existing != null;

  // Hold translations so we can use in validators without context
  late Translations _t;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(LoadCategories());
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
    // Cache translations — safe to call here
    _t = context.read<LanguageProvider>().t;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.selectCategory)),
      );
      return;
    }

    final transaction = TransactionEntity(
      id:         _isEditing ? widget.existing!.id : const Uuid().v4(),
      title:      _titleCtrl.text.trim(),
      amount:     double.parse(_amountCtrl.text),
      type:       _type,
      categoryId: _selectedCategoryId!,
      date:       _selectedDate,
      note:       _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
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
    // Always get latest translations in build
    final t      = context.watch<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? t.editTransaction : t.addTransaction),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Type toggle ──────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: TransactionType.values.map((type) {
                    final selected = _type == type;
                    final color    = type == TransactionType.income
                        ? AppColors.income : AppColors.expense;
                    final label    = type == TransactionType.income
                        ? t.income : t.expense;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(color: color, width: 1.5)
                                : null,
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? color : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ────────────────────────────────────
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: t.title,
                  prefixIcon: const Icon(Iconsax.edit_2),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? t.enterTitle : null,
              ),
              const SizedBox(height: 16),

              // ── Amount ───────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: t.amount,
                  prefixIcon: const Icon(Iconsax.money),
                  prefixText: '${widget.currencySymbol} ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return t.enterAmount;
                  if (double.tryParse(v) == null) return t.invalidNumber;
                  if (double.parse(v) <= 0) return t.greaterThanZero;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Category ─────────────────────────────────
              BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryError) {
                    return ErrorBanner(
                      message: 'Kategoriyalar yuklanmadi',
                      onRetry: () => context.read<CategoryBloc>().add(LoadCategories()),
                    );
                  }
                  if (state is! CategoryLoaded) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.category,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.goldDim,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.categories.map((cat) {
                          final selected = _selectedCategoryId == cat.id;
                          return GestureDetector(
                            onTap: () => setState(
                                    () => _selectedCategoryId = cat.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? cat.color.withOpacity(0.2)
                                    : (isDark
                                    ? AppColors.cardDark
                                    : AppColors.cardLight),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? cat.color
                                      : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat.icon,
                                      size: 14,
                                      color: selected
                                          ? cat.color
                                          : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected
                                          ? cat.color
                                          : Colors.grey,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
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
                },
              ),
              const SizedBox(height: 16),

              // ── Date picker ──────────────────────────────
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.calendar,
                      color: AppColors.gold, size: 20),
                ),
                title: Text(t.date),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Iconsax.arrow_right_3, size: 16),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: AppColors.gold),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Note ─────────────────────────────────────
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t.note,
                  prefixIcon: const Icon(Iconsax.note),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ───────────────────────────────────
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isEditing ? t.editTransaction : t.addTransaction,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}