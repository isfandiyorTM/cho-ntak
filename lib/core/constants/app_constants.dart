class AppConstants {
  AppConstants._();

  static const String appName        = "Cho'ntak";
  static const String appSlogan      = "Cho'ntagingizga qarab ish qiling";
  static const String dbName         = 'chontak.db';
  static const int    dbVersion      = 2;

  static const String transactionsTable = 'transactions';
  static const String categoriesTable   = 'categories';
  static const String budgetsTable      = 'budgets';
  static const String savingsTable      = 'savings';

  static const String themeKey        = 'theme_mode';
  static const String currencyKey     = 'currency';
  static const double defaultBudgetAlertThreshold = 0.8;

  // Notification IDs
  static const int morningNotifId = 1001;
  static const int appOpenNotifId = 1002;

  // Notification channel
  static const String notifChannelId   = 'chontak_channel';
  static const String notifChannelName = "Cho'ntak Bildirishnomalar";

  static const List<Map<String, String>> currencies = [
    // Default
    {'code': 'UZS', 'symbol': "so'm", 'name': 'Uzbek Som'},
    // Major
    {'code': 'USD', 'symbol': '\$',   'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€',    'name': 'Euro'},
    {'code': 'RUB', 'symbol': '₽',    'name': 'Russian Ruble'},
    {'code': 'GBP', 'symbol': '£',    'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥',    'name': 'Japanese Yen'},
    {'code': 'CNY', 'symbol': '¥',    'name': 'Chinese Yuan'},
    {'code': 'KZT', 'symbol': '₸',    'name': 'Kazakhstani Tenge'},
    {'code': 'TRY', 'symbol': '₺',    'name': 'Turkish Lira'},
    {'code': 'AED', 'symbol': 'د.إ',  'name': 'UAE Dirham'},
    {'code': 'SAR', 'symbol': '﷼',    'name': 'Saudi Riyal'},
    {'code': 'CHF', 'symbol': 'Fr',   'name': 'Swiss Franc'},
    {'code': 'CAD', 'symbol': 'C\$',  'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$',  'name': 'Australian Dollar'},
    {'code': 'KRW', 'symbol': '₩',    'name': 'South Korean Won'},
  ];
}