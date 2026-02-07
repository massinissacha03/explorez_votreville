// sert à gerer le theme (clair / sombre)
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/* gestion du thème (clair / sombre) */

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    loadTheme();
  }

  // charge le theme depuis les preferences
  Future<void> loadTheme() async {
    _isDarkMode = await PreferencesService.getThemeMode();
    notifyListeners();
  }

  // toggle le theme et le sauvegarde dans les preferences
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await PreferencesService.setThemeMode(_isDarkMode);
    notifyListeners();
  }

  // le theme actuel
  ThemeData get currentTheme {
    return _isDarkMode ? ThemeData.dark() : ThemeData.light();
  }
}
