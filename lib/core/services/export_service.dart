import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../utils/date_formatter.dart';

// ── Export filter options ─────────────────────────────────────────────────────
enum ExportPeriod { thisMonth, lastMonth, last3Months, last6Months, thisYear, allTime }
enum ExportType   { pdf, excel }

class ExportOptions {
  final ExportPeriod period;
  final ExportType   type;
  final bool         includeIncome;
  final bool         includeExpense;
  final bool         includeCharts;  // PDF only

  const ExportOptions({
    this.period         = ExportPeriod.thisMonth,
    this.type           = ExportType.pdf,
    this.includeIncome  = true,
    this.includeExpense = true,
    this.includeCharts  = true,
  });

  ExportOptions copyWith({
    ExportPeriod? period,
    ExportType?   type,
    bool?         includeIncome,
    bool?         includeExpense,
    bool?         includeCharts,
  }) => ExportOptions(
    period:         period         ?? this.period,
    type:           type           ?? this.type,
    includeIncome:  includeIncome  ?? this.includeIncome,
    includeExpense: includeExpense ?? this.includeExpense,
    includeCharts:  includeCharts  ?? this.includeCharts,
  );
}

// ── Export result ─────────────────────────────────────────────────────────────
class ExportResult {
  final bool   success;
  final String? filePath;
  final String? error;
  const ExportResult({required this.success, this.filePath, this.error});
}

// ── Main export service ───────────────────────────────────────────────────────
class ExportService {

  // ── Filter transactions by period ────────────────────────────────────────
  static List<TransactionEntity> filterByPeriod(
      List<TransactionEntity> all, ExportPeriod period,
      ) {
    final now = DateTime.now();
    late DateTime from;

    switch (period) {
      case ExportPeriod.thisMonth:
        from = DateTime(now.year, now.month, 1);
        break;
      case ExportPeriod.lastMonth:
        final lm = DateTime(now.year, now.month - 1, 1);
        from = lm;
        final to = DateTime(now.year, now.month, 1)
            .subtract(const Duration(seconds: 1));
        return all.where((t) =>
        t.date.isAfter(from.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(to.add(const Duration(seconds: 1)))).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case ExportPeriod.last3Months:
        from = DateTime(now.year, now.month - 2, 1);
        break;
      case ExportPeriod.last6Months:
        from = DateTime(now.year, now.month - 5, 1);
        break;
      case ExportPeriod.thisYear:
        from = DateTime(now.year, 1, 1);
        break;
      case ExportPeriod.allTime:
        return List.from(all)..sort((a, b) => b.date.compareTo(a.date));
    }

    return all.where((t) =>
        t.date.isAfter(from.subtract(const Duration(seconds: 1)))).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static String periodLabel(ExportPeriod p) {
    switch (p) {
      case ExportPeriod.thisMonth:   return 'This Month';
      case ExportPeriod.lastMonth:   return 'Last Month';
      case ExportPeriod.last3Months: return 'Last 3 Months';
      case ExportPeriod.last6Months: return 'Last 6 Months';
      case ExportPeriod.thisYear:    return 'This Year';
      case ExportPeriod.allTime:     return 'All Time';
    }
  }

  // ── Generate filename ─────────────────────────────────────────────────────
  static String _filename(ExportType type, ExportPeriod period) {
    final date   = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final period = periodLabel(ExportService._period).replaceAll(' ', '_');
    final ext    = type == ExportType.pdf ? 'pdf' : 'xlsx';
    return "Chontak_${period}_$date.$ext";
  }
  static ExportPeriod _period = ExportPeriod.thisMonth; // set before use

  // ════════════════════════════════════════════════════════════════════════════
  //  PDF EXPORT
  // ════════════════════════════════════════════════════════════════════════════
  static Future<ExportResult> exportPDF({
    required List<TransactionEntity> transactions,
    required List<CategoryEntity>    categories,
    required String                  currencySymbol,
    required ExportOptions           options,
  }) async {
    try {
      _period = options.period;
      final txs = filterByPeriod(transactions, options.period);
      final filtered = txs.where((t) =>
      (options.includeIncome  && t.type == TransactionType.income) ||
          (options.includeExpense && t.type == TransactionType.expense)
      ).toList();

      final income  = filtered.where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final expense = filtered.where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      final balance = income - expense;

      // ── Category breakdown ────────────────────────────────────────────
      final catMap = <String, double>{};
      for (final t in filtered.where((t) => t.type == TransactionType.expense)) {
        catMap[t.categoryId] = (catMap[t.categoryId] ?? 0) + t.amount;
      }
      final catBreakdown = catMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // ── Build PDF ─────────────────────────────────────────────────────
      final doc = pw.Document(
        title:   "Cho'ntak Financial Report",
        author:  'Isfandiyor Madaminov',
        subject: 'Financial Report - ${periodLabel(options.period)}',
      );

      // ── Colors ────────────────────────────────────────────────────────
      const bgDark    = PdfColor.fromInt(0xFF0F1117);
      const gold      = PdfColor.fromInt(0xFFF0B429);
      const cardBg    = PdfColor.fromInt(0xFF1E1E35);
      const greenCol  = PdfColor.fromInt(0xFF10B981);
      const redCol    = PdfColor.fromInt(0xFFEF4444);
      const textLight = PdfColor.fromInt(0xFFF1F5F9);
      const textMuted = PdfColor.fromInt(0xFF94A3B8);
      const borderCol = PdfColor.fromInt(0xFF2E2E50);
      const white     = PdfColors.white;

      // ── Fonts ─────────────────────────────────────────────────────────
      final regular = pw.Font.helvetica();
      final bold    = pw.Font.helveticaBold();

      final dateStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());

      // ── PAGE 1: Summary ───────────────────────────────────────────────
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin:     const pw.EdgeInsets.all(0),
        build: (ctx) => pw.Stack(children: [

          // Background
          pw.Container(
              width: double.infinity, height: double.infinity,
              color: bgDark),

          // Gold top accent bar
          pw.Positioned(top: 0, left: 0, right: 0,
              child: pw.Container(height: 6, color: gold)),

          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // ── Header ────────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("CHO'NTAK",
                            style: pw.TextStyle(font: bold, fontSize: 28,
                                color: gold, letterSpacing: 4)),
                        pw.SizedBox(height: 4),
                        pw.Text('Financial Report',
                            style: pw.TextStyle(font: regular, fontSize: 14,
                                color: textMuted)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(periodLabel(options.period),
                            style: pw.TextStyle(font: bold, fontSize: 14,
                                color: gold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Generated: $dateStr',
                            style: pw.TextStyle(font: regular, fontSize: 10,
                                color: textMuted)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                // Gold divider line
                pw.Container(height: 1, color: gold.shade(0.4)),
                pw.SizedBox(height: 24),

                // ── Summary cards row ─────────────────────────────────
                pw.Row(children: [
                  _pdfSummaryCard('INCOME', _fmt(income, currencySymbol),
                      greenCol, cardBg, bold, regular, textMuted),
                  pw.SizedBox(width: 12),
                  _pdfSummaryCard('EXPENSE', _fmt(expense, currencySymbol),
                      redCol, cardBg, bold, regular, textMuted),
                  pw.SizedBox(width: 12),
                  _pdfSummaryCard('BALANCE', _fmt(balance, currencySymbol),
                      balance >= 0 ? greenCol : redCol,
                      cardBg, bold, regular, textMuted),
                ]),
                pw.SizedBox(height: 24),

                // ── Stats row ─────────────────────────────────────────
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: cardBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderCol),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _pdfStatItem('Total Transactions',
                          '${filtered.length}', gold, bold, regular, textMuted),
                      _pdfStatItem('Avg. Daily Expense',
                          _fmtAvgDaily(filtered, expense, options.period,
                              currencySymbol),
                          textLight, bold, regular, textMuted),
                      _pdfStatItem('Largest Expense',
                          _fmtLargest(filtered, currencySymbol),
                          redCol, bold, regular, textMuted),
                      _pdfStatItem('Savings Rate',
                          income > 0
                              ? '${((balance / income) * 100).toStringAsFixed(1)}%'
                              : 'N/A',
                          greenCol, bold, regular, textMuted),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // ── Category breakdown ────────────────────────────────
                if (catBreakdown.isNotEmpty) ...[
                  pw.Text('SPENDING BY CATEGORY',
                      style: pw.TextStyle(font: bold, fontSize: 11,
                          color: textMuted, letterSpacing: 2)),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: cardBg,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: borderCol),
                    ),
                    child: pw.Column(
                      children: catBreakdown.take(8).toList().asMap()
                          .entries.map((e) {
                        final idx = e.key;
                        final entry = e.value;
                        final cat = categories.cast<CategoryEntity?>()
                            .firstWhere((c) => c?.id == entry.key,
                            orElse: () => null);
                        final pct = expense > 0
                            ? (entry.value / expense * 100) : 0.0;
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: pw.BoxDecoration(
                            border: idx < catBreakdown.take(8).length - 1
                                ? pw.Border(bottom: pw.BorderSide(
                                color: borderCol, width: 0.5))
                                : null,
                          ),
                          child: pw.Row(children: [
                            pw.Container(width: 3, height: 20,
                                color: _catColor(idx)),
                            pw.SizedBox(width: 10),
                            pw.Expanded(child: pw.Text(
                                cat?.name ?? 'Unknown',
                                style: pw.TextStyle(font: regular,
                                    fontSize: 11, color: textLight))),
                            pw.SizedBox(width: 8),
                            // Progress bar
                            pw.Stack(children: [
                              pw.Container(
                                  width: 80, height: 6,
                                  decoration: pw.BoxDecoration(
                                      color: borderCol,
                                      borderRadius: pw.BorderRadius.circular(3))),
                              pw.Container(
                                  width: (80 * (pct / 100).clamp(0.0, 1.0)),
                                  height: 6,
                                  decoration: pw.BoxDecoration(
                                      color: _catColor(idx),
                                      borderRadius: pw.BorderRadius.circular(3))),
                            ]),
                            pw.SizedBox(width: 8),
                            pw.SizedBox(width: 44,
                                child: pw.Text('${pct.toStringAsFixed(1)}%',
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(font: regular,
                                        fontSize: 10, color: textMuted))),
                            pw.SizedBox(width: 8),
                            pw.SizedBox(width: 90,
                                child: pw.Text(
                                    _fmt(entry.value, currencySymbol),
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(font: bold,
                                        fontSize: 11, color: textLight))),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                ],

                // ── Recent transactions (first page preview) ──────────
                pw.Text('TRANSACTIONS',
                    style: pw.TextStyle(font: bold, fontSize: 11,
                        color: textMuted, letterSpacing: 2)),
                pw.SizedBox(height: 10),

                // Table header
                _pdfTableHeader(bold, textMuted, borderCol),
                // First 15 rows on this page
                ...filtered.take(15).map((t) {
                  final cat = categories.cast<CategoryEntity?>()
                      .firstWhere((c) => c?.id == t.categoryId,
                      orElse: () => null);
                  return _pdfTableRow(t, cat, currencySymbol,
                      bold, regular, textLight, textMuted,
                      greenCol, redCol, borderCol,
                      filtered.indexOf(t).isEven);
                }),

                if (filtered.length > 15)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text(
                        '+ ${filtered.length - 15} more transactions on next page(s)',
                        style: pw.TextStyle(font: regular, fontSize: 9,
                            color: textMuted)),
                  ),
              ],
            ),
          ),

          // Footer
          pw.Positioned(bottom: 20, left: 40, right: 40,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Cho'ntak — Personal Finance",
                      style: pw.TextStyle(font: regular, fontSize: 8,
                          color: textMuted)),
                  pw.Text('Page 1',
                      style: pw.TextStyle(font: regular, fontSize: 8,
                          color: textMuted)),
                ],
              )),
        ]),
      ));

      // ── PAGE 2+: Full transaction list ────────────────────────────────
      if (filtered.length > 15) {
        final remaining = filtered.skip(15).toList();
        const rowsPerPage = 35;
        int pageNum = 2;

        for (int i = 0; i < remaining.length; i += rowsPerPage) {
          final chunk = remaining.skip(i).take(rowsPerPage).toList();
          doc.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin:     const pw.EdgeInsets.all(0),
            build: (ctx) => pw.Stack(children: [
              pw.Container(width: double.infinity,
                  height: double.infinity, color: bgDark),
              pw.Positioned(top: 0, left: 0, right: 0,
                  child: pw.Container(height: 4, color: gold)),
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(40, 28, 40, 40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("CHO'NTAK",
                            style: pw.TextStyle(font: bold, fontSize: 16,
                                color: gold, letterSpacing: 3)),
                        pw.Text('Transactions (continued)',
                            style: pw.TextStyle(font: regular, fontSize: 11,
                                color: textMuted)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(height: 0.5, color: borderCol),
                    pw.SizedBox(height: 14),
                    _pdfTableHeader(bold, textMuted, borderCol),
                    ...chunk.map((t) {
                      final cat = categories.cast<CategoryEntity?>()
                          .firstWhere((c) => c?.id == t.categoryId,
                          orElse: () => null);
                      return _pdfTableRow(t, cat, currencySymbol,
                          bold, regular, textLight, textMuted,
                          greenCol, redCol, borderCol,
                          (remaining.indexOf(t) + 15).isEven);
                    }),
                  ],
                ),
              ),
              pw.Positioned(bottom: 20, left: 40, right: 40,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Cho'ntak — Personal Finance",
                          style: pw.TextStyle(font: regular, fontSize: 8,
                              color: textMuted)),
                      pw.Text('Page $pageNum',
                          style: pw.TextStyle(font: regular, fontSize: 8,
                              color: textMuted)),
                    ],
                  )),
            ]),
          ));
          pageNum++;
        }
      }

      // ── Save and share ────────────────────────────────────────────────
      _period = options.period;
      final bytes    = await doc.save();
      final dir      = await getTemporaryDirectory();
      final filename = 'Chontak_${periodLabel(options.period).replaceAll(' ', '_')}'
          '_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
      final file     = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      return ExportResult(success: true, filePath: file.path);
    } catch (e) {
      return ExportResult(success: false, error: e.toString());
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  EXCEL EXPORT
  // ════════════════════════════════════════════════════════════════════════════
  static Future<ExportResult> exportExcel({
    required List<TransactionEntity> transactions,
    required List<CategoryEntity>    categories,
    required String                  currencySymbol,
    required ExportOptions           options,
  }) async {
    try {
      final txs = filterByPeriod(transactions, options.period);
      final filtered = txs.where((t) =>
      (options.includeIncome  && t.type == TransactionType.income) ||
          (options.includeExpense && t.type == TransactionType.expense)
      ).toList();

      final income  = filtered.where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final expense = filtered.where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      final balance = income - expense;

      final excel = xl.Excel.createExcel();

      // ── Remove default sheet ──────────────────────────────────────────
      excel.delete('Sheet1');

      // ──────────────────────────────────────────────────────────────────
      // SHEET 1: Summary
      // ──────────────────────────────────────────────────────────────────
      final summary = excel['Summary'];

      // Header styling
      final headerStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('FF0F1117'),
        fontColorHex:       xl.ExcelColor.fromHexString('FFF0B429'),
        bold:               true,
        fontSize:           14,
      );
      final labelStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('FF1E1E35'),
        fontColorHex:       xl.ExcelColor.fromHexString('FF94A3B8'),
        bold:               true,
        fontSize:           10,
      );
      final valueStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('FF1E1E35'),
        fontColorHex:       xl.ExcelColor.fromHexString('FFF1F5F9'),
        fontSize:           11,
      );
      final incomeStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('FF1E1E35'),
        fontColorHex:       xl.ExcelColor.fromHexString('FF10B981'),
        bold:               true, fontSize: 11,
      );
      final expenseStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('FF1E1E35'),
        fontColorHex:       xl.ExcelColor.fromHexString('FFEF4444'),
        bold:               true, fontSize: 11,
      );
      final balanceStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('FF1E1E35'),
        fontColorHex:       xl.ExcelColor.fromHexString(
            balance >= 0 ? 'FF10B981' : 'FFEF4444'),
        bold: true, fontSize: 12,
      );

      // Title row
      _xlCell(summary, 0, 0, "CHO'NTAK Financial Report", headerStyle);
      _xlCell(summary, 1, 0, 'Period: ${periodLabel(options.period)}', valueStyle);
      _xlCell(summary, 2, 0,
          'Generated: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
          valueStyle);

      // Summary section
      _xlCell(summary, 4, 0, 'SUMMARY', labelStyle);
      _xlCell(summary, 5, 0, 'Total Income',  labelStyle);
      _xlCell(summary, 5, 1,
          '$currencySymbol ${NumberFormat('#,##0.00').format(income)}',
          incomeStyle);
      _xlCell(summary, 6, 0, 'Total Expense', labelStyle);
      _xlCell(summary, 6, 1,
          '$currencySymbol ${NumberFormat('#,##0.00').format(expense)}',
          expenseStyle);
      _xlCell(summary, 7, 0, 'Net Balance',   labelStyle);
      _xlCell(summary, 7, 1,
          '$currencySymbol ${NumberFormat('#,##0.00').format(balance)}',
          balanceStyle);
      _xlCell(summary, 8, 0, 'Total Transactions', labelStyle);
      _xlCell(summary, 8, 1, '${filtered.length}', valueStyle);
      _xlCell(summary, 9, 0, 'Savings Rate', labelStyle);
      _xlCell(summary, 9, 1,
          income > 0 ? '${((balance/income)*100).toStringAsFixed(1)}%' : 'N/A',
          incomeStyle);

      // Category breakdown
      _xlCell(summary, 11, 0, 'SPENDING BY CATEGORY', labelStyle);
      _xlCell(summary, 12, 0, 'Category', labelStyle);
      _xlCell(summary, 12, 1, 'Amount',   labelStyle);
      _xlCell(summary, 12, 2, '%',        labelStyle);

      final catMap = <String, double>{};
      for (final t in filtered.where((t) => t.type == TransactionType.expense)) {
        catMap[t.categoryId] = (catMap[t.categoryId] ?? 0) + t.amount;
      }
      final catBreakdown = catMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      int row = 13;
      for (final e in catBreakdown) {
        final cat = categories.cast<CategoryEntity?>()
            .firstWhere((c) => c?.id == e.key, orElse: () => null);
        _xlCell(summary, row, 0, cat?.name ?? 'Unknown', valueStyle);
        _xlCell(summary, row, 1,
            '$currencySymbol ${NumberFormat('#,##0.00').format(e.value)}',
            expenseStyle);
        _xlCell(summary, row, 2,
            expense > 0 ? '${(e.value/expense*100).toStringAsFixed(1)}%' : '0%',
            valueStyle);
        row++;
      }

      // Column widths
      summary.setColumnWidth(0, 28);
      summary.setColumnWidth(1, 22);
      summary.setColumnWidth(2, 10);

      // ──────────────────────────────────────────────────────────────────
      // SHEET 2: All Transactions
      // ──────────────────────────────────────────────────────────────────
      final txSheet = excel['Transactions'];

      // Column headers
      final colHeaders = ['Date', 'Title', 'Category', 'Type', 'Amount', 'Note'];
      for (int i = 0; i < colHeaders.length; i++) {
        _xlCell(txSheet, 0, i, colHeaders[i], labelStyle);
      }

      // Data rows
      final df = DateFormat('dd/MM/yyyy');
      for (int i = 0; i < filtered.length; i++) {
        final t   = filtered[i];
        final cat = categories.cast<CategoryEntity?>()
            .firstWhere((c) => c?.id == t.categoryId, orElse: () => null);
        final isIncome = t.type == TransactionType.income;
        final rowStyle = i.isEven ? valueStyle : xl.CellStyle(
          backgroundColorHex: xl.ExcelColor.fromHexString('FF161628'),
          fontColorHex:       xl.ExcelColor.fromHexString('FFF1F5F9'),
          fontSize: 10,
        );
        final amtStyle = i.isEven
            ? (isIncome ? incomeStyle : expenseStyle)
            : xl.CellStyle(
          backgroundColorHex: xl.ExcelColor.fromHexString('FF161628'),
          fontColorHex: xl.ExcelColor.fromHexString(
              isIncome ? 'FF10B981' : 'FFEF4444'),
          bold: true, fontSize: 10,
        );

        _xlCell(txSheet, i+1, 0, df.format(t.date),       rowStyle);
        _xlCell(txSheet, i+1, 1, t.title,                 rowStyle);
        _xlCell(txSheet, i+1, 2, cat?.name ?? 'Unknown',  rowStyle);
        _xlCell(txSheet, i+1, 3,
            isIncome ? 'Income' : 'Expense', rowStyle);
        _xlCell(txSheet, i+1, 4,
            '${isIncome ? '+' : '-'} $currencySymbol '
                '${NumberFormat('#,##0.00').format(t.amount)}',
            amtStyle);
        _xlCell(txSheet, i+1, 5, t.note ?? '', rowStyle);
      }

      // Column widths
      txSheet.setColumnWidth(0, 14);
      txSheet.setColumnWidth(1, 28);
      txSheet.setColumnWidth(2, 18);
      txSheet.setColumnWidth(3, 10);
      txSheet.setColumnWidth(4, 20);
      txSheet.setColumnWidth(5, 30);

      // ──────────────────────────────────────────────────────────────────
      // SHEET 3: Monthly breakdown
      // ──────────────────────────────────────────────────────────────────
      final monthSheet = excel['Monthly'];
      _xlCell(monthSheet, 0, 0, 'Month',   labelStyle);
      _xlCell(monthSheet, 0, 1, 'Income',  labelStyle);
      _xlCell(monthSheet, 0, 2, 'Expense', labelStyle);
      _xlCell(monthSheet, 0, 3, 'Balance', labelStyle);

      final monthMap = <String, Map<String, double>>{};
      for (final t in filtered) {
        final key = DateFormat('yyyy-MM').format(t.date);
        monthMap[key] ??= {'income': 0, 'expense': 0};
        if (t.type == TransactionType.income) {
          monthMap[key]!['income'] = (monthMap[key]!['income']! + t.amount);
        } else {
          monthMap[key]!['expense'] = (monthMap[key]!['expense']! + t.amount);
        }
      }

      final months = monthMap.keys.toList()..sort();
      int mRow = 1;
      for (final m in months) {
        final inc  = monthMap[m]!['income']!;
        final exp  = monthMap[m]!['expense']!;
        final bal  = inc - exp;
        final mLabel = DateFormat('MMMM yyyy')
            .format(DateFormat('yyyy-MM').parse(m));
        _xlCell(monthSheet, mRow, 0, mLabel, valueStyle);
        _xlCell(monthSheet, mRow, 1,
            '$currencySymbol ${NumberFormat('#,##0.00').format(inc)}',
            incomeStyle);
        _xlCell(monthSheet, mRow, 2,
            '$currencySymbol ${NumberFormat('#,##0.00').format(exp)}',
            expenseStyle);
        _xlCell(monthSheet, mRow, 3,
            '$currencySymbol ${NumberFormat('#,##0.00').format(bal)}',
            bal >= 0 ? incomeStyle : expenseStyle);
        mRow++;
      }

      monthSheet.setColumnWidth(0, 18);
      monthSheet.setColumnWidth(1, 20);
      monthSheet.setColumnWidth(2, 20);
      monthSheet.setColumnWidth(3, 20);

      // ── Save ──────────────────────────────────────────────────────────
      final dir  = await getTemporaryDirectory();
      final name = 'Chontak_${periodLabel(options.period).replaceAll(' ', '_')}'
          '_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$name');
      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save returned null');
      await file.writeAsBytes(bytes);

      return ExportResult(success: true, filePath: file.path);
    } catch (e) {
      return ExportResult(success: false, error: e.toString());
    }
  }

  // ── Share file ────────────────────────────────────────────────────────────
  static Future<void> shareFile(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }

  // ── Open file ─────────────────────────────────────────────────────────────
  static Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }

  // ── PDF helper builders ───────────────────────────────────────────────────
  static pw.Widget _pdfSummaryCard(
      String label, String value, PdfColor valueColor,
      PdfColor bg, pw.Font bold, pw.Font regular, PdfColor muted,
      ) => pw.Expanded(child: pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
        color: bg, borderRadius: pw.BorderRadius.circular(8)),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(font: regular, fontSize: 9,
                color: muted, letterSpacing: 1.5)),
        pw.SizedBox(height: 6),
        pw.Text(value,
            style: pw.TextStyle(font: bold, fontSize: 14,
                color: valueColor)),
      ],
    ),
  ));

  static pw.Widget _pdfStatItem(
      String label, String value, PdfColor valueColor,
      pw.Font bold, pw.Font regular, PdfColor muted,
      ) => pw.Column(children: [
    pw.Text(value,
        style: pw.TextStyle(font: bold, fontSize: 14, color: valueColor)),
    pw.SizedBox(height: 4),
    pw.Text(label,
        style: pw.TextStyle(font: regular, fontSize: 8,
            color: muted, letterSpacing: 0.5)),
  ]);

  static pw.Widget _pdfTableHeader(
      pw.Font bold, PdfColor muted, PdfColor border,
      ) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: border, width: 1))),
    child: pw.Row(children: [
      pw.SizedBox(width: 68,
          child: pw.Text('DATE', style: pw.TextStyle(font: bold,
              fontSize: 8, color: muted, letterSpacing: 1.2))),
      pw.Expanded(child: pw.Text('TITLE', style: pw.TextStyle(font: bold,
          fontSize: 8, color: muted, letterSpacing: 1.2))),
      pw.SizedBox(width: 80, child: pw.Text('CATEGORY',
          style: pw.TextStyle(font: bold, fontSize: 8,
              color: muted, letterSpacing: 1.2))),
      pw.SizedBox(width: 96, child: pw.Text('AMOUNT',
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(font: bold, fontSize: 8,
              color: muted, letterSpacing: 1.2))),
    ]),
  );

  static pw.Widget _pdfTableRow(
      TransactionEntity t, CategoryEntity? cat,
      String currency, pw.Font bold, pw.Font regular,
      PdfColor textLight, PdfColor textMuted,
      PdfColor greenCol, PdfColor redCol, PdfColor border,
      bool isEven,
      ) {
    final isIncome = t.type == TransactionType.income;
    final bg = isEven
        ? const PdfColor.fromInt(0xFF1E1E35)
        : const PdfColor.fromInt(0xFF18182C);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: pw.BoxDecoration(color: bg),
      child: pw.Row(children: [
        pw.SizedBox(width: 68, child: pw.Text(
            DateFormat('dd MMM yy').format(t.date),
            style: pw.TextStyle(font: regular, fontSize: 9, color: textMuted))),
        pw.Expanded(child: pw.Text(t.title,
            style: pw.TextStyle(font: regular, fontSize: 9, color: textLight),
            maxLines: 1)),
        pw.SizedBox(width: 80, child: pw.Text(cat?.name ?? '—',
            style: pw.TextStyle(font: regular, fontSize: 9, color: textMuted),
            maxLines: 1)),
        pw.SizedBox(width: 96, child: pw.Text(
            '${isIncome ? '+' : '-'} ${_fmt(t.amount, currency)}',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: bold, fontSize: 9,
                color: isIncome ? greenCol : redCol))),
      ]),
    );
  }

  // ── Excel cell helper ─────────────────────────────────────────────────────
  static void _xlCell(xl.Sheet sheet, int row, int col,
      String value, xl.CellStyle style) {
    final cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = xl.TextCellValue(value);
    cell.cellStyle = style;
  }

  // ── Formatting helpers ────────────────────────────────────────────────────
  static String _fmt(double amount, String currency) {
    return '$currency ${NumberFormat('#,##0.00').format(amount)}';
  }

  static String _fmtAvgDaily(List<TransactionEntity> txs,
      double expense, ExportPeriod period, String currency) {
    if (txs.isEmpty) return 'N/A';
    final days = switch (period) {
      ExportPeriod.thisMonth   => DateTime.now().day,
      ExportPeriod.lastMonth   => 30,
      ExportPeriod.last3Months => 90,
      ExportPeriod.last6Months => 180,
      ExportPeriod.thisYear    => DateTime.now().dayOfYear,
      ExportPeriod.allTime     => 365,
    };
    return _fmt(expense / days, currency);
  }

  static String _fmtLargest(
      List<TransactionEntity> txs, String currency) {
    final expenses = txs.where((t) => t.type == TransactionType.expense);
    if (expenses.isEmpty) return 'N/A';
    final max = expenses.map((t) => t.amount).reduce((a, b) => a > b ? a : b);
    return _fmt(max, currency);
  }

  static PdfColor _catColor(int index) {
    const colors = [
      PdfColor.fromInt(0xFF7C3AED),
      PdfColor.fromInt(0xFF06B6D4),
      PdfColor.fromInt(0xFFF59E0B),
      PdfColor.fromInt(0xFF10B981),
      PdfColor.fromInt(0xFFEC4899),
      PdfColor.fromInt(0xFF3B82F6),
      PdfColor.fromInt(0xFFF97316),
      PdfColor.fromInt(0xFF84CC16),
    ];
    return colors[index % colors.length];
  }
}

// ── Extension for day of year ─────────────────────────────────────────────────
extension _DateExt on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays + 1;
  }
}