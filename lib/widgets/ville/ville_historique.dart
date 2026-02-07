import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/historique_provider.dart';
import '../../providers/theme_provider.dart';


// widget pour afficher l'historique des recherches de villes

Widget villeHistorique(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final isDark = themeProvider.isDarkMode;
  final historiqueProvider = Provider.of<HistoriqueProvider>(context);
  final recherches = historiqueProvider.recherchesRecentes;

  if (recherches.isEmpty) return const SizedBox.shrink();

  const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);
  final couleurTexte = isDark ? Colors.white70 : Colors.grey[700];
  final couleurChip =
      isDark ? Colors.white.withAlpha(38) : Colors.white.withAlpha(230);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.history,
              size: 16,
              color: couleurPrincipale,
            ),
            const SizedBox(width: 8),
            Text(
              'Recherches récentes',
              style: TextStyle(
                color: couleurTexte,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_sweep, size: 20, color: Colors.red),
              tooltip: 'Vider l\'historique',
              onPressed: () => historiqueProvider.viderHistorique(),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: recherches.length,
          itemBuilder: (context, index) {
            final ville = recherches[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(
                  Icons.location_city,
                  size: 16,
                  color: couleurPrincipale,
                ),
                label: Text(
                  ville,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: couleurChip,
                side: BorderSide(
                  color: couleurPrincipale.withOpacity(0.3),
                  width: 1,
                ),
              ),
            );
          },
        ),
      ),


      
    ],
  );
}
