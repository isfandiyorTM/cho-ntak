import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _key = 'app_language';

  AppLanguage _language = AppLanguage.uz;
  AppLanguage get language => _language;
  Translations get t => Translations(_language);

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _language = AppLanguage.values.firstWhere(
            (l) => l.name == saved,
        orElse: () => AppLanguage.uz,
      );
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang.name);
  }
}