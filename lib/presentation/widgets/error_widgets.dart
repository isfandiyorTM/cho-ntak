import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_theme.dart';

// ── Full page error ───────────────────────────────────────────────────────────
class ErrorScreen extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorScreen({
    super.key,
    this.title = 'Xatolik yuz berdi',
    this.message = 'Nimadir noto\'g\'ri ketdi. Qayta urinib ko\'ring.',
    this.onRetry,
    this.icon = Iconsax.warning_2,
  });

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon container
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.7, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.expense.withOpacity(0.1),
                      border: Border.all(
                          color: AppColors.expense.withOpacity(0.3),
                          width: 2),
                    ),
                    child: Icon(widget.icon,
                        color: AppColors.expense, size: 44),
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: widget.onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.goldLight, AppColors.gold],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.refresh, color: Colors.black, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Qayta urinish',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class EmptyState extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Iconsax.document,
    this.iconColor,
    this.action,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? Colors.grey[600]!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(
                        color: color.withOpacity(0.2), width: 1.5),
                  ),
                  child: Icon(widget.icon, color: color, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                ),
                if (widget.action != null) ...[
                  const SizedBox(height: 24),
                  widget.action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Inline error banner (for inside cards/sections) ───────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.expense.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: AppColors.expense.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2,
              color: AppColors.expense, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.expense)),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.expense.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.expense,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Loading shimmer card ──────────────────────────────────────────────────────
class ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius = 16,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1 + _anim.value * 2, 0),
            end: Alignment(1 + _anim.value * 2, 0),
            colors: isDark
                ? [
              AppColors.cardDark,
              AppColors.borderDark,
              AppColors.cardDark,
            ]
                : [
              AppColors.cardLight,
              Colors.white,
              AppColors.cardLight,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading skeleton for home page ────────────────────────────────────────────
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: ShimmerCard(height: 90)),
            const SizedBox(width: 12),
            Expanded(child: ShimmerCard(height: 90)),
          ]),
          const SizedBox(height: 12),
          ShimmerCard(height: 90),
          const SizedBox(height: 12),
          ShimmerCard(height: 100),
          const SizedBox(height: 28),
          ShimmerCard(height: 20, width: 120, borderRadius: 8),
          const SizedBox(height: 14),
          for (int i = 0; i < 4; i++) ...[
            ShimmerCard(height: 70),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}