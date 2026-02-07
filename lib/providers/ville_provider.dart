import 'package:flutter/material.dart';
import '../models/ville.dart';
import '../db/database_helper.dart';
import '../db/ville_db_helper.dart';
import '../services/api_ville.dart';
import '../services/meteo_api.dart';
import '../services/preferences_service.dart';
import '../models/meteo.dart';

import 'dart:async';

/* gestion des villes */

class VilleProvider extends ChangeNotifier {
  final ApiVille _apiVille = ApiVille(); // service API pour les villes
  final MeteoApi _meteoApi = MeteoApi(); // service API pour la météo

  List<Ville> _villes = []; // liste des villes en mémoire
  Ville? _villeActuelle; // ville actuellement sélectionnée
  Meteo? _meteoActuelle;
  int? _villeMiseEnAvantId; // id de la ville mise en avant
  bool _isInitialized =
      false; // pour savoir si l'initialisation est faite ou non

  DateTime _heureActuelle = DateTime.now();
  Timer? _heureTimer; // timer pour mettre a jour l'heure actuelle de la ville chaque minute

  List<Ville> get villes => _villes;
  Ville? get villeActuelle => _villeActuelle;
  Meteo? get meteoActuelle => _meteoActuelle;
  int? get villeMiseEnAvantId => _villeMiseEnAvantId;
  bool get isInitialized => _isInitialized;
  DateTime get heureActuelle => _heureActuelle;

  // constructeur , initialise les villes et l'heure
  VilleProvider() {
    _init();
    _startHeureTimer();
  }

  // start le timer pour mettre à jour l'heure actuelle chaque 30 secondes
  void _startHeureTimer() {
    _heureTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _heureActuelle = DateTime.now();
      notifyListeners();
    });
  }


  // on arrête le Timer  pour qu’il continue pas après la destruction du provider
  @override
  void dispose() {
    _heureTimer?.cancel();
    super.dispose();
  }

  // initialisation : chargeer les villes et la meteo et la ville mise en avant et passe isInitialized à true
  Future<void> _init() async {
    await loadVilles();
    _villeMiseEnAvantId = await PreferencesService.getVilleMiseenavantId();

    if (_villeMiseEnAvantId != null) {
      final ville = await VilleDbHelper.getById(_villeMiseEnAvantId!);
      if (ville != null) {
        _villeActuelle = ville;
        await _chargerMeteo();
        _isInitialized = true;
        notifyListeners();
        return;
      }
    }

    final villesFavorites = _villes.where((v) => v.isFavorite).toList();
    if (villesFavorites.isNotEmpty) {
      _villeActuelle = villesFavorites.first;
      await _chargerMeteo();
    }

    _isInitialized = true;
    notifyListeners();
  }

  // charger la meteo pour la ville actuelle
  Future<void> _chargerMeteo() async {
    if (_villeActuelle == null) return;
    final data = await _meteoApi.getWeather(
      _villeActuelle!.latitude,
      _villeActuelle!.longitude,
    );
    if (data != null) {
      _meteoActuelle = Meteo.fromMap(data);
    }
  }

  // trouver  la ville par position
  Future<void> selectionnerVilleParPosition(double lat, double lon) async {
    try {
      final data = await _apiVille.fetchVilleParPosition(lat, lon);
      if (data != null) {
        await selectionnerVille(data);
      }
    } catch (e) {
      print(e);
    }
    notifyListeners();
  }

  // charger les villes depuis la BDD
  Future<void> loadVilles() async {
    _villes = await VilleDbHelper.getAll();
    notifyListeners();
  }

  // rechercher une ville par son nom
  Future<List<Map<String, dynamic>>> rechercherVille(String nom) async {
    return await _apiVille.searchCityAPI(nom);
  }

  // Sélectionne la ville courante : si elle existe déjà dans la liste (_villes) on la réutilise,
  // sinon on la crée depuis les donnees API, puis on charge la météo

  Future<void> selectionnerVille(Map<String, dynamic> villeData) async {
    final lat = double.parse(villeData['lat']);
    final lon = double.parse(villeData['lon']);

    Ville? villeExistante;
    try {
      villeExistante = _villes.firstWhere(
        (v) => v.latitude == lat && v.longitude == lon,
      );
    } catch (_) {
      villeExistante = null;
    }

    if (villeExistante != null) {
      _villeActuelle = villeExistante;
    } else {
      _villeActuelle = Ville.creerVilleDepuisAPI(villeData);
    }

    await _chargerMeteo();
    notifyListeners();
  }

  // définir la ville actuelle
  Future<void> setVilleActuelle(Ville ville) async {
    _villeActuelle = ville;
    await _chargerMeteo();
    notifyListeners();
  }

  // basculer le statut favori d'une ville
  // si la ville n'a pas d'id (pas en BDD), on l'insère d'abord
  // puis on met à jour son statut favori
  // on met à jour la liste des villes en mémoire et la ville actuelle si besoin
  // on gère aussi la ville mise en avant si besoin
  Future<void> toggleFavori(Ville ville) async {
    // si la ville n'est pas en BDD , on l'insère d'abord
    if (ville.id == null) {
      final villeAFavoriser = ville.copie(isFavorite: true);
      final id = await VilleDbHelper.insert(villeAFavoriser);
      final villeFavorite = villeAFavoriser.copie(id: id);

      _villeActuelle = villeFavorite;
      await loadVilles();
      notifyListeners();
      return;
    }
    // sinon , on fait que inverser le statut favori et mettre à jour la BDD

    final Ville updated = ville.copie(isFavorite: !ville.isFavorite);
    await VilleDbHelper.update(updated);

    // cas où la ville est msis en mise en avant
    if (!updated.isFavorite && _villeMiseEnAvantId == updated.id) {
      _villeMiseEnAvantId = null;
      await PreferencesService.setVillemiseenavant(null);
    }

    final int index = _villes.indexWhere((v) => v.id == updated.id);
    if (index != -1) {
      _villes[index] = updated;
    } else {
      _villes.add(updated);
    }

    if (_villeActuelle?.id == updated.id) {
      _villeActuelle = updated;
    }

    notifyListeners();
  }

  // basculer le statut de mise en avant d'une ville

  Future<void> toggleMiseEnAvant(Ville ville) async {
    if (!ville.isFavorite) return;

    if (_villeMiseEnAvantId == ville.id) {
      _villeMiseEnAvantId = null;
      await PreferencesService.setVillemiseenavant(null);
    } else {
      _villeMiseEnAvantId = ville.id;
      await PreferencesService.setVillemiseenavant(ville.id);
      _villeActuelle = ville;
      await _chargerMeteo();
    }
    notifyListeners();
  }

  // logiquement : on peut aimer un lieu sans avoir à aimer la ville , donc si on aime le liueu , on aurait visité la ville

  // permet de marquer une ville comme visitée (non favorite)
  // si la ville n'a pas d'id (pas en BDD), on l'insère d'abord

  Future<Ville> marquerCommeVisitee(Ville ville) async {
    if (ville.id != null) return ville;

    final id = await VilleDbHelper.insert(ville.copie(isFavorite: false));
    final villeInseree = ville.copie(id: id, isFavorite: false);

    final index = _villes.indexWhere((v) => v.id == villeInseree.id);
    if (index == -1) _villes.add(villeInseree);

    notifyListeners();
    return villeInseree;
  }

  // supprimer une ville
  Future<void> supprimerVille(Ville ville) async {
    if (ville.id == null) return;

    // supprimer de la BDD
    await VilleDbHelper.delete(ville.id!);

    if (_villeMiseEnAvantId == ville.id) {
      _villeMiseEnAvantId = null;
      await PreferencesService.setVillemiseenavant(null);
    }

    _villes.removeWhere((v) => v.id == ville.id);

    if (_villeActuelle?.id == ville.id) {
      _villeActuelle = ville.copie(
        id: null,
        isFavorite: false,
        forceIdNull: true,
      );
    }

    notifyListeners();
  }

  // reinitialiser l'app vider la BDD et les préférences
  /* nous n'avons pas trouvé de meilleur endroit pour mettre cette fonction, on la met ici  */
  Future<void> reinitialiserApplication() async {
    await DatabaseHelper.resetDatabase();
    await PreferencesService.clearAll();
    _villes = [];
    _villeActuelle = null;
    _villeMiseEnAvantId = null;
    _meteoActuelle = null;
    notifyListeners();
  }
}
