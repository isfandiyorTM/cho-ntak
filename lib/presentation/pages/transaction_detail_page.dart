import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import 'add_transaction_page.dart';

class TransactionDetailPage extends StatefulWidget {
  final TransactionEntity transaction;
  final CategoryEntity? category;
  final String currencySymbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    this.category,
    this.onEdit,
    this.onDelete,
  });

  // ── Open as bottom sheet ──────────────────────────────────
  static Future<void> show(
      BuildContext context, {
        required TransactionEntity transaction,
        required String currencySymbol,
        CategoryEntity? category,
        VoidCallback? onEdit,
        VoidCallback? onDelete,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => TransactionDetailPage(
        transaction: transaction,
        currencySymbol: currencySymbol,
        category: category,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tx      = widget.transaction;
    final cat     = widget.category;
    final isIncome = tx.type == TransactionType.income;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final color    = cat?.color ?? AppColors.gold;
    final amtColor = isIncome ? AppColors.income : AppColors.expense;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Drag handle ────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Hero amount section ────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                  child: Column(
                    children: [
                      // Category icon circle
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(
                              color: color.withOpacity(0.4), width: 2),
                        ),
                        child: Icon(cat?.icon ?? Iconsax.wallet,
                            color: color, size: 32),
                      ),
                      const SizedBox(height: 16),

                      // Transaction title
                      Text(
                        tx.title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // Category label badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
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

                      // Big amount — the hero element
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              isIncome ? '+' : '-',
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

                      // Type chip
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: amtColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: amtColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          isIncome ? '↑ Daromad' : '↓ Xarajat',
                          style: TextStyle(
                              fontSize: 12,
                              color: amtColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Divider ────────────────────────────────
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  indent: 24,
                  endIndent: 24,
                ),

                // ── Details rows ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Iconsax.calendar,
                        label: 'Sana',
                        value: DateFormatter.formatFull(tx.date),
                        iconColor: AppColors.gold,
                      ),
                      if (tx.note != null && tx.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _DetailRow(
                          icon: Iconsax.note,
                          label: 'Izoh',
                          value: tx.note!,
                          iconColor: AppColors.gold,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _DetailRow(
                        icon: Iconsax.tag,
                        label: 'ID',
                        value: tx.id.substring(0, 8).toUpperCase(),
                        iconColor: Colors.grey,
                        valueStyle: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // ── Action buttons ─────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      24,
                      12,
                      24,
                      24 + MediaQuery.of(context).viewInsets.bottom),
                  child: Row(
                    children: [
                      // Delete
                      Expanded(
                        child: _ActionButton(
                          icon: Iconsax.trash,
                          label: "O'chirish",
                          color: AppColors.expense,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onDelete?.call();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Edit
                      Expanded(
                        flex: 2,
                        child: _ActionButton(
                          icon: Iconsax.edit,
                          label: "Tahrirlash",
                          color: AppColors.gold,
                          filled: true,
                          onTap: () {
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
        ),
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color iconColor;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.grey[500]
                          : Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle ??
                      const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
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
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
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
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: filled
              ? color
              : (isDark
              ? AppColors.cardDark
              : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: filled
                  ? Colors.transparent
                  : color.withOpacity(0.4)),
          boxShadow: filled
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: filled ? Colors.black : color, size: 18),
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