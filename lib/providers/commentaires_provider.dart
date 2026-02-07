import 'package:flutter/material.dart';
import '../models/commentaire.dart';
import '../models/lieu.dart';
import '../db/commentaire_db_helper.dart';
/* gestion des commentaires , creation, ajout , suppression , chargement */
class CommentaireProvider extends ChangeNotifier {
  
  List<Commentaire> _commentaires = []; // pour stocker les commentaires en mémoire et éviter d'aller à chaque fois en BDD

  List<Commentaire> get commentaires => _commentaires;


  // obtenir les commentaires d'un lieu 
  List<Commentaire> getCommentairesByLieu(int lieuId) {
    return _commentaires.where((c) => c.lieuId == lieuId).toList();
  }




// charger les commentaires d'un seul lieu
Future<void> rechargerCommentairesDuLieu(int lieuId) async {
  _commentaires.removeWhere((c) => c.lieuId == lieuId);
  final comments = await CommentaireDbHelper.getByLieu(lieuId);
  _commentaires.addAll(comments);
  notifyListeners();
}



  // charger les commentaires pour une liste de lieux
  Future<void> chargerCommentaires(List<Lieu> lieux) async {
    _commentaires = [];
    for (var lieu in lieux) {
      if (lieu.id != null) {
        final comments = await CommentaireDbHelper.getByLieu(lieu.id!);
        _commentaires.addAll(comments);
      }
    }
    notifyListeners();
  }

  


  // ajouter un commentaire
  Future<void> ajouterCommentaire(Commentaire commentaire) async {
    final id = await CommentaireDbHelper.insert(commentaire);
    final commentaireAvecId = commentaire.copie(id: id);
    _commentaires.add(commentaireAvecId);
    notifyListeners();
  }


  // obtenir la note moyenne pour un lieu
  Future<double?> getNoteMoyenne(int lieuId) async {
    return await CommentaireDbHelper.getNoteMoyennePourLieu(lieuId);
  }

  // supprimer les commentaires pour une liste de lieux
  void supprimerCommentairesDeVille(Set<int> idsLieux) {
    _commentaires.removeWhere((c) => idsLieux.contains(c.lieuId));
    notifyListeners();
  }

  

}
