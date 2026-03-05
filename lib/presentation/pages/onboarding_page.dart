import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'main_shell.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  String _selectedCurrency = 'UZS';

  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _totalPages = 4;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _fadeCtrl.reset();
    _slideCtrl.reset();
    _pageCtrl.animateToPage(page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut);
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeCtrl.forward();
      _slideCtrl.forward();
    });
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _animateToPage(_currentPage + 1);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setString(AppConstants.currencyKey, _selectedCurrency);

    if (!mounted) return;

    final symbol = AppConstants.currencies.firstWhere(
          (c) => c['code'] == _selectedCurrency,
      orElse: () => AppConstants.currencies.first,
    )['symbol'] ??
        "so'm";

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MainShell(
          isDark: true,
          currency: _selectedCurrency,
          currencySymbol: symbol,
          onThemeChanged: (_) {},
          onCurrencyChanged: (_) {},
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Decorative background blobs ──────────────────
          _BackgroundBlobs(page: _currentPage),

          // ── Page content ─────────────────────────────────
          PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _buildPage0(),
              _buildPage1(),
              _buildPage2(),
              _buildPage3(),
            ],
          ),

          // ── Bottom controls ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onNext: _next,
              onSkip: _skip,
              isLast: _currentPage == _totalPages - 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 0: Welcome ───────────────────────────────────────
  Widget _buildPage0() {
    return _PageWrapper(
      fadeAnim: _fadeAnim,
      slideAnim: _slideAnim,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big wallet icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withOpacity(0.3),
                  AppColors.gold.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                  color: AppColors.gold.withOpacity(0.4), width: 1.5),
            ),
            child: const Center(
              child: Text('💵', style: TextStyle(fontSize: 72)),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Cho'ntak",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Cho'ntagingizga qarab\nish qiling",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.gold.withOpacity(0.3), width: 1),
              borderRadius: BorderRadius.circular(30),
              color: AppColors.gold.withOpacity(0.08),
            ),
            child: Text(
              "Shaxsiy moliyangizni nazorat qiling",
              style: TextStyle(
                  fontSize: 13, color: AppColors.gold.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 1: Features ─────────────────────────────────────
  Widget _buildPage1() {
    final features = [
      ('📊', 'Tranzaksiyalar', "Daromad va xarajatlarni\nqayd qiling"),
      ('🎯', 'Byudjet', "Oylik limit belgilang\nva nazorat qiling"),
      ('📈', 'Statistika', "Moliyangizni\ntahlil qiling"),
    ];

    return _PageWrapper(
      fadeAnim: _fadeAnim,
      slideAnim: _slideAnim,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nima qiladi?",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gold.withOpacity(0.7),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Hamma narsa\nbir joyda",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ...features.asMap().entries.map((e) {
            final delay = e.key * 0.15;
            return AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, child) => Opacity(
                opacity: (_fadeAnim.value - delay).clamp(0.0, 1.0),
                child: child,
              ),
              child: _FeatureCard(
                  emoji: e.value.$1,
                  title: e.value.$2,
                  subtitle: e.value.$3),
            );
          }),
        ],
      ),
    );
  }

  // ── Page 2: Currency picker ───────────────────────────────
  Widget _buildPage2() {
    final topCurrencies = AppConstants.currencies.take(6).toList();

    return _PageWrapper(
      fadeAnim: _fadeAnim,
      slideAnim: _slideAnim,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SOZLASH",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gold.withOpacity(0.7),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Valyutangizni\ntanlang",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Keyinchalik sozlamalardan\no'zgartirish mumkin",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.4),
                      height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: topCurrencies.map((cur) {
              final selected = _selectedCurrency == cur['code'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCurrency = cur['code']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.gold.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.gold
                          : Colors.white.withOpacity(0.1),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cur['symbol']!,
                        style: TextStyle(
                          fontSize: 18,
                          color: selected
                              ? AppColors.gold
                              : Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cur['code']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            cur['name']!.split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? AppColors.gold.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle,
                            color: AppColors.gold, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Page 3: Ready ─────────────────────────────────────────
  Widget _buildPage3() {
    final symbol = AppConstants.currencies.firstWhere(
          (c) => c['code'] == _selectedCurrency,
      orElse: () => AppConstants.currencies.first,
    )['symbol'] ??
        "so'm";

    return _PageWrapper(
      fadeAnim: _fadeAnim,
      slideAnim: _slideAnim,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated checkmark
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.25),
                    AppColors.gold.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.gold, size: 60),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Tayyor!",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Tanlangan valyuta: ",
            style: TextStyle(
                fontSize: 15, color: Colors.white.withOpacity(0.4)),
          ),
          const SizedBox(height: 4),
          Text(
            "$symbol  $_selectedCurrency",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                _ReadyTip(
                    icon: '➕',
                    text: "Birinchi tranzaksiyangizni qo'shing"),
                const SizedBox(height: 12),
                _ReadyTip(
                    icon: '🎯',
                    text: "Oylik byudjet belgilang"),
                const SizedBox(height: 12),
                _ReadyTip(
                    icon: '🔔',
                    text:
                    "Bildirishnomalar har safar qulfni ochganizda ishlaydi"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated page wrapper ─────────────────────────────────────────────────────
class _PageWrapper extends StatelessWidget {
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final Widget child;

  const _PageWrapper({
    required this.fadeAnim,
    required this.slideAnim,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 80, 28, 140),
          child: child,
        ),
      ),
    );
  }
}

// ── Background decorative blobs ───────────────────────────────────────────────
class _BackgroundBlobs extends StatelessWidget {
  final int page;
  const _BackgroundBlobs({required this.page});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.gold,
      AppColors.income,
      AppColors.expense,
      AppColors.gold,
    ];
    final color = colors[page % colors.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature card ──────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final String emoji, title, subtitle;
  const _FeatureCard(
      {required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.4),
                      height: 1.3)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ready tip row ─────────────────────────────────────────────────────────────
class _ReadyTip extends StatelessWidget {
  final String icon, text;
  const _ReadyTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.55),
                  height: 1.3)),
        ),
      ],
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int currentPage, totalPages;
  final VoidCallback onNext, onSkip;
  final bool isLast;

  const _BottomBar({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.bgDark.withOpacity(0.95),
            AppColors.bgDark,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.gold
                      : AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              if (!isLast)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    "O'tkazib yuborish",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 14),
                  ),
                )
              else
                const Spacer(),
              const Spacer(),
              GestureDetector(
                onTap: onNext,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(
                    horizontal: isLast ? 40 : 28,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.goldLight, AppColors.gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? "Boshlash!" : "Keyingisi",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.black, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}