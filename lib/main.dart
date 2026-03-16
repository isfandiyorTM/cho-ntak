import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/i18n/language_provider.dart';
import 'core/i18n/translations.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/local_database.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'data/repositories/budget_repository_impl.dart';
import 'data/repositories/category_repository_impl.dart';
import 'domain/usecases/get_transactions.dart';
import 'domain/usecases/add_transaction.dart';
import 'domain/usecases/update_transaction.dart';
import 'domain/usecases/delete_transaction.dart';
import 'domain/usecases/get_budget.dart';
import 'domain/usecases/set_budget.dart';
import 'presentation/blocs/transaction/transaction_bloc.dart';
import 'presentation/blocs/budget/budget_bloc.dart';
import 'presentation/blocs/category/category_bloc.dart';
import 'presentation/pages/main_shell.dart';
import 'presentation/pages/onboarding_page.dart';
import 'presentation/pages/lock_screen.dart';
import 'core/services/app_lock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  final prefs          = await SharedPreferences.getInstance();
  final isDark         = prefs.getBool(AppConstants.themeKey) ?? true;
  final currencyCode   = prefs.getString(AppConstants.currencyKey) ?? 'UZS';
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  final lockEnabled    = await AppLockService.instance.isEnabled;

  AppTheme.applySystemUI(isDark);

  runApp(ChontakApp(
    isDark:         isDark,
    currencyCode:   currencyCode,
    showOnboarding: !onboardingDone,
    showLock:       lockEnabled,
  ));
}

class ChontakApp extends StatefulWidget {
  final bool isDark;
  final String currencyCode;
  final bool showOnboarding;
  final bool showLock;
  const ChontakApp({
    super.key,
    required this.isDark,
    required this.currencyCode,
    required this.showOnboarding,
    required this.showLock,
  });

  @override
  State<ChontakApp> createState() => _ChontakAppState();
}

class _ChontakAppState extends State<ChontakApp> {
  late ThemeNotifier   _themeNotifier;
  late String          _currencyCode;
  late bool            _showOnboarding;
  late bool            _showLock;

  late final LocalDatabase             _db;
  late final TransactionRepositoryImpl _txRepo;
  late final BudgetRepositoryImpl      _budgetRepo;
  late final CategoryRepositoryImpl    _categoryRepo;
  late final LanguageProvider          _langProvider;

  @override
  void initState() {
    super.initState();
    _themeNotifier  = ThemeNotifier(widget.isDark);
    _showOnboarding = widget.showOnboarding;
    _showLock       = widget.showLock;
    _currencyCode   = widget.currencyCode;
    _db             = LocalDatabase.instance;
    _txRepo         = TransactionRepositoryImpl(_db);
    _budgetRepo     = BudgetRepositoryImpl(_db);
    _categoryRepo   = CategoryRepositoryImpl();
    _langProvider   = LanguageProvider();

    Future.delayed(const Duration(seconds: 2), _scheduleDaily);
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  Future<void> _scheduleDaily() async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_enabled') ?? true;
      if (!enabled) return;

      final now    = DateTime.now();
      final symbol = _currencySymbol;
      final hour   = prefs.getInt('notif_hour')   ?? 9;
      final minute = prefs.getInt('notif_minute') ?? 0;

      final transactions =
      await _txRepo.getTransactionsByMonth(now.month, now.year);
      final budget =
      await _budgetRepo.getBudgetByMonth(now.month, now.year);
      final carryover =
      await _txRepo.getCarryover(now.month, now.year);

      double income = 0, expense = 0;
      for (final tx in transactions) {
        if (tx.type.name == 'income')  income  += tx.amount;
        if (tx.type.name == 'expense') expense += tx.amount;
      }

      final balance     = carryover + income - expense;
      final budgetLimit = budget?.limit ?? 0;

      await NotificationService.instance.scheduleDailyNotification(
        balance:        balance,
        totalExpense:   expense,
        budgetLimit:    budgetLimit,
        currencySymbol: symbol,
        hour:           hour,
        minute:         minute,
      );
    } catch (e) {
      debugPrint('Notification schedule error: $e');
    }
  }

  String get _currencySymbol {
    return AppConstants.currencies.firstWhere(
          (c) => c['code'] == _currencyCode,
      orElse: () => AppConstants.currencies.first,
    )['symbol'] ??
        "so'm";
  }

  void _handleCurrencyChange(String code) {
    setState(() => _currencyCode = code);
    SharedPreferences.getInstance()
        .then((p) => p.setString(AppConstants.currencyKey, code));
  }

  // Called by OnboardingPage when user finishes — applies language + currency
  // to the live provider tree before showing MainShell
  void _completeOnboarding(AppLanguage lang, String currencyCode) {
    _langProvider.setLanguage(lang);
    setState(() {
      _showOnboarding = false;
      _currencyCode   = currencyCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeNotifier),
        ChangeNotifierProvider.value(value: _langProvider),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => TransactionBloc(
              getTransactions:   GetTransactions(_txRepo),
              addTransaction:    AddTransaction(_txRepo),
              updateTransaction: UpdateTransaction(_txRepo),
              deleteTransaction: DeleteTransaction(_txRepo),
              repository:        _txRepo,
            ),
          ),
          BlocProvider(
            create: (_) => BudgetBloc(
              getBudget:  GetBudget(_budgetRepo),
              setBudget:  SetBudget(_budgetRepo),
              repository: _budgetRepo,
            ),
          ),
          BlocProvider(
            create: (_) => CategoryBloc(repository: _categoryRepo),
          ),
        ],
        // ── Consumer<ThemeNotifier> is the ONLY thing that rebuilds MaterialApp
        child: Consumer<ThemeNotifier>(
          builder: (context, themeNotifier, _) {
            return Consumer<LanguageProvider>(
              builder: (context, langProvider, _) {
                _categoryRepo.updateLanguage(langProvider.t);
                return MaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  theme:     AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  // ← This is now driven by ThemeNotifier, guaranteed reactive
                  themeMode: themeNotifier.isDark
                      ? ThemeMode.dark
                      : ThemeMode.light,
                  home: _showOnboarding
                      ? OnboardingPage(onComplete: _completeOnboarding)
                      : _showLock
                      ? LockScreen(
                    onUnlocked: () =>
                        setState(() => _showLock = false),
                  )
                      : MainShell(
                    isDark:            themeNotifier.isDark,
                    currency:          _currencyCode,
                    currencySymbol:    _currencySymbol,
                    onThemeChanged:    themeNotifier.setDark,
                    onCurrencyChanged: _handleCurrencyChange,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}