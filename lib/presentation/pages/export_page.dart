import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/language_provider.dart';
import '../../core/services/export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class ExportPage extends StatefulWidget {
  final List<TransactionEntity> transactions;
  final List<CategoryEntity>    categories;
  final String                  currencySymbol;

  const ExportPage({
    super.key,
    required this.transactions,
    required this.categories,
    required this.currencySymbol,
  });

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {

  ExportOptions _options = const ExportOptions();
  late var _t; // cached translations, set in build()
  bool _loading  = false;
  String? _lastFilePath;
  String? _error;

  // ── Period display map ────────────────────────────────────────────────────
  Map<ExportPeriod, String> _periodLabels(t) => {
    ExportPeriod.thisMonth:   t.periodThisMonth,
    ExportPeriod.lastMonth:   t.periodLastMonth,
    ExportPeriod.last3Months: t.period3Months,
    ExportPeriod.last6Months: t.period6Months,
    ExportPeriod.thisYear:    t.periodThisYear,
    ExportPeriod.allTime:     t.periodAllTime,
  };

  // ── Preview stats ─────────────────────────────────────────────────────────
  late List<TransactionEntity> _preview;

  @override
  void initState() {
    super.initState();
    _updatePreview();
  }

  void _updatePreview() {
    final filtered = ExportService.filterByPeriod(
        widget.transactions, _options.period);
    setState(() {
      _preview = filtered.where((t) =>
      (_options.includeIncome  && t.type == TransactionType.income) ||
          (_options.includeExpense && t.type == TransactionType.expense)
      ).toList();
    });
  }

  // ── Export action ─────────────────────────────────────────────────────────
  Future<void> _export() async {
    setState(() { _loading = true; _error = null; _lastFilePath = null; });

    final result = _options.type == ExportType.pdf
        ? await ExportService.exportPDF(
      transactions:   widget.transactions,
      categories:     widget.categories,
      currencySymbol: widget.currencySymbol,
      options:        _options,
    )
        : await ExportService.exportExcel(
      transactions:   widget.transactions,
      categories:     widget.categories,
      currencySymbol: widget.currencySymbol,
      options:        _options,
    );

    setState(() {
      _loading      = false;
      _lastFilePath = result.filePath;
      _error        = result.error;
    });

    if (result.success && result.filePath != null) {
      _showSuccessSheet(result.filePath!);
    } else if (result.error != null) {
      _showError(result.error!);
    }
  }

  void _showSuccessSheet(String path) {
    final t = _t;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Success icon
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(Iconsax.tick_circle,
                color: AppColors.income, size: 32),
          ),
          const SizedBox(height: 16),
          Text(t.exportSuccess,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(_options.type == ExportType.pdf
              ? t.exportPdfReady
              : t.exportXlsReady,
              style: TextStyle(fontSize: 14,
                  color: AppColors.subTextDark)),
          const SizedBox(height: 24),
          // Action buttons
          Row(children: [
            Expanded(child: _ActionBtn(
              icon:  Iconsax.share,
              label: t.exportShare,
              color: AppColors.accent,
              onTap: () {
                Navigator.pop(context);
                ExportService.shareFile(path);
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: _ActionBtn(
              icon:  Iconsax.document_download,
              label: t.exportOpen,
              color: AppColors.gold,
              filled: true,
              onTap: () {
                Navigator.pop(context);
                ExportService.openFile(path);
              },
            )),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showError(String error) {
    final t = _t;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('\${t.exportReport} failed: \$error'),
      backgroundColor: AppColors.expense,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    _t = t; // cache for use in callbacks
    final income  = _preview
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (s, tx) => s + tx.amount);
    final expense = _preview
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (s, tx) => s + tx.amount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left,
              color: isDark ? AppColors.textDark : AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t.exportReport,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDark : AppColors.textLight)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Format selector ──────────────────────────────────────────
          _SectionTitle(t.exportFormat),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _FormatCard(
              icon:     Iconsax.document_text,
              label:    t.exportPdfLabel,
              sublabel: t.exportPdfSub,
              color:    AppColors.expense,
              selected: _options.type == ExportType.pdf,
              onTap: () => setState(() {
                _options = _options.copyWith(type: ExportType.pdf);
              }),
            )),
            const SizedBox(width: 12),
            Expanded(child: _FormatCard(
              icon:     Iconsax.document_text1,
              label:    t.exportExcelLabel,
              sublabel: t.exportExcelSub,
              color:    const Color(0xFF1D6F42),
              selected: _options.type == ExportType.excel,
              onTap: () => setState(() {
                _options = _options.copyWith(type: ExportType.excel);
              }),
            )),
          ]),
          const SizedBox(height: 24),

          // ── Period selector ──────────────────────────────────────────
          _SectionTitle(t.exportTimePeriod),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8,
            children: ExportPeriod.values.map((p) => _PeriodChip(
              label:    _periodLabels(t)[p]!,
              selected: _options.period == p,
              onTap: () {
                setState(() => _options = _options.copyWith(period: p));
                _updatePreview();
              },
            )).toList(),
          ),
          const SizedBox(height: 24),

          // ── Include filter ───────────────────────────────────────────
          _SectionTitle(t.exportInclude),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            child: Column(children: [
              _ToggleRow(
                icon:     Iconsax.arrow_up_3,
                iconColor: AppColors.income,
                label:    t.exportIncIncome,
                value:    _options.includeIncome,
                onChanged: (v) {
                  setState(() => _options = _options.copyWith(
                      includeIncome: v));
                  _updatePreview();
                },
                isDark: isDark,
              ),
              Divider(height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
              _ToggleRow(
                icon:     Iconsax.arrow_down,
                iconColor: AppColors.expense,
                label:    t.exportIncExpense,
                value:    _options.includeExpense,
                onChanged: (v) {
                  setState(() => _options = _options.copyWith(
                      includeExpense: v));
                  _updatePreview();
                },
                isDark: isDark,
              ),
              if (_options.type == ExportType.pdf) ...[
                Divider(height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight),
                _ToggleRow(
                  icon:     Iconsax.chart_2,
                  iconColor: AppColors.accent,
                  label:    t.exportIncCharts,
                  value:    _options.includeCharts,
                  onChanged: (v) => setState(() =>
                  _options = _options.copyWith(includeCharts: v)),
                  isDark: isDark,
                ),
              ],
            ]),
          ),
          const SizedBox(height: 24),

          // ── Preview stats ────────────────────────────────────────────
          _SectionTitle(t.exportPreview),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            child: Column(children: [
              _PreviewRow(
                label: t.exportPeriodLabel,
                value: _periodLabels(t)[_options.period]!,
                icon:  Iconsax.calendar,
                isDark: isDark,
              ),
              _PreviewRow(
                label: t.transactions,
                value: '${_preview.length}',
                icon:  Iconsax.receipt_item,
                isDark: isDark,
              ),
              _PreviewRow(
                label: t.income,
                value: '${widget.currencySymbol} '
                    '${income.toStringAsFixed(0)}',
                icon:  Iconsax.arrow_up_3,
                valueColor: AppColors.income,
                isDark: isDark,
              ),
              _PreviewRow(
                label: t.expense,
                value: '${widget.currencySymbol} '
                    '${expense.toStringAsFixed(0)}',
                icon:  Iconsax.arrow_down,
                valueColor: AppColors.expense,
                isDark: isDark,
                isLast: true,
              ),
            ]),
          ),
          const SizedBox(height: 32),

          // ── Export button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading || _preview.isEmpty ? null : _export,
              style: ElevatedButton.styleFrom(
                backgroundColor: _options.type == ExportType.pdf
                    ? AppColors.expense
                    : const Color(0xFF1D6F42),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                isDark ? AppColors.borderDark : Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_options.type == ExportType.pdf
                        ? Iconsax.document_download
                        : Iconsax.document_text1,
                        size: 20),
                    const SizedBox(width: 10),
                    Text(
                        _preview.isEmpty
                            ? t.exportNoData
                            : (_options.type == ExportType.pdf ? t.exportPDF : t.exportExcel),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── What's included description ───────────────────────────────
          if (_options.type == ExportType.pdf)
            _InfoBox(
              color: AppColors.expense,
              icon:  Iconsax.document_text,
              title: t.exportPdfLabel + ':',
              points: [
                t.exportPdfInfo1,
                t.exportPdfInfo2,
                t.exportPdfInfo3,
                t.exportPdfInfo4,
                t.exportPdfInfo5,
              ],
              isDark: isDark,
            )
          else
            _InfoBox(
              color: const Color(0xFF1D6F42),
              icon:  Iconsax.document_text1,
              title: t.exportExcelLabel + ':',
              points: [
                t.exportXlsInfo1,
                t.exportXlsInfo2,
                t.exportXlsInfo3,
                t.exportXlsInfo4,
                t.exportXlsInfo5,
              ],
              isDark: isDark,
            ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.8,
        color: isDark ? AppColors.subTextDark : AppColors.subTextLight));
  }
}

class _FormatCard extends StatelessWidget {
  final IconData icon;
  final String   label, sublabel;
  final Color    color;
  final bool     selected;
  final VoidCallback onTap;
  const _FormatCard({required this.icon, required this.label,
    required this.sublabel, required this.color, required this.selected,
    required this.onTap});

  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color
                : isDark ? AppColors.borderDark : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: selected ? color : AppColors.mutedDark, size: 22),
            const Spacer(),
            if (selected)
              Icon(Iconsax.tick_circle, color: color, size: 18),
          ]),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: selected ? color
                  : isDark ? AppColors.textDark : AppColors.textLight)),
          const SizedBox(height: 4),
          Text(sublabel, style: TextStyle(
              fontSize: 10, color: AppColors.mutedDark)),
        ]),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final VoidCallback onTap;
  const _PeriodChip({required this.label, required this.selected,
    required this.onTap});
  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent
                : isDark ? AppColors.borderDark : AppColors.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? AppColors.accent
                : isDark ? AppColors.subTextDark : AppColors.subTextLight)),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final bool     value, isDark;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.icon, required this.iconColor,
    required this.label, required this.value, required this.onChanged,
    required this.isDark});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      Icon(icon, color: iconColor, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textDark : AppColors.textLight))),
      Switch(
        value: value, onChanged: onChanged,
        activeColor: AppColors.accent,
        inactiveThumbColor: AppColors.mutedDark,
      ),
    ]),
  );
}

class _PreviewRow extends StatelessWidget {
  final String  label, value;
  final IconData icon;
  final Color?  valueColor;
  final bool    isDark, isLast;
  const _PreviewRow({required this.label, required this.value,
    required this.icon, required this.isDark,
    this.valueColor, this.isLast = false});
  @override Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(children: [
        Icon(icon, size: 16,
            color: isDark ? AppColors.subTextDark : AppColors.subTextLight),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13,
            color: isDark ? AppColors.subTextDark : AppColors.subTextLight)),
        const Spacer(),
        Text(value, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: valueColor ??
                (isDark ? AppColors.textDark : AppColors.textLight))),
      ]),
    ),
    if (!isLast) Divider(height: 1,
        color: isDark ? AppColors.borderDark : AppColors.borderLight),
  ]);
}

class _InfoBox extends StatelessWidget {
  final Color  color;
  final IconData icon;
  final String title;
  final List<String> points;
  final bool isDark;
  const _InfoBox({required this.color, required this.icon,
    required this.title, required this.points, required this.isDark});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 10),
      ...points.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 5, height: 5, margin: const EdgeInsets.fromLTRB(4, 5, 8, 0),
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          Expanded(child: Text(p, style: TextStyle(fontSize: 12,
              color: isDark ? AppColors.subTextDark : AppColors.subTextLight))),
        ]),
      )),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     filled;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label,
    required this.color, required this.onTap, this.filled = false});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: filled ? Colors.white : color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: filled ? Colors.white : color)),
      ]),
    ),
  );
}