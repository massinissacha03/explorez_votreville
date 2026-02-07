import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../../models/lieu.dart';
import '../../providers/lieu_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../providers/ville_provider.dart';
import 'carte_interactive.dart';


// un widget pour afficher la carte des lieux d'une ville
Widget carteDesLieux(BuildContext context) {
  final villeProvider = Provider.of<VilleProvider>(context);
  final lieuProvider = Provider.of<LieuProvider>(context);
  final suggestionProvider = Provider.of<SuggestionProvider>(context);

  final ville = villeProvider.villeActuelle;
  if (ville == null) { // pas de ville sélectionnée
    return const SizedBox.shrink();
  }


  
  final categorie = suggestionProvider.categorieSelectionnee;
  final lieuxAfficher = <Lieu>[];

  for (final lieu in lieuProvider.lieux) {
    if (categorie == null || lieu.categorie == categorie) {
      lieuxAfficher.add(lieu);
    }
  }

  lieuxAfficher.addAll(suggestionProvider.suggestionsFiltrees);

  return Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      height: 400,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: CarteInteractive(
          lieux: lieuxAfficher,
          centre: LatLng(ville.latitude, ville.longitude),
        ),
      ),
    ),
  );
}
