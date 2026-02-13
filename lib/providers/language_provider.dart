import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = false;
  static const String _langKey = 'language_code';

  bool get isEnglish => _isEnglish;
  Locale get currentLocale => isEnglish ? const Locale('en') : const Locale('tr');

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool(_langKey) ?? false; // Default to TR (false)
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _isEnglish = !_isEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_langKey, _isEnglish);
    notifyListeners();
  }

  Future<void> setLanguage(bool isEnglish) async {
    _isEnglish = isEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_langKey, _isEnglish);
    notifyListeners();
  }
}
