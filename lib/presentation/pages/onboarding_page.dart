import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/translations.dart';
import 'main_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cho'ntak Onboarding — 5 swipeable slides
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  // Called when onboarding completes — parent applies lang + currency
  final void Function(AppLanguage lang, String currency) onComplete;
  const OnboardingPage({super.key, required this.onComplete});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  double _page          = 0;          // fractional page for parallax
  int    _currentPage   = 0;
  String _selectedCurrency = 'UZS';
  AppLanguage _selectedLanguage = AppLanguage.uz;

  // Live translations driven by selected language (no Provider needed here)
  Translations get _t => Translations(_selectedLanguage);

  static const _total = 5;

  // Per-slide accent colors
  static const _colors = [
    Color(0xFFF0B429), // amber  — welcome
    Color(0xFF22C55E), // green  — track
    Color(0xFF60A5FA), // blue   — stats
    Color(0xFFA78BFA), // purple — savings
    Color(0xFFF0B429), // amber  — ready
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _pageCtrl.addListener(() {
      final newPage = _pageCtrl.page ?? 0;
      // Fire haptic when crossing a page boundary
      if ((newPage - _page).abs() >= 1.0) {
        HapticFeedback.lightImpact();
      }
      setState(() => _page = newPage);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _total - 1) {
      HapticFeedback.lightImpact();
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic);
    } else {
      HapticFeedback.mediumImpact();
      _finish();
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    _finish();
  }

  Future<void> _finish() async {
    // Save prefs first
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setString(AppConstants.currencyKey, _selectedCurrency);
    await prefs.setString('app_language', _selectedLanguage.name);
    if (!mounted) return;
    // Notify parent — it will call LanguageProvider.setLanguage()
    // which propagates through the entire Provider tree before rebuilding.
    // This is the only correct way: pushReplacement bypasses the provider tree.
    widget.onComplete(_selectedLanguage, _selectedCurrency);
  }

  Color get _accent => _colors[_currentPage];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: Stack(
        children: [

          // ── Animated gradient background ──────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.6, -0.6),
                radius: 1.4,
                colors: [
                  _accent.withValues(alpha: 0.18),
                  const Color(0xFF0A0D14),
                ],
              ),
            ),
          ),

          // Bottom glow
          Positioned(
            bottom: -60,
            left: size.width * 0.1,
            right: size.width * 0.1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.15),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Page content — swipeable ──────────────────────
          PageView(
            controller: _pageCtrl,
            // Allow swipe
            physics: const ClampingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _Slide0(
                accent: _colors[0],
                page: _page,
                selectedLanguage: _selectedLanguage,
                onLanguageChanged: (lang) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedLanguage = lang);
                },
              ),
              _Slide1(accent: _colors[1], page: _page, lang: _selectedLanguage),
              _Slide2(accent: _colors[2], page: _page, lang: _selectedLanguage),
              _Slide3(
                accent: _colors[3],
                page: _page,
                lang: _selectedLanguage,
                selectedCurrency: _selectedCurrency,
                onCurrencyChanged: (c) =>
                    setState(() => _selectedCurrency = c),
              ),
              _Slide4(
                accent: _colors[4],
                page: _page,
                lang: _selectedLanguage,
                selectedCurrency: _selectedCurrency,
              ),
            ],
          ),

          // ── Bottom bar ────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomBar(
              current:  _currentPage,
              total:    _total,
              accent:   _accent,
              isLast:   _currentPage == _total - 1,
              lang:     _selectedLanguage,
              onNext:   _next,
              onSkip:   _skip,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SLIDE 0 — Welcome / Brand
// ═════════════════════════════════════════════════════════════════════════════
class _Slide0 extends StatefulWidget {
  final Color accent;
  final double page;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;
  const _Slide0({
    required this.accent,
    required this.page,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });
  @override State<_Slide0> createState() => _Slide0State();
}

class _Slide0State extends State<_Slide0> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // ── App logo — amber circle + wallet icon (not emoji) ──
          ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _fade,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        widget.accent.withValues(alpha: 0.25),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  // Main circle
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.accent,
                          widget.accent.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.4),
                          blurRadius: 30, spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Iconsax.wallet_2,
                        color: Colors.black, size: 52),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          FadeTransition(
            opacity: _fade,
            child: Column(children: [

              // ── Language selector ──────────────────────────
              _LangSelector(
                selected: widget.selectedLanguage,
                onChanged: widget.onLanguageChanged,
                accent: widget.accent,
              ),
              const SizedBox(height: 28),

              Text("Cho'ntak",
                  style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: widget.accent,
                      letterSpacing: -2,
                      height: 1)),
              const SizedBox(height: 10),
              Text(_slideSubtitle(widget.selectedLanguage),
                  style: TextStyle(
                      fontSize: 17,
                      color: Colors.white.withValues(alpha: 0.55),
                      letterSpacing: 0.3)),
              const SizedBox(height: 32),

              // Feature pills — translated
              Wrap(
                spacing: 8, runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _slidePills(widget.selectedLanguage, widget.accent),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Language-aware helpers for slide 0 ───────────────────────────────────────
String _slideSubtitle(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.uz: return 'Shaxsiy moliya hamkori';
    case AppLanguage.ru: return 'Личный финансовый помощник';
    case AppLanguage.en: return 'Your personal finance companion';
  }
}

List<Widget> _slidePills(AppLanguage lang, Color accent) {
  final labels = {
    AppLanguage.uz: ['📊  Tranzaksiyalar', '🎯  Byudjet', "💰  Jamg'arma", '🌐  3 til', '💱  3 valyuta'],
    AppLanguage.ru: ['📊  Транзакции',    '🎯  Бюджет',  '💰  Копилка',   '🌐  3 языка','💱  3 валюты'],
    AppLanguage.en: ['📊  Transactions',  '🎯  Budget',  '💰  Savings',   '🌐  3 langs', '💱  3 currencies'],
  };
  return (labels[lang] ?? labels[AppLanguage.uz]!)
      .map((t) => _Pill(t, accent))
      .toList();
}

// ── Language selector widget ──────────────────────────────────────────────────
class _LangSelector extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;
  final Color accent;
  const _LangSelector({
    required this.selected,
    required this.onChanged,
    required this.accent,
  });

  static const _langs = [
    (AppLanguage.uz, "O'zbek", '🇺🇿'),
    (AppLanguage.ru, 'Русский', '🇷🇺'),
    (AppLanguage.en, 'English', '🇬🇧'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _langs.map((lang) {
          final isSelected = selected == lang.$1;
          return GestureDetector(
            onTap: () => onChanged(lang.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang.$3, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                    child: Text(lang.$2),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color accent;
  const _Pill(this.text, this.accent);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: accent.withValues(alpha: 0.3)),
    ),
    child: Text(text,
        style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500)),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// SLIDE 1 — Track income & expenses
// ═════════════════════════════════════════════════════════════════════════════
class _Slide1 extends StatelessWidget {
  final Color accent;
  final double page;
  final AppLanguage lang;
  const _Slide1({required this.accent, required this.page, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideLabel({'uz':'KUZATUV','ru':'ОТСЛЕЖИВАНИЕ','en':'TRACKING'}[lang.name]!, accent),
          const SizedBox(height: 10),
          _SlideTitle({'uz':'Pul kirim va\nchiqimini qayd qiling','ru':'Записывайте\nдоходы и расходы','en':'Track your income\nand expenses'}[lang.name]!, accent),
          const SizedBox(height: 32),

          // Mock transaction list
          _MockPhone(accent: accent, child: _MockTransactionList(accent: accent, lang: lang)),
          const SizedBox(height: 28),

          _FeatureRow(Iconsax.add_circle, accent,
              {'uz':"Tez qo'shish",'ru':'Быстрое добавление','en':'Quick add'}[lang.name]!,
              {'uz':"Bir necha soniyada daromad yoki xarajat qo'shing",'ru':'Добавьте доход или расход за секунды','en':'Add income or expense in seconds'}[lang.name]!),
          const SizedBox(height: 12),
          _FeatureRow(Iconsax.category, accent,
              {'uz':'Kategoriyalar','ru':'Категории','en':'Categories'}[lang.name]!,
              {'uz':"Har bir xarajatni turkumlang — ovqat, transport, dam olish",'ru':'Разбивайте расходы по категориям','en':'Sort expenses by category — food, transport, fun'}[lang.name]!),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SLIDE 2 — Budget & Stats
// ═════════════════════════════════════════════════════════════════════════════
class _Slide2 extends StatelessWidget {
  final Color accent;
  final double page;
  final AppLanguage lang;
  const _Slide2({required this.accent, required this.page, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideLabel({'uz':'BYUDJET & STATISTIKA','ru':'БЮДЖЕТ & СТАТИСТИКА','en':'BUDGET & STATS'}[lang.name]!, accent),
          const SizedBox(height: 10),
          _SlideTitle({'uz':'Sarfingizni\nnazorat qiling','ru':'Контролируйте\nрасходы','en':'Control your\nspending'}[lang.name]!, accent),
          const SizedBox(height: 32),

          // Mock budget + pie chart
          _MockPhone(accent: accent, child: _MockStatsView(accent: accent, lang: lang)),
          const SizedBox(height: 28),

          _FeatureRow(Iconsax.chart_2, accent,
              {'uz':"Ayliq statistika",'ru':'Месячная статистика','en':'Monthly stats'}[lang.name]!,
              {'uz':"Qaysi kategoriyaga ko'p sarflayotganingizni bilib oling",'ru':'Узнайте, на что тратите больше всего','en':'See where your money goes each month'}[lang.name]!),
          const SizedBox(height: 12),
          _FeatureRow(Iconsax.wallet, accent,
              {'uz':'Byudjet limiti','ru':'Лимит бюджета','en':'Budget limit'}[lang.name]!,
              {'uz':"Limit qo'ying va oshib ketsa ogohlantirish oling",'ru':'Установите лимит и получайте уведомления','en':'Set a limit and get notified when near'}[lang.name]!),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SLIDE 3 — Savings goals + currency picker
// ═════════════════════════════════════════════════════════════════════════════
class _Slide3 extends StatefulWidget {
  final Color accent;
  final double page;
  final AppLanguage lang;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  const _Slide3({
    required this.accent, required this.page, required this.lang,
    required this.selectedCurrency, required this.onCurrencyChanged,
  });
  @override State<_Slide3> createState() => _Slide3State();
}

class _Slide3State extends State<_Slide3> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideLabel({'uz':'MAQSAD & VALYUTA','ru':'ЦЕЛИ & ВАЛЮТА','en':'GOALS & CURRENCY'}[widget.lang.name]!, widget.accent),
          const SizedBox(height: 10),
          _SlideTitle({'uz':"Maqsad qo'ying,\nvaqtida yeting",'ru':'Ставьте цели,\nдостигайте их','en':'Set goals,\nachieve them'}[widget.lang.name]!, widget.accent),
          const SizedBox(height: 24),

          // Mock savings goals
          _MockSavingsGoal(accent: widget.accent, label: {'uz':'Yangi telefon','ru':'Новый телефон','en':'New phone'}[widget.lang.name]!,
              saved: 0.65, emoji: '📱'),
          const SizedBox(height: 10),
          _MockSavingsGoal(accent: widget.accent, label: {'uz':"Ta'til",'ru':'Отпуск','en':'Vacation'}[widget.lang.name]!,
              saved: 0.38, emoji: '✈️'),
          const SizedBox(height: 28),

          // Currency picker
          Text({'uz':"Valyutangizni tanlang",'ru':'Выберите валюту','en':'Choose your currency'}[widget.lang.name]!,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 12),
          Row(
            children: AppConstants.currencies.map((cur) {
              final selected = widget.selectedCurrency == cur['code'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onCurrencyChanged(cur['code']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? widget.accent.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? widget.accent
                            : Colors.white.withValues(alpha: 0.1),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Text(cur['symbol']!,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? widget.accent
                                  : Colors.white.withValues(alpha: 0.4))),
                      const SizedBox(height: 4),
                      Text(cur['code']!,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35))),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text({'uz':"Sozlamalardan istalgan vaqt o'zgartirish mumkin",'ru':'Можно изменить в настройках позже','en':'You can change this anytime in settings'}[widget.lang.name]!,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.35))),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SLIDE 4 — Ready / Security features
// ═════════════════════════════════════════════════════════════════════════════
class _Slide4 extends StatefulWidget {
  final Color accent;
  final double page;
  final AppLanguage lang;
  final String selectedCurrency;
  const _Slide4({required this.accent, required this.page,
    required this.lang, required this.selectedCurrency});
  @override State<_Slide4> createState() => _Slide4State();
}

class _Slide4State extends State<_Slide4>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    // Animate each time this slide becomes visible
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _ctrl.forward(from: 0);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final symbol = AppConstants.currencies.firstWhere(
          (c) => c['code'] == widget.selectedCurrency,
      orElse: () => AppConstants.currencies.first,
    )['symbol'] ?? "so'm";

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Big animated check
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.accent, widget.accent.withValues(alpha: 0.6)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: widget.accent.withValues(alpha: 0.45),
                      blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.black, size: 56),
            ),
          ),
          const SizedBox(height: 28),

          Text({'uz':"Hammasi tayyor!",'ru':'Всё готово!','en':'All set!'}[widget.lang.name]!,
              style: const TextStyle(
                  fontSize: 38, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: -1)),
          const SizedBox(height: 8),
          Text('$symbol · ${widget.selectedCurrency}',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: widget.accent, letterSpacing: 1)),
          const SizedBox(height: 32),

          // Feature summary grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _ReadyCard('🔐', {'uz':'PIN qulf','ru':'PIN-блок','en':'PIN lock'}[widget.lang.name]!, widget.accent),
              _ReadyCard('🔔', {'uz':'Eslatmalar','ru':'Уведомления','en':'Reminders'}[widget.lang.name]!, widget.accent),
              _ReadyCard('🌙', {'uz':"Qorong'u rejim",'ru':'Тёмный режим','en':'Dark mode'}[widget.lang.name]!, widget.accent),
              _ReadyCard('📱', {'uz':'Ekran vidjet','ru':'Виджет','en':'Home widget'}[widget.lang.name]!, widget.accent),
              _ReadyCard('🌐', 'UZ · RU · EN', widget.accent),
              _ReadyCard('📶', {'uz':'Oflayn ishlaydi','ru':'Офлайн','en':'Works offline'}[widget.lang.name]!, widget.accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  final String emoji, label;
  final Color accent;
  const _ReadyCard(this.emoji, this.label, this.accent);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white),
            overflow: TextOverflow.ellipsis),
      ),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════

class _SlideLabel extends StatelessWidget {
  final String text;
  final Color accent;
  const _SlideLabel(this.text, this.accent);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
          letterSpacing: 2.5));
}

class _SlideTitle extends StatelessWidget {
  final String text;
  final Color accent;
  const _SlideTitle(this.text, this.accent);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.15,
          letterSpacing: -0.5));
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title, subtitle;
  const _FeatureRow(this.icon, this.accent, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.35)),
        ]),
      ),
    ],
  );
}

// ── Mock phone frame ──────────────────────────────────────────────────────────
class _MockPhone extends StatelessWidget {
  final Color accent;
  final Widget child;
  const _MockPhone({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF161B26),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: child,
    ),
  );
}

// ── Mock transaction list ─────────────────────────────────────────────────────
class _MockTransactionList extends StatelessWidget {
  final Color accent;
  final AppLanguage lang;
  const _MockTransactionList({required this.accent, required this.lang});

  @override
  Widget build(BuildContext context) {
    final items = [
      (accent, '🍕', {'uz':'Tushlik','ru':'Обед','en':'Lunch'}[lang.name]!, '-45,000', false),
      (const Color(0xFF22C55E), '💰', {'uz':'Maosh','ru':'Зарплата','en':'Salary'}[lang.name]!, '+3,200,000', true),
      (const Color(0xFF60A5FA), '🚌', {'uz':'Metro','ru':'Метро','en':'Metro'}[lang.name]!, '-1,800', false),
      (const Color(0xFFA78BFA), '🎮', {'uz':"O'yin",'ru':'Игра','en':'Game'}[lang.name]!, '-89,000', false),
    ];
    return Column(
      children: [
        // Header strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: accent.withValues(alpha: 0.12),
          child: Row(children: [
            Icon(Iconsax.wallet_2, color: accent, size: 14),
            const SizedBox(width: 6),
            Text({'uz':"so'm 1,240,000",'ru':'сум 1 240 000','en':'\$1,240'}[lang.name]!,
                style: TextStyle(color: accent,
                    fontWeight: FontWeight.w800, fontSize: 13)),
            const Spacer(),
            Text('Mar 2026',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10)),
          ]),
        ),
        ...items.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: item.$1.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(child: Text(item.$2,
                  style: const TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(item.$3,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600, fontSize: 12))),
            Text(item.$4,
                style: TextStyle(
                    color: item.$5
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF87171),
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        )),
      ],
    );
  }
}

// ── Mock stats view ───────────────────────────────────────────────────────────
class _MockStatsView extends StatelessWidget {
  final Color accent;
  final AppLanguage lang;
  const _MockStatsView({required this.accent, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Bar chart area
      Container(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text({'uz':"Kategoriyalar bo'yicha",'ru':'По категориям','en':'By category'}[lang.name]!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10)),
          const SizedBox(height: 10),
          // Fake horizontal bars
          _MockBar({'uz':'🍕 Oziq-ovqat','ru':'🍕 Еда','en':'🍕 Food'}[lang.name]!, 0.72, const Color(0xFFF0B429)),
          const SizedBox(height: 6),
          _MockBar({'uz':'🚌 Transport','ru':'🚌 Транспорт','en':'🚌 Transport'}[lang.name]!, 0.45, const Color(0xFF60A5FA)),
          const SizedBox(height: 6),
          _MockBar({'uz':'🎮 Hobby','ru':'🎮 Хобби','en':'🎮 Hobby'}[lang.name]!, 0.30, const Color(0xFFA78BFA)),
          const SizedBox(height: 6),
          _MockBar({'uz':'💊 Salomatlik','ru':'💊 Здоровье','en':'💊 Health'}[lang.name]!, 0.18, const Color(0xFF22C55E)),
          const SizedBox(height: 10),
          // Budget bar
          Row(children: [
            Icon(Iconsax.chart, color: accent, size: 12),
            const SizedBox(width: 6),
            Text({'uz':'Byudjet: 64% ishlatildi','ru':'Бюджет: 64% использовано','en':'Budget: 64% used'}[lang.name]!,
                style: TextStyle(color: accent, fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.64,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _MockBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MockBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 90,
        child: Text(label, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6), fontSize: 9),
            overflow: TextOverflow.ellipsis)),
    const SizedBox(width: 8),
    Expanded(child: ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value, minHeight: 6,
        backgroundColor: Colors.white.withValues(alpha: 0.07),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    )),
  ]);
}

// ── Mock savings goal ─────────────────────────────────────────────────────────
class _MockSavingsGoal extends StatelessWidget {
  final Color accent;
  final String label, emoji;
  final double saved; // 0.0–1.0
  const _MockSavingsGoal({
    required this.accent, required this.label,
    required this.emoji, required this.saved,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accent.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 28)),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: saved, minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(saved * 100).toInt()}% yig\'ildi',
              style: TextStyle(color: accent, fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      )),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// BOTTOM BAR
// ═════════════════════════════════════════════════════════════════════════════
class _BottomBar extends StatelessWidget {
  final int current, total;
  final Color accent;
  final bool isLast;
  final AppLanguage lang;
  final VoidCallback onNext, onSkip;
  const _BottomBar({
    required this.current, required this.total, required this.accent,
    required this.isLast, required this.lang,
    required this.onNext, required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24,
          MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent,
            const Color(0xFF0A0D14).withValues(alpha: 0.97),
            const Color(0xFF0A0D14)],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: Row(
        children: [
          // Dot indicators
          Row(
            children: List.generate(total, (i) {
              final active = i == current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? accent
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),

          // Skip
          if (!isLast)
            GestureDetector(
              onTap: onSkip,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Text({'uz':"O'tkazish",'ru':'Пропустить','en':'Skip'}[lang.name]!,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ),

          const SizedBox(width: 8),

          // Next / Start button
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                  horizontal: isLast ? 32 : 22, vertical: 14),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 18, offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  isLast
                      ? {'uz':'Boshlash!','ru':'Начать!','en':'Get started!'}[lang.name]!
                      : {'uz':'Keyingisi','ru':'Далее','en':'Next'}[lang.name]!,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
                if (!isLast) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.black, size: 16),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}