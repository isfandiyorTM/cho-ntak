import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionDetailPage extends StatefulWidget {
  final TransactionEntity transaction;
  final CategoryEntity?   category;
  final String            currencySymbol;
  final VoidCallback?     onEdit;
  final VoidCallback?     onDelete;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    this.category,
    this.onEdit,
    this.onDelete,
  });

  // ── Open as bottom sheet ─────────────────────────────────────────────────
  static Future<void> show(
      BuildContext context, {
        required TransactionEntity transaction,
        required String currencySymbol,
        CategoryEntity? category,
        VoidCallback?   onEdit,
        VoidCallback?   onDelete,
      }) {
    return showModalBottomSheet(
      context:           context,
      isScrollControlled: true,
      backgroundColor:   Colors.transparent,
      barrierColor:      Colors.black.withValues(alpha: 0.55),
      builder: (_) => TransactionDetailPage(
        transaction:    transaction,
        currencySymbol: currencySymbol,
        category:       category,
        onEdit:         onEdit,
        onDelete:       onDelete,
      ),
    );
  }

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final tx       = widget.transaction;
    final cat      = widget.category;
    final isIncome = tx.type == TransactionType.income;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final color    = cat?.color ?? AppColors.gold;
    final amtColor = isIncome ? AppColors.income : AppColors.expense;
    final bg       = isDark ? AppColors.surfaceDark : Colors.white;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        // ── DraggableScrollableSheet — full content always visible ──────
        child: DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize:     0.5,
          maxChildSize:     0.95,
          expand:           false,
          builder: (context, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: CustomScrollView(
              controller: scrollCtrl,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      // ── Drag handle ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 4),
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // ── Hero section ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                        child: Column(
                          children: [
                            // Category icon / emoji circle
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:  color.withValues(alpha: 0.15),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.4), width: 2),
                              ),
                              child: Center(
                                child: cat?.emoji != null
                                    ? Text(cat!.emoji!,
                                    style: const TextStyle(fontSize: 32))
                                    : Icon(cat?.icon ?? Iconsax.wallet,
                                    color: color, size: 32),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              tx.title,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),

                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cat?.name ?? 'Unknown',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: color,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Big amount
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      isIncome ? '+' : '−',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: amtColor),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    CurrencyFormatter.format(
                                        tx.amount, widget.currencySymbol),
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      color: amtColor,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Type chip
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: amtColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: amtColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                isIncome ? '↑  Daromad' : '↓  Xarajat',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: amtColor,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),

                      // ── Divider ──────────────────────────────────────
                      Divider(
                        height: 1,
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        indent: 24, endIndent: 24,
                      ),

                      // ── Detail rows ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon:      Iconsax.calendar,
                              label:     'Sana',
                              value:     DateFormatter.formatFull(tx.date),
                              iconColor: AppColors.gold,
                              isDark:    isDark,
                            ),
                            if (tx.note != null && tx.note!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _DetailRow(
                                icon:      Iconsax.note,
                                label:     'Izoh',
                                value:     tx.note!,
                                iconColor: AppColors.gold,
                                isDark:    isDark,
                                maxLines:  5,
                              ),
                            ],
                            const SizedBox(height: 4),
                            _DetailRow(
                              icon:      Iconsax.tag,
                              label:     'ID',
                              value:     tx.id.substring(0, 8).toUpperCase(),
                              iconColor: AppColors.mutedDark,
                              isDark:    isDark,
                              valueStyle: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight),
                            ),
                          ],
                        ),
                      ),

                      // ── Action buttons ───────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon:  Iconsax.trash,
                                label: "O'chirish",
                                color: AppColors.expense,
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onDelete?.call();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _ActionButton(
                                icon:   Iconsax.edit,
                                label:  'Tahrirlash',
                                color:  AppColors.gold,
                                filled: true,
                                onTap:  () {
                                  Navigator.pop(context);
                                  widget.onEdit?.call();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ── Detail row ────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData    icon;
  final String      label, value;
  final Color       iconColor;
  final bool        isDark;
  final TextStyle?  valueStyle;
  final int         maxLines;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isDark,
    this.valueStyle,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.mutedDark : AppColors.mutedLight)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines:  maxLines,
                  overflow:  TextOverflow.ellipsis,
                  style: valueStyle ??
                      TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.navyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final Color      color;
  final bool       filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: filled
              ? color
              : (isDark ? AppColors.cardDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: filled ? Colors.transparent : color.withValues(alpha: 0.4)),
          boxShadow: filled
              ? [BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: filled ? Colors.black : color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.black : color,
                    fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}