import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/local_database.dart';
import '../../data/repositories/saving_repository_impl.dart';
import '../blocs/saving/saving_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/budget/budget_bloc.dart';
import '../blocs/category/category_bloc.dart';
import 'home_page.dart';
import 'stats_page.dart';
import 'savings_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  final bool isDark;
  final String currency;
  final String currencySymbol;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onCurrencyChanged;

  const MainShell({
    super.key,
    required this.isDark,
    required this.currency,
    required this.currencySymbol,
    required this.onThemeChanged,
    required this.onCurrencyChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      HomePage(currencySymbol: widget.currencySymbol),
      StatsPage(currencySymbol: widget.currencySymbol),
      BlocProvider(
        create: (_) => SavingBloc(
          repository: SavingRepositoryImpl(LocalDatabase.instance),
        ),
        child: SavingsPage(currencySymbol: widget.currencySymbol),
      ),
      SettingsPage(
        isDark: widget.isDark,
        currency: widget.currency,
        onThemeChanged: widget.onThemeChanged,
        onCurrencyChanged: widget.onCurrencyChanged,
      ),
    ];

    final items = [
      (Iconsax.home,      Iconsax.home_2,      t.home),
      (Iconsax.chart_2,   Iconsax.chart_21,    t.stats),
      (Iconsax.coin,      Iconsax.coin_1,      t.savingsGoals),
      (Iconsax.setting_2, Iconsax.setting,     t.settings),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: items.asMap().entries.map((e) {
            final idx    = e.key;
            final item   = e.value;
            final active = _currentIndex == idx;
            return BottomNavigationBarItem(
              label: item.$3,
              icon: _AnimatedNavIcon(
                icon:       item.$1,
                activeIcon: item.$2,
                active:     active,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Animated nav icon ─────────────────────────────────────────────────────────
class _AnimatedNavIcon extends StatefulWidget {
  final IconData icon, activeIcon;
  final bool active;
  const _AnimatedNavIcon({
    required this.icon, required this.activeIcon, required this.active});

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 1.0, end: 1.25).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_AnimatedNavIcon old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active) {
      _ctrl..reset()..forward();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: widget.active ? _scale.value : 1.0,
        child: Icon(
          widget.active ? widget.activeIcon : widget.icon,
          color: widget.active ? AppColors.gold : null,
        ),
      ),
    );
  }
}