import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionTile extends StatefulWidget {
  final TransactionEntity  transaction;
  final CategoryEntity?    category;
  final String             currencySymbol;
  final VoidCallback?      onEdit;
  final VoidCallback?      onDelete;
  final int                index;

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
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
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
    final hasEmoji = widget.category?.emoji != null;

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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [

                    // ── Category icon / emoji ──────────────
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: hasEmoji
                            ? Text(
                          widget.category!.emoji!,
                          style: const TextStyle(fontSize: 22),
                        )
                            : Icon(
                          widget.category?.icon ?? Iconsax.wallet,
                          color: color,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Title + subtitle ───────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.transaction.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.category?.name ?? ''}'
                                ' · '
                                '${DateFormatter.formatShort(widget.transaction.date)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ── Amount ─────────────────────────────
                    Text(
                      '${isIncome ? '+' : '-'}'
                          '${CurrencyFormatter.format(widget.transaction.amount, widget.currencySymbol)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isIncome
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),

                    // ── Menu ───────────────────────────────
                    PopupMenuButton<String>(
                      icon: Icon(
                        Iconsax.more,
                        size: 18,
                        color: isDark
                            ? Colors.grey[600]
                            : Colors.grey[400],
                      ),
                      onSelected: (v) {
                        if (v == 'edit')   widget.onEdit?.call();
                        if (v == 'delete') widget.onDelete?.call();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Iconsax.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Tahrirlash'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Iconsax.trash,
                                size: 16, color: AppColors.expense),
                            SizedBox(width: 8),
                            Text('O\'chirish',
                                style:
                                TextStyle(color: AppColors.expense)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}