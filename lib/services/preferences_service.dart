import 'package:shared_preferences/shared_preferences.dart';

/* service pour gérer les préférences utilisateur */


class PreferencesService {
  // instance de SharedPreferences


  static SharedPreferences? _prefs;

  PreferencesService._init();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setThemeMode(bool isDark) async {
    await _prefs?.setBool('isDarkMode', isDark);
  }

  static bool getThemeMode() {
    return _prefs?.getBool('isDarkMode') ?? false;
  }

  static Future<void> setVillemiseenavant(int? villeId) async {
    if (villeId != null) {
      await _prefs?.setInt('villeFavoriteId', villeId);
    } else {
      await _prefs?.remove('villeFavoriteId');
    }
  }

  static int? getVilleMiseenavantId() {
    return _prefs?.getInt('villeFavoriteId');
  }

  static Future<void> ajouterRechercheRecente(String ville) async {
    final recherches = getRecherchesRecentes();
    
    // Retirer si déjà présent pour éviter les doublons
    recherches.remove(ville);
    
    // Ajouter en premier
    recherches.insert(0, ville);
    
    // Limiter à 10
    if (recherches.length > 10) {
      recherches.removeRange(10, recherches.length);
    }
    
    await setRecherchesRecentes(recherches);
  }


    // getter 
  static List<String> getRecherchesRecentes() {
    return _prefs?.getStringList('recherchesRecentes') ?? [];
  }

  // setter 
  static Future<void> setRecherchesRecentes(List<String> recherches) async {
    await _prefs?.setStringList('recherchesRecentes', recherches);
  }


  // vider les recherches récentes
  static Future<void> clearRecherchesRecentes() async {
    await _prefs?.remove('recherchesRecentes');
  }


  // clear all preferences
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }


  
}