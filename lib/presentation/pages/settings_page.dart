import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/transaction/transaction_bloc.dart';
import 'export_page.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/i18n/translations.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/app_lock_service.dart';
import '../../data/datasources/local_database.dart';
import 'lock_screen.dart';
import 'category_page.dart';
import 'category_budget_page.dart';
import '../blocs/category_budget/category_budget_bloc.dart';
import '../blocs/category/category_bloc.dart';

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final String currency;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onCurrencyChanged;

  const SettingsPage({
    super.key,
    required this.isDark,
    required this.currency,
    required this.onThemeChanged,
    required this.onCurrencyChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _selectedCurrency;

  bool _notifsEnabled = true;
  int _notifHour = 9;
  int _notifMinute = 0;

  int _eveningNotifHour = 20;
  int _eveningNotifMinute = 30;

  bool _lockEnabled = false;
  int _widgetOpacity = 80;
  bool _bioEnabled = false;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currency;
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bioAvail = await AppLockService.instance.isBiometricAvailable;
    final lockOn = await AppLockService.instance.isEnabled;
    final opacity = prefs.getInt('widget_opacity') ?? 80;
    final bioOn = await AppLockService.instance.useBiometric;

    setState(() {
      _notifsEnabled = prefs.getBool('notif_enabled') ?? true;
      _notifHour = prefs.getInt('notif_hour') ?? 9;
      _notifMinute = prefs.getInt('notif_minute') ?? 0;

      _eveningNotifHour = prefs.getInt('evening_notif_hour') ?? 20;
      _eveningNotifMinute = prefs.getInt('evening_notif_minute') ?? 30;

      _lockEnabled = lockOn;
      _widgetOpacity = opacity;
      _bioEnabled = bioOn;
      _bioAvailable = bioAvail;
    });
  }

  Future<void> _saveNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', _notifsEnabled);
    await prefs.setInt('notif_hour', _notifHour);
    await prefs.setInt('notif_minute', _notifMinute);
    await prefs.setInt('evening_notif_hour', _eveningNotifHour);
    await prefs.setInt('evening_notif_minute', _eveningNotifMinute);
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _morningTimeLabel => _formatTime(_notifHour, _notifMinute);
  String get _eveningTimeLabel =>
      _formatTime(_eveningNotifHour, _eveningNotifMinute);

  String _eveningNotifLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.uz:
        return 'Kechki eslatma';
      case AppLanguage.ru:
        return 'Вечернее напоминание';
      case AppLanguage.en:
        return 'Evening reminder';
    }
  }

  Future<void> _rescheduleNotifications(Translations t) async {
    if (!_notifsEnabled) return;

    await NotificationService.instance.scheduleMorningNotification(
      t: t,
      balance: 0,
      totalExpense: 0,
      budgetLimit: 0,
      currencySymbol: _currencySymbol,
      hour: _notifHour,
      minute: _notifMinute,
    );

    await NotificationService.instance.scheduleEveningReminder(
      t: t,
      hour: _eveningNotifHour,
      minute: _eveningNotifMinute,
    );
  }

  Future<void> _pickMorningTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifHour, minute: _notifMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.gold),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _notifHour = picked.hour;
      _notifMinute = picked.minute;
    });

    await _saveNotifPrefs();

    final t = context.read<LanguageProvider>().t;
    await _rescheduleNotifications(t);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ertalabki xabarnoma $_morningTimeLabel ga o'rnatildi ✅"),
          backgroundColor: AppColors.gold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickEveningTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
      TimeOfDay(hour: _eveningNotifHour, minute: _eveningNotifMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.gold),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _eveningNotifHour = picked.hour;
      _eveningNotifMinute = picked.minute;
    });

    await _saveNotifPrefs();

    final t = context.read<LanguageProvider>().t;
    await _rescheduleNotifications(t);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kechki eslatma $_eveningTimeLabel ga o'rnatildi ✅"),
          backgroundColor: AppColors.gold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String get _currencySymbol {
    return AppConstants.currencies.firstWhere(
          (c) => c['code'] == _selectedCurrency,
      orElse: () => AppConstants.currencies.first,
    )['symbol'] ??
        "so'm";
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(t.categories, [
              _SettingsTile(
                icon: Icons.category_rounded,
                iconColor: const Color(0xFF9C27B0),
                title: t.customCategories,
                subtitle: t.addCategory,
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.gold),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<CategoryBloc>(),
                      child: const CategoriesPage(),
                    ),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Iconsax.chart,
                iconColor: AppColors.gold,
                title: t.categoryBudgets,
                subtitle: t.categoryBudgetsSub,
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.gold),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<CategoryBloc>()),
                        BlocProvider.value(
                            value: context.read<TransactionBloc>()),
                        BlocProvider.value(
                            value: context.read<CategoryBudgetBloc>()),
                      ],
                      child: CategoryBudgetPage(currencySymbol: _currencySymbol),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _Section(t.exportData, [
              _SettingsTile(
                icon: Iconsax.document_download,
                iconColor: const Color(0xFFEF4444),
                title: t.exportReport,
                subtitle: t.exportSub,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D6F42).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'XLS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D6F42),
                      ),
                    ),
                  ),
                ]),
                onTap: () {
                  final txState = context.read<TransactionBloc>().state;
                  final catState = context.read<CategoryBloc>().state;
                  if (txState is! TransactionLoaded) return;
                  if (catState is! CategoryLoaded) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExportPage(
                        transactions: txState.transactions,
                        categories: catState.categories,
                        currencySymbol: _currencySymbol,
                      ),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 20),
            _Section(t.languages, [
              _LangTile(
                flag: '🇺🇿',
                label: "O'zbek",
                selected: langProvider.language == AppLanguage.uz,
                onTap: () async {
                  langProvider.setLanguage(AppLanguage.uz);
                  await _rescheduleNotifications(langProvider.t);
                },
              ),
              _LangTile(
                flag: '🇷🇺',
                label: 'Русский',
                selected: langProvider.language == AppLanguage.ru,
                onTap: () async {
                  langProvider.setLanguage(AppLanguage.ru);
                  await _rescheduleNotifications(langProvider.t);
                },
              ),
              _LangTile(
                flag: '🇬🇧',
                label: 'English',
                selected: langProvider.language == AppLanguage.en,
                onTap: () async {
                  langProvider.setLanguage(AppLanguage.en);
                  await _rescheduleNotifications(langProvider.t);
                },
              ),
            ]),
            const SizedBox(height: 20),
            _Section(t.appearance, [
              _SettingsTile(
                icon: Iconsax.moon,
                iconColor: AppColors.gold,
                title: t.darkMode,
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: widget.onThemeChanged,
                  activeColor: AppColors.amber,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _Section(t.notifications, [
              _SettingsTile(
                icon: Iconsax.notification,
                iconColor: _notifsEnabled ? AppColors.gold : Colors.grey,
                title: t.notifications,
                subtitle: _notifsEnabled ? t.notifOn : t.notifOff,
                trailing: Switch(
                  value: _notifsEnabled,
                  onChanged: (val) async {
                    setState(() => _notifsEnabled = val);
                    await _saveNotifPrefs();

                    if (!val) {
                      await NotificationService.instance.cancelAll();
                    } else {
                      await _rescheduleNotifications(t);
                    }
                  },
                  activeColor: AppColors.amber,
                ),
              ),
              if (_notifsEnabled) ...[
                _SettingsTile(
                  icon: Iconsax.sun_1,
                  iconColor: AppColors.gold,
                  title: t.morningNotif,
                  subtitle: _morningTimeLabel,
                  trailing: const Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  onTap: _pickMorningTime,
                ),
                _SettingsTile(
                  icon: Iconsax.moon,
                  iconColor: AppColors.gold,
                  title: _eveningNotifLabel(langProvider.language),
                  subtitle: _eveningTimeLabel,
                  trailing: const Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  onTap: _pickEveningTime,
                ),
              ],
            ]),
            const SizedBox(height: 20),
            _Section(t.widgetSettings, [
              _SettingsTile(
                icon: Iconsax.mobile,
                iconColor: AppColors.gold,
                title: t.widgetOpacity,
                subtitle: '${_widgetOpacity}%',
                trailing: const SizedBox.shrink(),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Text('20%', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Slider(
                        value: _widgetOpacity.toDouble(),
                        min: 20,
                        max: 100,
                        divisions: 16,
                        activeColor: AppColors.amber,
                        onChanged: (v) async {
                          setState(() => _widgetOpacity = v.toInt());
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('widget_opacity', v.toInt());
                          await LocalDatabase.notifyWidget();
                        },
                      ),
                    ),
                    const Text('100%', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _Section(t.appLock, [
              _SettingsTile(
                icon: Iconsax.lock,
                iconColor: _lockEnabled ? AppColors.gold : Colors.grey,
                title: t.appLockTitle,
                subtitle: _lockEnabled ? t.lockOn : t.lockOff,
                trailing: Switch(
                  value: _lockEnabled,
                  onChanged: (val) async {
                    if (val) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LockScreen(
                            isSetup: true,
                            onUnlocked: () => Navigator.pop(context),
                          ),
                        ),
                      );
                      final enabled = await AppLockService.instance.isEnabled;
                      setState(() => _lockEnabled = enabled);
                    } else {
                      await AppLockService.instance.disableAll();
                      setState(() {
                        _lockEnabled = false;
                        _bioEnabled = false;
                      });
                    }
                  },
                  activeColor: AppColors.amber,
                ),
              ),
              if (_lockEnabled && _bioAvailable)
                _SettingsTile(
                  icon: Icons.fingerprint,
                  iconColor: _bioEnabled ? AppColors.gold : Colors.grey,
                  title: t.biometric,
                  subtitle: t.biometricSub,
                  trailing: Switch(
                    value: _bioEnabled,
                    onChanged: (val) async {
                      await AppLockService.instance.setUseBiometric(val);
                      setState(() => _bioEnabled = val);
                    },
                    activeColor: AppColors.amber,
                  ),
                ),
              if (_lockEnabled)
                _SettingsTile(
                  icon: Iconsax.refresh,
                  iconColor: AppColors.gold,
                  title: t.changePin,
                  onTap: () async {
                    await AppLockService.instance.disableAll();
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LockScreen(
                          isSetup: true,
                          onUnlocked: () => Navigator.pop(context),
                        ),
                      ),
                    );
                    final enabled = await AppLockService.instance.isEnabled;
                    setState(() => _lockEnabled = enabled);
                  },
                ),
            ]),
            const SizedBox(height: 20),
            _Section(t.currency, [
              ...AppConstants.currencies.map((cur) {
                final selected = _selectedCurrency == cur['code'];
                return _SettingsTile(
                  icon: Iconsax.money,
                  iconColor: selected ? AppColors.gold : Colors.grey,
                  title: cur['name']!,
                  subtitle: '${cur['code']} · ${cur['symbol']}',
                  trailing: selected
                      ? const Icon(Iconsax.tick_circle,
                      color: AppColors.gold, size: 20)
                      : null,
                  onTap: () async {
                    setState(() => _selectedCurrency = cur['code']!);
                    widget.onCurrencyChanged(cur['code']!);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(AppConstants.currencyKey, cur['code']!);

                    final langT = context.read<LanguageProvider>().t;
                    await _rescheduleNotifications(langT);
                  },
                );
              }),
            ]),
            const SizedBox(height: 20),
            _Section(t.aboutApp, [
              _SettingsTile(
                icon: Iconsax.wallet,
                iconColor: AppColors.gold,
                title: "Cho'ntak",
                subtitle: AppConstants.appSlogan,
              ),
              _SettingsTile(
                icon: Iconsax.info_circle,
                iconColor: AppColors.gold,
                title: t.version,
              ),
              _SettingsTile(
                icon: Iconsax.code,
                iconColor: AppColors.gold,
                title: t.developer,
                subtitle: 'Isfandiyor Madaminov',
              ),
              _SettingsTile(
                icon: Iconsax.refresh,
                iconColor: AppColors.amber,
                title: "Kirish sahifasini ko'rish",
                subtitle: "Onboarding-ni qayta ko'rsatish",
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_done', false);
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                    runApp(const SizedBox.shrink());
                  }
                },
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String flag, label;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? AppColors.gold : null,
        ),
      ),
      trailing: selected
          ? const Icon(Iconsax.tick_circle, color: AppColors.gold, size: 20)
          : null,
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.goldDim,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    Divider(
                      height: 1,
                      color:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle!,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      )
          : null,
      trailing: trailing,
    );
  }
}