import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import '../../core/services/app_lock_service.dart';
import '../../core/theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final bool isSetup; // true = setting up new PIN

  const LockScreen({
    super.key,
    required this.onUnlocked,
    this.isSetup = false,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  String _pin         = '';
  String _confirmPin  = '';
  bool   _confirming  = false; // setup step 2
  String _error       = '';
  bool   _biometricAvailable = false;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;
  late AnimationController _fadeCtrl;

  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600))
      ..forward();

    _checkBiometric();

    // Auto-trigger biometric on open if not setup mode
    if (!widget.isSetup) {
      Future.delayed(
          const Duration(milliseconds: 400), _tryBiometric);
    }
  }

  Future<void> _checkBiometric() async {
    final avail =
    await AppLockService.instance.isBiometricAvailable;
    final useBio = await AppLockService.instance.useBiometric;
    if (mounted) setState(() => _biometricAvailable = avail && useBio);
  }

  Future<void> _tryBiometric() async {
    if (!_biometricAvailable) return;
    final ok = await AppLockService.instance.authenticateBiometric();
    if (ok && mounted) widget.onUnlocked();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      _error = '';
      if (widget.isSetup) {
        if (!_confirming) {
          if (_pin.length < _pinLength) _pin += digit;
          if (_pin.length == _pinLength) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() => _confirming = true);
            });
          }
        } else {
          if (_confirmPin.length < _pinLength) _confirmPin += digit;
          if (_confirmPin.length == _pinLength) _verifySetup();
        }
      } else {
        if (_pin.length < _pinLength) _pin += digit;
        if (_pin.length == _pinLength) _verifyPin();
      }
    });
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      _error = '';
      if (widget.isSetup && _confirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyPin() async {
    final saved = await AppLockService.instance.savedPin;
    if (_pin == saved) {
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _error = 'Noto\'g\'ri PIN. Qayta urinib ko\'ring.';
        _pin   = '';
      });
    }
  }

  Future<void> _verifySetup() async {
    if (_pin == _confirmPin) {
      await AppLockService.instance.setPin(_pin);
      await AppLockService.instance.setEnabled(true);
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _error      = 'PIN mos kelmadi. Qayta kiriting.';
        _pin        = '';
        _confirmPin = '';
        _confirming = false;
      });
    }
  }

  String get _currentPin =>
      widget.isSetup && _confirming ? _confirmPin : _pin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // ── Logo + title ──────────────────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.gold.withValues(alpha: 0.28),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  Container(
                    width: 84, height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gold,
                          AppColors.gold.withValues(alpha: 0.75),
                        ],
                      ),
                      boxShadow: [BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        blurRadius: 24, spreadRadius: 4,
                      )],
                    ),
                    child: const Icon(Iconsax.wallet_2,
                        color: Colors.black, size: 38),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.isSetup
                    ? (_confirming
                    ? 'PIN ni tasdiqlang'
                    : 'Yangi PIN kiriting')
                    : "Cho'ntak",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isSetup
                    ? (_confirming
                    ? 'Xavfsizlik uchun PIN ni qayta kiriting'
                    : '4 ta raqamli PIN o\'rnating')
                    : 'Kirish uchun PIN kiriting',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.45)),
              ),
              const SizedBox(height: 48),

              // ── PIN dots ──────────────────────────────────
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(
                      _shakeCtrl.isAnimating
                          ? 12 * (0.5 - _shakeAnim.value).abs() * 8
                          : 0,
                      0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (i) {
                    final filled = i < _currentPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? AppColors.gold
                            : Colors.transparent,
                        border: Border.all(
                          color: filled
                              ? AppColors.gold
                              : Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: filled
                            ? [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                            : [],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // ── Error message ─────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _error.isNotEmpty
                    ? Text(
                  _error,
                  key: ValueKey(_error),
                  style: const TextStyle(
                      color: AppColors.expense, fontSize: 13),
                )
                    : const SizedBox(height: 18),
              ),

              const Spacer(),

              // ── Numpad ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    for (final row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                    ])
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row
                            .map((d) => _NumKey(digit: d, onTap: _onKey))
                            .toList(),
                      ),
                    // Bottom row: biometric | 0 | delete
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Biometric or empty
                        _NumKey(
                          icon: _biometricAvailable && !widget.isSetup
                              ? Icons.fingerprint
                              : null,
                          onTap: _biometricAvailable && !widget.isSetup
                              ? (_) => _tryBiometric()
                              : null,
                        ),
                        _NumKey(digit: '0', onTap: _onKey),
                        _NumKey(
                          icon: Icons.backspace_outlined,
                          onTap: (_) => _onDelete(),
                          iconColor: Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Number key ────────────────────────────────────────────────────────────────
class _NumKey extends StatefulWidget {
  final String? digit;
  final IconData? icon;
  final Color? iconColor;
  final Function(String)? onTap;

  const _NumKey({this.digit, this.icon, this.onTap, this.iconColor});

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.digit != null || widget.icon != null;
    if (!hasContent) return const SizedBox(width: 80, height: 80);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call(widget.digit ?? '');
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: widget.digit != null
                ? Text(
              widget.digit!,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )
                : Icon(widget.icon,
                color: widget.iconColor ?? Colors.white.withValues(alpha: 0.7),
                size: 28),
          ),
        ),
      ),
    );
  }
}