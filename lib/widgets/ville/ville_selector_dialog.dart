import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/ville_provider.dart';
import '../../providers/historique_provider.dart';
import '../../utils/ville_loader.dart';


// dialog pour sélectionner une ville parmi une liste de résultats

Widget villeSelectorDialog(
  BuildContext context,
  List<Map<String, dynamic>> villes,
) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final isDark = themeProvider.isDarkMode;

  const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);
  final couleurFond = isDark ? Colors.grey[900] : Colors.white;
  final couleurTexte = isDark ? Colors.white : Colors.black87;
  final couleurSubtitle = isDark ? Colors.grey[400] : Colors.grey[600];

  return AlertDialog(
    backgroundColor: couleurFond,
    title: Text(
      'Choisissez votre ville',
      style: TextStyle(color: couleurTexte),
    ),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: villes.length,
        itemBuilder: (context, index) {
          final ville = villes[index];
          final nomComplet = ville['display_name'] as String;
          final nomVille = nomComplet.split(',').first;

          return ListTile(
            leading: const Icon(
              Icons.location_city,
              color: couleurPrincipale,
            ),
            title: Text(
              nomVille,
              style: TextStyle(color: couleurTexte),
            ),
            subtitle: Text(
              nomComplet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: couleurSubtitle),
            ),
            onTap: () async {
              final villeProvider = Provider.of<VilleProvider>(
                context,
                listen: false,
              );
              final historiqueProvider = Provider.of<HistoriqueProvider>(
                context,
                listen: false,
              );

                Navigator.pop(context);

                await villeProvider.selectionnerVille(ville);
                await historiqueProvider.ajouterRecherche(nomVille);

                if (villeProvider.villeActuelle != null) {
                  final villeActuelle = villeProvider.villeActuelle!;
                  await applyVilleSelection(context, villeActuelle);
                }
              },
            );
          },
        ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Annuler',
          style: TextStyle(color: couleurPrincipale),
        ),
      ),
    ],
  );
}
