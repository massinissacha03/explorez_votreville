import 'package:flutter/material.dart';
import '../models/lieu.dart';
import '../models/ville.dart';
import '../db/lieu_db_helper.dart';
import '../db/commentaire_db_helper.dart';


/* gestion des lieux : ajout , modification, suppression, favoris, notes moyennes...  */
class LieuProvider extends ChangeNotifier {
  List<Lieu> _lieux = []; // pour stocker les lieux en mémoire et éviter d'aller à chaque fois en BDD


  List<Lieu> get lieux => _lieux; 




  // obtenir les lieux favoris
  List<Lieu> getLieuxFavoris() {
    return _lieux.where((lieu) => lieu.estFavori).toList();
  }


  // charger les lieux d'une ville
  Future<void> chargerLieux(Ville ville) async {
    if (ville.id != null) {
      _lieux = await LieuDbHelper.getByVille(ville.id!);
      await _rafraichirToutesNotesMoyennes();
    } else {
      _lieux = [];
    }
    notifyListeners();
  }


   // rafraichir la note moyenne pour un lieu spécifique
  Future<void> _rafraichirNoteMoyennePourLieu(int lieuId) async {
    final moyenne = await CommentaireDbHelper.getNoteMoyennePourLieu(lieuId);
    final index = _lieux.indexWhere((l) => l.id == lieuId);
    if (index == -1) return;

    final updated = _lieux[index].copie(noteMoyenne: moyenne);
    _lieux[index] = updated;
    await LieuDbHelper.update(updated);
  }
  // rafraichir les notes moyennes pour tous les lieux
  Future<void> _rafraichirToutesNotesMoyennes() async {
    for (final lieu in _lieux) {
      if (lieu.id != null) {
        await _rafraichirNoteMoyennePourLieu(lieu.id!);
      }
    }
  }

  //  publique pour rafraichir après ajout de commentaire
  Future<void> rafraichirNoteMoyenne(int lieuId) async {
    await _rafraichirNoteMoyennePourLieu(lieuId);
    notifyListeners();
  }


  // ajouter un lieu
  Future<Lieu?> ajouterLieu(
    Lieu lieu, {
    bool villeFavorite = true,
  }) async {
    final id = await LieuDbHelper.insert(lieu);
    final lieuAvecId = lieu.copie(id: id);
    _lieux.add(lieuAvecId);
    notifyListeners();
    return lieuAvecId;
  }


  // modifier un lieu 
  Future<void> modifierLieu(Lieu lieu) async {
    if (lieu.id == null) return;

    await LieuDbHelper.update(lieu);
    
    final index = _lieux.indexWhere((l) => l.id == lieu.id);
    if (index != -1) {
      _lieux[index] = lieu;
      notifyListeners();
    }
  }
  // supprimer un lieu
  Future<void> supprimerLieu(int id) async {
    await LieuDbHelper.delete(id);
    _lieux.removeWhere((l) => l.id == id);
    notifyListeners();
  }


  // supprimer les lieux d'une ville
  Future<void> supprimerLieuxDeVille(int villeId) async {
    await LieuDbHelper.supprimerParVille(villeId);
    _lieux.removeWhere((lieu) => lieu.villeId == villeId);
    notifyListeners();
  }


  // basculer le statut d'un lieu favori ou non 
  Future<void> toggleFavori(int id) async {
    final index = _lieux.indexWhere((l) => l.id == id);
    if (index == -1) return;

    final lieu = _lieux[index];
    final updated = lieu.copie(estFavori: !lieu.estFavori);
    await LieuDbHelper.update(updated);
    _lieux[index] = updated;
    notifyListeners();
  }
}
