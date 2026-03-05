import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionTile extends StatefulWidget {
  final TransactionEntity transaction;
  final CategoryEntity? category;
  final String currencySymbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int index; // for staggered delay

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    this.category,
    this.onEdit,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Staggered delay based on index
    Future.delayed(
        Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.type == TransactionType.income;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final color    = widget.category?.color ?? AppColors.gold;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.category?.icon ?? Iconsax.wallet,
                  color: color, size: 20),
            ),
            title: Text(
              widget.transaction.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              '${widget.category?.name ?? 'Unknown'} · ${DateFormatter.formatShort(widget.transaction.date)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(widget.transaction.amount, widget.currencySymbol)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isIncome ? AppColors.income : AppColors.expense,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Iconsax.more,
                      size: 18,
                      color: isDark
                          ? Colors.grey[600]
                          : Colors.grey[400]),
                  onSelected: (v) {
                    if (v == 'edit') widget.onEdit?.call();
                    if (v == 'delete') widget.onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Iconsax.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit')
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Iconsax.trash,
                              size: 16, color: AppColors.expense),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(
                                  color: AppColors.expense))
                        ])),
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