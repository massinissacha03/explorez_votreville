import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/commun.dart';


// Widget pour le filtre par catégories dans les suggestions de lieux

Widget categoriesFilterRow(BuildContext context) {
  final suggestionProvider = Provider.of<SuggestionProvider>(context);
  final themeProvider = Provider.of<ThemeProvider>(context);
  final isDark = themeProvider.isDarkMode;

  const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);
  final couleurFond = isDark ? Colors.grey[800] : Colors.white;

  return SizedBox(
    height: 45,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: Commun.categories.map((categorie) {
        final estSelectionnee = suggestionProvider.categorieSelectionnee == categorie;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            selected: estSelectionnee,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Commun.getIconeCategorie(categorie),
                  size: 16,
                  color: estSelectionnee ? Colors.white : couleurPrincipale,
                ),
                const SizedBox(width: 6),
                Text(categorie),
              ],
            ),
            backgroundColor: couleurFond,
            selectedColor: couleurPrincipale,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: estSelectionnee ? Colors.white : (isDark ? Colors.white : Colors.black87),
              fontWeight: estSelectionnee ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: estSelectionnee ? couleurPrincipale : Colors.grey,
              width: estSelectionnee ? 2 : 1,
            ),
            onSelected: (_) => suggestionProvider.setCategorie(categorie),
          ),
        );
      }).toList(),
    ),
  );
}
