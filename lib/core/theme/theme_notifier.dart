import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'app_theme.dart';

/// Single source of truth for dark/light mode.
/// Lives at the top of the widget tree via ChangeNotifierProvider.
class ThemeNotifier extends ChangeNotifier {
  bool _isDark;
  ThemeNotifier(this._isDark);

  bool get isDark => _isDark;

  void setDark(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    AppTheme.applySystemUI(value);
    SharedPreferences.getInstance()
        .then((p) => p.setBool(AppConstants.themeKey, value));
  }
}