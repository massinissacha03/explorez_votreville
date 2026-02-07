import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lieu_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../providers/ville_provider.dart';


// section du drawer pour le rayon de recherche des suggestions
Widget rayonRechercheSection(Color couleurPrincipale) {
  return Builder(
    builder: (context) {
      final suggestionProvider = Provider.of<SuggestionProvider>(context);

      return Column(
        children: [
          ListTile(
            leading: Icon(Icons.radar, color: couleurPrincipale),
            title: const Text('Rayon de recherche'),
            subtitle: Text(
              '${(suggestionProvider.rayonRecherche / 1000).toStringAsFixed(0)} km',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: suggestionProvider.rayonRecherche,
              min: 1000,
              max: 10000,
              divisions: 9,
              label: '${(suggestionProvider.rayonRecherche / 1000).toStringAsFixed(0)} km',
              activeColor: couleurPrincipale,
              onChanged: suggestionProvider.setRayon,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: couleurPrincipale,
                  side: BorderSide(color: couleurPrincipale),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Appliquer le rayon'),
                onPressed: () async {
                  final villeProvider = Provider.of<VilleProvider>(
                    context,
                    listen: false,
                  );
                  final lieuProvider = Provider.of<LieuProvider>(
                    context,
                    listen: false,
                  );
                  final suggestionProvider = Provider.of<SuggestionProvider>(
                    context,
                    listen: false,
                  );

                  final ville = villeProvider.villeActuelle;
                  if (ville == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucune ville sélectionnée.')),
                    );
                    return;
                  }

                  await suggestionProvider.chargerSuggestions(ville, lieuProvider.lieux);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recherche mise à jour avec le nouveau rayon.'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}
