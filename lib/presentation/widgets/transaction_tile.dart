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
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 35 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.type == TransactionType.income;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final color    = widget.category?.color ?? AppColors.accent;
    final hasEmoji = widget.category?.emoji != null;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Icon / emoji
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: hasEmoji
                            ? Text(widget.category!.emoji!,
                            style:
                            const TextStyle(fontSize: 20))
                            : Icon(
                            widget.category?.icon
                                ?? Iconsax.wallet,
                            color: color,
                            size: 19),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.transaction.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.category?.name ?? ''}  ·  '
                                '${DateFormatter.formatShort(widget.transaction.date)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.subTextDark
                                  : AppColors.subTextLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Amount + menu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? '+' : '−'}'
                              '${CurrencyFormatter.format(widget.transaction.amount, widget.currencySymbol)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: -0.3,
                            color: isIncome
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 24, height: 20,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.subTextDark
                                  : AppColors.subTextLight,
                            ),
                            onSelected: (v) {
                              if (v == 'edit')
                                widget.onEdit?.call();
                              if (v == 'delete')
                                widget.onDelete?.call();
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Iconsax.edit,
                                      size: 15,
                                      color: isDark
                                          ? AppColors.textDark
                                          : AppColors.textLight),
                                  const SizedBox(width: 8),
                                  const Text('Tahrirlash'),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 15,
                                      color: AppColors.expense),
                                  const SizedBox(width: 8),
                                  const Text("O'chirish",
                                      style: TextStyle(
                                          color: AppColors.expense)),
                                ]),
                              ),
                            ],
                          ),
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