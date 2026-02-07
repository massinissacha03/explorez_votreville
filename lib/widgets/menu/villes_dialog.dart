import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ville_provider.dart';
import '../../providers/lieu_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../providers/commentaires_provider.dart';
import '../../utils/ville_loader.dart';

/*on peut avoir des villes visitées sans avoir à les aimer (on pourrait aimer un lieu de la ville) */

// ce widget nnoous les affiche dans un dialog
void showVillesVisiteesDialog(BuildContext context, List villes) {
  final villesEnregistrees = villes.where((v) => v.id != null).toList();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Toutes mes villes visitées'),
      content: SizedBox(
        width: double.maxFinite,
        child: villesEnregistrees.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Aucune ville enregistrée pour le moment.'),
              )
            : ListView.builder(
                shrinkWrap:
                    true, // pour que le ListView prenne seulement la place nécessaire
                itemCount: villesEnregistrees.length,
                itemBuilder: (context, index) {
                  final ville = villesEnregistrees[index];
                  final estFavorite = ville.isFavorite == true;

                  return ListTile(
                    leading: Icon(
                      estFavorite ? Icons.favorite : Icons.explore_outlined,
                      color: estFavorite ? Colors.red : Colors.grey[700],
                    ),
                    title: Text(ville.name),
                    subtitle: Text(
                      estFavorite ? 'Favorite' : 'Visitée',
                      style: TextStyle(
                        color: estFavorite ? Colors.red : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirme = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Supprimer la ville ?'),
                                content: Text(
                                  'Voulez-vous supprimer "${ville.name}" et tous ses lieux ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Supprimer',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirme == true) {
                              final villeProvider = Provider.of<VilleProvider>(
                                context,
                                listen: false,
                              );
                              final lieuProvider = Provider.of<LieuProvider>(
                                context,
                                listen: false,
                              );
                              final commentaireProvider =
                                  Provider.of<CommentaireProvider>(
                                    context,
                                    listen: false,
                                  );
                              final suggestionProvider =
                                  Provider.of<SuggestionProvider>(
                                    context,
                                    listen: false,
                                  );

                              final lieuxDeCetteVille = lieuProvider.lieux
                                  .where((l) => l.villeId == ville.id)
                                  .toList();
                              final idsLieux = lieuxDeCetteVille
                                  .where((l) => l.id != null)
                                  .map((l) => l.id!)
                                  .toSet();
                              commentaireProvider.supprimerCommentairesDeVille(
                                idsLieux,
                              );

                              if (ville.id != null) {
                                suggestionProvider
                                    .ajouterLieuxDepuisVilleCommeSuggestions(
                                      lieuxDeCetteVille,
                                      ville.id!,
                                    );
                              }

                              await lieuProvider.supprimerLieuxDeVille(
                                ville.id!,
                              );
                              await villeProvider.supprimerVille(ville);
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            estFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: estFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () async {
                            final villeProvider = Provider.of<VilleProvider>(
                              context,
                              listen: false,
                            );
                            await villeProvider.toggleFavori(ville);
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      await applyVilleSelection(context, ville);
                      Navigator.pop(context); // Fermer le dialog
                      Navigator.pop(context); // Fermer le drawer
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Fermer',
            style: TextStyle(color: Color.fromARGB(255, 7, 90, 11)),
          ),
        ),
      ],
    ),
  );
}
