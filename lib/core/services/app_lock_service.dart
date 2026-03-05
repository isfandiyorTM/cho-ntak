import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  final _auth = LocalAuthentication();

  static const _kEnabled   = 'lock_enabled';
  static const _kUseBio    = 'lock_use_biometric';
  static const _kPin       = 'lock_pin';

  // ── Getters ───────────────────────────────────────────────
  Future<bool> get isEnabled async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kEnabled) ?? false;
  }

  Future<bool> get useBiometric async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kUseBio) ?? false;
  }

  Future<String?> get savedPin async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kPin);
  }

  Future<bool> get isBiometricAvailable async {
    try {
      final available = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return available && supported;
    } catch (_) { return false; }
  }

  // ── Save settings ─────────────────────────────────────────
  Future<void> setEnabled(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, val);
  }

  Future<void> setUseBiometric(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kUseBio, val);
  }

  Future<void> setPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPin, pin);
  }

  Future<void> disableAll() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, false);
    await p.remove(_kPin);
  }

  // ── Authenticate with biometrics ──────────────────────────
  Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: "Cho'ntak ilovasiga kirish uchun",
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) { return false; }
  }
}