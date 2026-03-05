import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Full format — always shows exact number with separators
  // e.g. 2,000,000.00 or 1,250,000.00
  static String format(double amount, String currencySymbol) {
    final formatter = NumberFormat('#,##0.00');
    return '$currencySymbol ${formatter.format(amount)}';
  }

  // Summary format — exact number with separators, no decimals for large amounts
  // e.g.  999        → "$ 999.00"
  //       1,500      → "$ 1,500"
  //       2,000,000  → "$ 2,000,000"
  //       1,250,500  → "$ 1,250,500"
  static String formatCompact(double amount, String currencySymbol) {
    if (amount >= 1000) {
      final formatter = NumberFormat('#,##0');
      return '$currencySymbol ${formatter.format(amount)}';
    }
    return format(amount, currencySymbol);
  }
}