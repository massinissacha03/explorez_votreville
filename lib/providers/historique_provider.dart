import 'package:flutter/material.dart';
import '../services/preferences_service.dart';


/* gestion de l'historique des recherches */
class HistoriqueProvider extends ChangeNotifier {
  List<String> _recherchesRecentes = []; // liste des recherches récentes

  List<String> get recherchesRecentes => _recherchesRecentes;

  // constructeur qui charge l'historique au démarrage
  HistoriqueProvider() {
    _chargerHistorique();
  }

  // charger l'historique depuis les preferences
  Future<void> _chargerHistorique() async {
    _recherchesRecentes = await PreferencesService.getRecherchesRecentes();
    notifyListeners();
  }

  // ajouter une recherche à l'historique
  Future<void> ajouterRecherche(String nomVille) async {
    await PreferencesService.ajouterRechercheRecente(nomVille);
    _recherchesRecentes = await PreferencesService.getRecherchesRecentes();
    notifyListeners();
  }

  // vider l'historique
  Future<void> viderHistorique() async {
    await PreferencesService.clearRecherchesRecentes();
    _recherchesRecentes = [];
    notifyListeners();
  }
}
