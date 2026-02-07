import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/ville.dart';
import '../providers/ville_provider.dart';
import '../providers/lieu_provider.dart';
import '../providers/suggestion_provider.dart';
import '../providers/commentaires_provider.dart';


// appliquer la sélection d'une ville : charger les lieux, commentaires, suggestions associés



Future<void> applyVilleSelection(BuildContext context, Ville ville) async {
  final villeProvider = Provider.of<VilleProvider>(context, listen: false);
  await villeProvider.setVilleActuelle(ville);

  final lieuProvider = Provider.of<LieuProvider>(context, listen: false);
  final commentaireProvider =
      Provider.of<CommentaireProvider>(context, listen: false);
  final suggestionProvider =
      Provider.of<SuggestionProvider>(context, listen: false);

  await lieuProvider.chargerLieux(ville);
  await commentaireProvider.chargerCommentaires(lieuProvider.lieux);
  await suggestionProvider.chargerSuggestions(ville, lieuProvider.lieux);
}
