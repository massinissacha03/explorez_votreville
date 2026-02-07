import 'package:flutter/material.dart';
import '../models/lieu.dart';
import '../models/ville.dart';
import '../services/api_lieux.dart';
import '../utils/commun.dart';


/* gestion des suggestions de lieux */


class SuggestionProvider extends ChangeNotifier {
  final ApiLieux _api = ApiLieux(); // instance de l'API pour les lieux



  List<Lieu> _suggestions = []; // liste des suggestions actuelles , pour ne pas faire trop d'appels
  double _rayonRecherche = 5000; // extension : rayon de recherche modifiable
  String? _categorieSelectionnee; 


 // un map de suggestions par ville, <villeId, liste des lieux>
  final Map<int, List<Lieu>> _suggestionsParVille = {};

  List<Lieu> get suggestions => _suggestions;
  double get rayonRecherche => _rayonRecherche;
  String? get categorieSelectionnee => _categorieSelectionnee;



  // obtenir les suggestions filtrées par catégorie
  List<Lieu> get suggestionsFiltrees {
    if (_categorieSelectionnee == null) return _suggestions;
    return _suggestions
        .where((l) => l.categorie == _categorieSelectionnee)
        .toList();
  }

  // modifier le rayon de recherche
  void setRayon(double nouveauRayon) {
    _rayonRecherche = nouveauRayon;
    _suggestionsParVille.clear();
    _suggestions = [];
    notifyListeners();
  }


  // modifier la catégorie sélectionnée
  void setCategorie(String? categorie) {
    if (_categorieSelectionnee == categorie) {
      _categorieSelectionnee = null; // désélectionner si déjà sélectionnée
    } else {
      _categorieSelectionnee = categorie;
    }
    notifyListeners();
  }


  // charger les suggestions pour une ville donnée en paramètre
  Future<void> chargerSuggestions(
    Ville ville,
    List<Lieu> lieuxExistants,
  ) async {

    // vérifier si on a déjà des suggestions pour cette ville
    if (ville.id != null && _suggestionsParVille.containsKey(ville.id)) {
      _suggestions = List<Lieu>.from(_suggestionsParVille[ville.id!]!);
      notifyListeners();
      return;
    }

    // sinon, charger depuis l'API
    final List<Lieu> nouvellesSuggestions = [];


    // pour chaque catégorie , charger les suggestions
    for (final categorie in Commun.categories) {
      try {
        // appeler l'API
        final results = await _api.chargerSuggestionsParCategorie(
          categorie,
          ville.latitude,
          ville.longitude,
          radius: _rayonRecherche.toInt(),
        );

        // on limite a 20 par catégorie
        int compteur = 0;
        for (var result in results) {
          if (compteur >= 20) break;
          // parser les lat/lon et vérifier si le lieu existe déjà
          try {
            final lat = double.parse(result['lat'].toString());
            final lon = double.parse(result['lon'].toString());

            final existeDeja =
                lieuxExistants.any(
                  (l) => l.latitude == lat && l.longitude == lon,
                ) ||
                nouvellesSuggestions.any(
                  (l) => l.latitude == lat && l.longitude == lon,
                );
            // si n'existe pas déjà, l'ajouter aux suggestions
            if (!existeDeja) {
              nouvellesSuggestions.add(
                Lieu.fromApi(
                  result,
                  categorie: categorie,
                  villeId: ville.id ?? 0,
                ),
              );
              compteur++;
            }
          } catch (e) {
            continue;
          }
        }
      } catch (e) {
        continue;
      }
    }


    // mettre à jour les suggestions et le map
    _suggestions = nouvellesSuggestions;
    
    if (ville.id != null) {
      _suggestionsParVille[ville.id!] = List<Lieu>.from(_suggestions);
    }

    notifyListeners();
  }


  // rechercher un lieu par son nom 
  Future<List<Lieu>> rechercherLieuParNom(
    String nom,
    String categorie,
    double lat,
    double lon,
  ) async {
    try {
      final results = await _api.rechercherParNom(nom, lat, lon);
      return results
          .map((r) => Lieu.fromApi(r, categorie: categorie, villeId: 0))
          .toList();
    } catch (e) {
      return [];
    }
  }


  // ajouter un lieu aux suggestions
  void ajouterAuxSuggestions(Lieu lieu) {
    final existeDeja = _suggestions.any(
      (l) => l.latitude == lieu.latitude && l.longitude == lieu.longitude,
    );

    if (!existeDeja) {
      _suggestions.add(lieu);
      notifyListeners();
    }
  }


  // retirer un lieu des suggestions pour remettre en favori
  void retirerDesSuggestions(Lieu lieu) {
    _suggestions.removeWhere(
      (s) => s.latitude == lieu.latitude && s.longitude == lieu.longitude,
    );

    if (lieu.villeId != 0 && _suggestionsParVille.containsKey(lieu.villeId)) {
      _suggestionsParVille[lieu.villeId]!.removeWhere(
        (s) => s.latitude == lieu.latitude && s.longitude == lieu.longitude,
      );
    }
    notifyListeners();
  }



  // ajouter les lieux d'une ville comme suggestions
  void ajouterLieuxDepuisVilleCommeSuggestions(
    List<Lieu> lieuxDeVille,
    int villeId,
  ) {
    for (final lieu in lieuxDeVille) {
      final dejaEnSuggestion = _suggestions.any(
        (s) => s.latitude == lieu.latitude && s.longitude == lieu.longitude,
      );

      if (!dejaEnSuggestion) {
        _suggestions.add(
          lieu.copie(
            id: null, // plus en BDD
            estFavori: false, // plus favori
            noteMoyenne: null, // suggestions simples
          ),
        );
      }
    }

    _suggestionsParVille[villeId] = List<Lieu>.from(_suggestions);
    notifyListeners();
  }
}
