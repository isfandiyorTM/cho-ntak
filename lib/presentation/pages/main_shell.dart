import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/local_database.dart';
import '../../data/repositories/saving_repository_impl.dart';
import '../blocs/saving/saving_bloc.dart';
import 'package:iconsax/iconsax.dart';
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

  // ── Pages are built ONCE and kept alive — never recreated on rebuild ─────
  // This is the critical fix: building pages inside build() caused:
  //   1. HomePage to recreate → initState fires → postFrameCallback on dead widget
  //   2. SettingsPage to recreate → onThemeChanged closure stale in release AOT
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
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
  }

  @override
  Widget build(BuildContext context) {
    final t      = context.watch<LanguageProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      _NavItem(icon: Iconsax.home,       activeIcon: Iconsax.home_2,    label: t.home),
      _NavItem(icon: Iconsax.chart_2,    activeIcon: Iconsax.chart_21,  label: t.stats),
      _NavItem(icon: Iconsax.coin,       activeIcon: Iconsax.coin_1,    label: t.savingsGoals),
      _NavItem(icon: Iconsax.setting_2,  activeIcon: Iconsax.setting,   label: t.settings),
    ];

    return Scaffold(
      body: IndexedStack(
        // IndexedStack keeps all pages alive AND mounted — no recreation ever
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: navItems,
        isDark: isDark,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final bool isDark;
  final ValueChanged<int> onTap;
  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: items.asMap().entries.map((e) {
              final idx    = e.key;
              final item   = e.value;
              final active = currentIndex == idx;
              return Expanded(
                child: _NavButton(
                  item:    item,
                  active:  active,
                  isDark:  isDark,
                  onTap:   () => onTap(idx),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool active, isDark;
  final VoidCallback onTap;
  const _NavButton({
    required this.item,
    required this.active,
    required this.isDark,
    required this.onTap,
  });
  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _scale = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_NavButton old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active) {
      _ctrl..reset()..forward();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final isDark = widget.isDark;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: active ? _scale.value : 1.0,
          child: child,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? (isDark
                    ? AppColors.amber.withValues(alpha: 0.15)
                    : AppColors.navyText.withValues(alpha: 0.08))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                active ? widget.item.activeIcon : widget.item.icon,
                size: 20,
                color: active
                    ? (isDark ? AppColors.amber : AppColors.navyText)
                    : (isDark
                    ? AppColors.mutedDark
                    : AppColors.mutedLight),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? (isDark ? AppColors.amber : AppColors.navyText)
                    : (isDark
                    ? AppColors.mutedDark
                    : AppColors.mutedLight),
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}