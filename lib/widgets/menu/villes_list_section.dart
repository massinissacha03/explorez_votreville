import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ville_provider.dart';
import '../../providers/lieu_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../providers/commentaires_provider.dart';
import '../../utils/ville_loader.dart';

/// Liste des villes FAVORITES
// animation de l'apparition des villes favorites dans le drawer avec AnimatedSlide selon leur index
//
/// - animation AnimatedSwitcher sur le bouton mise en avant
Widget villesListSection(
  BuildContext context,
  List villesFavorites,
  VilleProvider villeProvider,
  bool isDark,
  Set<int> visibleIndices,
) {
  return ListView.builder(
    itemCount: villesFavorites.length,
    itemBuilder: (context, index) {
      final ville = villesFavorites[index];

      final estMiseEnAvant =
          ville.estMiseEnAvant(villeProvider.villeMiseEnAvantId);

      final isActuelle = villeProvider.villeActuelle?.id == ville.id;

      final estVisible = visibleIndices.contains(index);

      return AnimatedSlide(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        offset: estVisible ? Offset.zero : const Offset(-0.25, 0),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActuelle
                ? const Color.fromARGB(255, 0, 92, 20).withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withAlpha(100),
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.favorite,
              color: isActuelle
                  ? const Color.fromARGB(255, 0, 92, 20)
                  : Colors.red,
            ),
            title: Text(
              ville.name,
              style: TextStyle(
                fontWeight: isActuelle ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () async {
                    final vp =
                        Provider.of<VilleProvider>(context, listen: false);
                    await vp.toggleFavori(ville);
                  },
                ),

                // Animation sur le changement d'icône étoile mise en avant
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: IconButton(
                    key: ValueKey(estMiseEnAvant),
                    icon: Icon(
                      estMiseEnAvant ? Icons.star : Icons.star_border,
                      color: estMiseEnAvant ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () async {
                      await villeProvider.toggleMiseEnAvant(ville);

                      if (villeProvider.villeActuelle?.id == ville.id) {
                        final lieuProvider =
                            Provider.of<LieuProvider>(context, listen: false);
                        final suggestionProvider =
                            Provider.of<SuggestionProvider>(
                          context,
                          listen: false,
                        );
                        final commentaireProvider =
                            Provider.of<CommentaireProvider>(
                          context,
                          listen: false,
                        );

                        await lieuProvider.chargerLieux(ville);
                        await commentaireProvider
                            .chargerCommentaires(lieuProvider.lieux);
                        await suggestionProvider.chargerSuggestions(
                          ville,
                          lieuProvider.lieux,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            onTap: () async {
              await applyVilleSelection(context, ville);
              Navigator.pop(context);
            },
          ),
        ),
      );
    },
  );
}
